#!/bin/bash

# Setup Jitsi Server sys users
# (and get LE cert, moved after to shared image)
#
set -e

PUB_IP=$(curl -s ifconfig.me)
LOCAL_IP=$(ip -4 -br address show eth0 | awk '{ print $3 }' | sed -e 's#/.*##')
INSTANCE_IDX=$(curl -s -H 'Metadata:true' "http://169.254.169.254/metadata/instance?api-version=2020-09-01" | jq -j 'first(.[] | .name)' | tail -c 1)
echo "Setting up instance $INSTANCE_IDX ip: $LOCAL_IP  vip:${vip}  curl says $PUB_IP. Updating hosts with vip"
sed -i "/${hostname}/c ${vip} ${hostname}" /etc/hosts
hostnamectl set-hostname --static "${hostname}"
echo "Setting up Jitsi users"

function generatePassword() {
    openssl rand -hex 16
}
#OLD_JVB_PASSWORD=$(grep -oP 'org.jitsi.videobridge.xmpp.user.shard.PASSWORD=\K.*' /etc/jitsi/videobridge/sip-communicator.properties)
#OLD_JICOFO_PASSWORD=$(grep -oP 'JICOFO_AUTH_PASSWORD=\K.*' /etc/jitsi/jicofo/config)
JICOFO_SECRET=$(generatePassword)
JICOFO_AUTH_PASSWORD=$(generatePassword)
JVB_AUTH_PASSWORD=$(generatePassword)
#JIGASI_XMPP_PASSWORD=$(generatePassword)
#JIBRI_RECORDER_PASSWORD=$(generatePassword)
#JIBRI_XMPP_PASSWORD=$(generatePassword)
MEET_CONF_JS="/etc/jitsi/meet/${hostname}-config.js"
JVB_CONF=/etc/jitsi/videobridge/config
JVB_SIP=/etc/jitsi/videobridge/sip-communicator.properties
PROSODY_HOST_CONF="/etc/prosody/conf.avail/${hostname}.cfg.lua"
JICOFO_CONFIG=/etc/jitsi/jicofo/config
JITSI_USER="${user_login}"
JITSI_PASSWORD="${user_password}"

function setup_users() {
  sed -i "s/component_secret =.*/component_secret = \"$JICOFO_SECRET\"/" $PROSODY_HOST_CONF
  sed -i "s/JICOFO_AUTH_PASSWORD=.*/JICOFO_AUTH_PASSWORD=$JICOFO_AUTH_PASSWORD/" $JICOFO_CONFIG
  sed -i "s/JICOFO_SECRET=.*/JICOFO_SECRET=$JICOFO_SECRET/" $JICOFO_CONFIG
  sed -i "s/JVB_SECRET=.*/JVB_SECRET=$JVB_AUTH_PASSWORD/" $JVB_CONF
  sed -i "s/org.jitsi.videobridge.xmpp.user.shard.PASSWORD=.*/org.jitsi.videobridge.xmpp.user.shard.PASSWORD=$JVB_AUTH_PASSWORD/" $JVB_SIP
  # default admin
  prosodyctl register $JITSI_USER "${hostname}" $JITSI_PASSWORD
  prosodyctl register "jvb" "auth.${hostname}" $JVB_AUTH_PASSWORD
  prosodyctl register "focus" "auth.${hostname}" $JICOFO_AUTH_PASSWORD
}

function edit_bitrate() {
  sed -i "s/.*low: [0-9]\{6\}/\                low: ${low_bitrate}/" $MEET_CONF_JS
  sed -i "s/.*standard: [0-9]\{6\}/\                standard: ${med_bitrate}/" $MEET_CONF_JS
  sed -i "s/.*high: [0-9]\{7\}/\                high: ${high_bitrate}/" $MEET_CONF_JS

}

setup_users
edit_bitrate

# cascade future
cat << EOF >> $JICOFO_CONFIG
jicofo.octo.id="0000$${INSTANCE_IDX}"
# Todo: set regions and deployment info in jvb/meet
EOF

function restart_all() {
  systemctl restart prosody jicofo jitsi-videobridge2 etherpad-lite
}

restart_all
echo "Done Setting Up!"