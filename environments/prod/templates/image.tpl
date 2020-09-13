#!/bin/bash

# Setup Jitsi Server (shared)
# Azure Ubuntu Focal Fossa
# Lets Encrypt in Key Vault, etherpad, auth
# postgres (local or azure)

function env_setup() {
  set -e
  LONG_DATE=$(date +"%A at %R (%D) Unix:%s")
  echo "Setting up ${hostname}. It's $LONG_DATE"
  #LOCAL_IP=$(ip -4 -br address show eth0 | awk '{ print $3 }' | sed -e 's#/.*##')
  #DNS_PUB_IP=$(dig +short myip.opendns.com @resolver1.opendns.com)
  PUB_IP=$(curl -s ifconfig.me)
  MEET_CONF_JS=/etc/jitsi/meet/${hostname}-config.js
  JVB_CONF=/etc/jitsi/videobridge/config
  JVB_SIP=/etc/jitsi/videobridge/sip-communicator.properties
  PROSODY_HOST_CONF=/etc/prosody/conf.avail/${hostname}.cfg.lua
  #COTURN="${hostname}:5349"
  JICOFO_CONF=/etc/jitsi/jicofo/sip-communicator.properties
  ETHERPAD_DIR=/opt/etherpad
  NGINX_AVAIL_CONF=/etc/nginx/sites-available/${hostname}.conf

  cat << EOF > /etc/hosts
  $PUB_IP ${hostname}
  127.0.0.1 localhost
EOF

  # Disable IPv6
  {
    echo "net.ipv6.conf.all.disable_ipv6=1"
    echo "net.ipv6.conf.default.disable_ipv6=1"
  } >> /etc/sysctl.conf

  # Raise File Limits
  {
    echo "DefaultLimitNOFILE=65000"
    echo "DefaultLimitNPROC=65000"
    echo "DefaultTasksMax=65000"
  } >> /etc/systemd/system.conf

  hostnamectl set-hostname --static ${hostname}
  systemctl daemon-reload
}

function package_install() {
  # Debconf
  export DEBIAN_FRONTEND=noninteractive

  cat << EOF | sudo debconf-set-selections
  jitsi-meet jitsi-meet/jvb-serve boolean false
  jitsi-videobridge jitsi-videobridge/jvb-hostname string ${hostname}
  jitsi-meet-prosody jitsi-videobridge/jvb-hostname string ${hostname}
  jitsi-meet-web-config jitsi-meet/cert-choice select 'Generate a new self-signed certificate'
EOF
  # "I want to use my own certificate"
  #jitsi-meet-web-config jitsi-meet/cert-path-crt string  "/etc/ssl/${hostname}.crt"
  #jitsi-meet-web-config jitsi-meet/cert-path-key string  "/etc/ssl/${hostname}.key"

  # Upgrade Ubuntu
  apt-add-repository universe
  apt-get update -y -q
  apt-get upgrade -y -q

  # Jitsi
  curl -S https://download.jitsi.org/jitsi-key.gpg.key | sudo sh -c 'gpg --dearmor > /usr/share/keyrings/jitsi-keyring.gpg'
  echo 'deb [signed-by=/usr/share/keyrings/jitsi-keyring.gpg] https://download.jitsi.org stable/' | tee /etc/apt/sources.list.d/jitsi-stable.list > /dev/null
  apt-get update -y -q

  echo "Installing Jitsi!"
  apt-get install -y -q apt-transport-https nginx-full jq python3-pip openjdk-8-jdk azure-cli
  apt-get install -y -q jitsi-meet lua-dbi-postgresql postgresql-client postgresql postgresql-contrib

  # for: "No module named 'azure.keyvault.key_vault_id"
  pip3 install azure-keyvault==1.1.0
}

function install_etherpad(){
  # Install Etherpad
  curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
  apt install -y nodejs
  adduser --system --home $ETHERPAD_DIR --group etherpad-lite
  cd /opt/etherpad || exit
  git clone --branch master https://github.com/ether/etherpad-lite.git
  chown -R etherpad-lite:etherpad-lite $ETHERPAD_DIR/etherpad-lite

  # Systemd
  cat << EOF > /etc/systemd/system/etherpad-lite.service
  [Unit]
  Description=Etherpad-lite, the collaborative editor.
  After=syslog.target network.target
  [Service]
  Type=simple
  User=etherpad-lite
  Group=etherpad-lite
  WorkingDirectory=/opt/etherpad/etherpad-lite
  Environment=NODE_ENV=production
  ExecStart=/bin/sh $ETHERPAD_DIR/etherpad-lite/bin/run.sh
  Restart=always
  [Install]
  WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable etherpad-lite
  systemctl start etherpad-lite

}

function enable_auth() {
    # Auth
  echo "org.jitsi.jicofo.auth.URL=XMPP:${hostname}" >> $JICOFO_CONF
  sed -i "s|// anonymousdomain:.*|anonymousdomain: 'guest.${hostname}',|g" $MEET_CONF_JS
  sed -i "s/authentication = \"anonymous\"/authentication = \"internal_hashed\"/g" $PROSODY_HOST_CONF
  sed -i "s/authentication = \"internal_plain\"/authentication = \"internal_hashed\"/g" $PROSODY_HOST_CONF

  cat <<EOF >> $PROSODY_HOST_CONF

VirtualHost "guest.${hostname}"
      authentication = "anonymous"
      c2s_require_encryption = false
EOF

}

function meet_settings() {
  sed -i "s|^}|\    location ^~ /etherpad/ {\n        proxy_pass http://localhost:9001/;\n        proxy_set_header X-Forwarded-For \$remote_addr;\n        proxy_buffering off;\n        proxy_set_header       Host \$host;\n    }\n}|g" $NGINX_AVAIL_CONF
  sed -i "/makeJsonParserHappy.*/i\    etherpad_base: 'https://${hostname}/etherpad/p/'", $MEET_CONF_JS
  sed -i "/defaultLanguage/c\    defaultLanguage: '${lang}'", $MEET_CONF_JS
  # enable layer suspension to bring down client CPU usage: https://github.com/jitsi/jitsi-meet/issues/5464#issuecomment-698996303

  if [ ${layer_suspension} = 1 ]; then
    sed -i "/enableLayerSuspension/c\    enableLayerSuspension: true," $MEET_CONF_JS
  fi
}

function video_settings() {
  echo "JVB_STUN_SERVERS=$${COTURN}" >> $JVB_CONF
  # enable client stun
  # https://github.com/mavenik/jitsi-terraform/blob/master/aws/install_jitsi.tpl
  sed -i '/p2p:/a \ \ \ \ useStunTurn: true,' $MEET_CONF_JS
  sed -i '/var config =/a \ \ \ \ useStunTurn: true,' $MEET_CONF_JS

  # use our coturn
  sed -i '/stun:meet.jit/s#^#//#' $MEET_CONF_JS
  sed -i "/stun:${hostname}/s#//##" $MEET_CONF_JS

  # harvest using our stun
  sed -i "s/meet-jit-si-turnrelay.jitsi\.net:443/${hostname}:3478/" $JVB_SIP

  # Jitsi low bandwidth settings
  sed -i "/resolution: 720/c\    resolution: ${resolution}," $MEET_CONF_JS
  sed -i "s#//.*constraints:#\    constraints:#" $MEET_CONF_JS
  sed -i "s#//.*video:#\        video:#" $MEET_CONF_JS
  sed -i "s#//.*height:#\           height:#" $MEET_CONF_JS
  sed -i "s#//.*ideal: 720#\                ideal: ${resolution}#" $MEET_CONF_JS
  sed -i "s#//.*max: 720#\                max: ${resolution} #" $MEET_CONF_JS
  sed -i "s#//.*min: 240#\                min: 240#" $MEET_CONF_JS
  sed -i "/min: 240/a\            }\n        }\n    }," $MEET_CONF_JS
  
  # download only lastN streams
  if [ ${lastN} = 1 ]; then
    sed -i "s#//.*lastNLimits#lastNLimits#" $MEET_CONF_JS
    sed -i "s#//.*5: 20#\    5: 20#" $MEET_CONF_JS
    sed -i "s#//.*30: 15#\    30: 15#" $MEET_CONF_JS
    sed -i "s#//.*50: 10#\    50: 10#" $MEET_CONF_JS
    sed -i "s#//.*70: 5#\    70: 5#" $MEET_CONF_JS
    sed -i "s#//.*90: 2#\    90: 2#" $MEET_CONF_JS
    sed -i "/90: 2/a\    },\n" $MEET_CONF_JS
  fi
  # enable websockets
  sed -i "/websocket:/a\    openBridgeChannel: 'websocket'," $MEET_CONF_JS

  # codec bps
  sed -i "s#//.*videoQuality:#\    videoQuality:#" $MEET_CONF_JS
  sed -i "s#//.*preferredCodec: 'VP8'#\        preferredCodec: 'VP9'#" $MEET_CONF_JS
  sed -i "s#//.*maxBitratesVideo:#\        maxBitratesVideo:#" $MEET_CONF_JS
  sed -i "s#//.*low: 200000#\            low: ${low_bitrate}#" $MEET_CONF_JS
  sed -i "s#//.*standard: 500000#\            standard: ${med_bitrate}#" $MEET_CONF_JS
  sed -i "s#//.*high: 1500000#\            high: ${high_bitrate}#" $MEET_CONF_JS
  sed -i "/high:/a\        },\n" $MEET_CONF_JS
  sed -i "/resizeDesktopForPresenter:/a\        },\n" $MEET_CONF_JS
}

function enable_nginx() {
  systemctl start nginx.service
  systemctl enable nginx.service
}

function restart_all() {
  systemctl restart prosody jicofo jitsi-videobridge2 etherpad-lite
}

function setup_postgres() {
  systemctl enable postgresql.service
  systemctl start postgresql.service

  sudo -u postgres createuser "${db_user}"
  sudo -u postgres createdb ${db_name}
  # postgres requires double quotes for mixed case else lowers case
  sudo -u postgres psql -c "ALTER USER \"${db_user}\" with encrypted password '${db_password}';"
  sudo -u postgres psql -c "grant all privileges on database ${db_name} to \"${db_user}\";"
  # use Postgres
  sed -i 's/--storage = "sql".*/storage = "sql"/g' $PROSODY_HOST_CONF
  sed -i "s/--sql = { driver = \"PostgreSQL\".*/sql = { driver = \"PostgreSQL\", database = \"${db_name}\", username = \"${db_user}\", password   = \"${db_password}\", host = \"${db_host}\" }/g" $PROSODY_HOST_CONF

  cat << EOF > /etc/prosody/migrator.cfg.lua
  local data_path = '/var/lib/prosody';

  filesdefault {
          type = "prosody_files";
          path = data_path;
  }

  postgres {
          type = "prosody_sql";
          driver = "PostgreSQL";
          database = "${db_name}";
          username = "${db_user}";
          password = "${db_password}";
          host = "${db_host}"
  }
EOF

  export HOME=/root
  prosody-migrator filesdefault postgres
}

function lets_encrypt() {

  LETS_ENCRYPT_ARCHIVE=/tmp/lets_encrypt_archive.tar.bz2
  LETS_ENCRYPT_PATH=/etc/letsencrypt
  LETS_ENCRYPT_TMP=/tmp/letsencrypt.tmp

  echo "Checking for Let's Encrypt.."
  rm -f $LETS_ENCRYPT_ARCHIVE
  rm -f $LETS_ENCRYPT_TMP

  if [ ! -d "$LETS_ENCRYPT_PATH"/live ]; then
    echo "Trying to download cert"
    az login -i --allow-no-subscriptions
    # if download fail then generate
    az keyvault secret download --file $LETS_ENCRYPT_TMP --name "${cert_name}" --vault-name "${vault_name}"
    if [ $? -eq 0 ]; then
      # Todo convert letsencrypt cert to pfx and upload properly
      echo "Downloaded cert!"
      touch $LETS_ENCRYPT_ARCHIVE
      base64 -d $LETS_ENCRYPT_TMP > $LETS_ENCRYPT_ARCHIVE
      if file -ib $LETS_ENCRYPT_ARCHIVE | grep -q "application/x-bzip2"; then
        tar -xvf $LETS_ENCRYPT_ARCHIVE -C /etc
        echo "Archive extracted! Updating Nginx"
        CERT_KEY="/etc/letsencrypt/live/${hostname}/privkey.pem"
        CERT_CRT="/etc/letsencrypt/live/${hostname}/fullchain.pem"
        CONF_FILE="/etc/nginx/sites-available/${hostname}.conf"
        CERT_KEY_ESC=$(echo $CERT_KEY | sed 's/\./\\\./g')
        CERT_KEY_ESC=$(echo $CERT_KEY_ESC | sed 's/\//\\\//g')
        sed -i "s/ssl_certificate_key\ \/etc\/jitsi\/meet\/.*key/ssl_certificate_key\ $CERT_KEY_ESC/g" $CONF_FILE
        CERT_CRT_ESC=$(echo $CERT_CRT | sed 's/\./\\\./g')
        CERT_CRT_ESC=$(echo $CERT_CRT_ESC | sed 's/\//\\\//g')
        sed -i "s/ssl_certificate\ \/etc\/jitsi\/meet\/.*crt/ssl_certificate\ $CERT_CRT_ESC/g" $CONF_FILE
        echo "Nginx secured"
      fi
    else
      echo "Failed to download cert.!"
      # uncomment for first run if on public IP or run this on the scaleset
      #echo "${email}" | /usr/share/jitsi-meet/scripts/install-letsencrypt-cert.sh
      #echo "Cert created now uploading to ${vault_name}"
      #tar -cjvf $LETS_ENCRYPT_ARCHIVE -C /etc letsencrypt
      #base64 $LETS_ENCRYPT_ARCHIVE > $LETS_ENCRYPT_TMP
      # az login -i --allow-no-subscriptions
      #az keyvault secret set --vault-name "${vault_name}" --file $LETS_ENCRYPT_TMP --name "${cert_name}"
      #rm -rf $LETS_ENCRYPT_TMP
      #rm -f $LETS_ENCRYPT_ARCHIVE
    fi
  fi

  systemctl restart nginx.service
}



env_setup
package_install
enable_auth
install_etherpad
meet_settings
video_settings
enable_nginx
setup_postgres
echo "Ready for Let's Encrypt and User Setup."
lets_encrypt
restart_all
echo "Jitsi letsencrypt setup completed."