variable "prefix" {
  description = "region_group"
}

variable "location" {
  description = "Azure location"
}

variable "cert_email" {
  description = "email for LetsEncrypt TLS certificate"
  default = "admin@letsencrypt.com"
}

variable "meet_ip" {
  description = "domain"
  default = "REPLACE_MEET_IP"
}

variable "bridge_ips" {
  type = list(any)
  description = "IP of Jitsi bridges"
  default = ["REPLACE_BRIDGE_IP", "REPLACE_BRIDGE_IP", "REPLACE_BRIDGE_IP"]
}

variable "domain" {
  description = "domain"
  default = "azurejitsi.com"
}

variable "web_host" {
  description = "web hostname"
}

variable "video_host" {
  description = "video hostname"
}

variable "ssh_file" {
  description = "empty to generate"
  default = null
}

variable "ssh_username" {
  description = "system username"
  default = "hapa"
}

variable "publisher" {
  description = "image publisher"
}

variable "offer" {
  description = "OS offer"
}

variable "sku" {
  description = "OS sku"
}

variable "disk" {
  description = "Azure disks standard_lrs StandardSSD_LRS premium_lrs"
  default = "standard_lrs"
}


variable "image_version" {
  description = "OS release"
}

variable "vmss_sku" {
  description = "Azure vmss size"
  default = "Standard_B1ms"
}

variable "imagevm_sku" {
  description = "image VM size"
  default = "Standard_B1ms"
}

variable "bastion_sku" {
  description = "bastion vm size"
  default = "Standard_B1s"
}

variable "vmss_count" {
  description = "how many"
  type = number
  default = 3
}

variable "vmss_image_resource_id" {
  description = "Azure Shared Image Gallery image"
  /*
    Edit resource group, SIG name and image name as needed
  */
  default = "/subscriptions/ACCOUNT_NO/resourceGroups/jitsi_images/providers/Microsoft.Compute/galleries/jitsi/images/jitsi-shared-general"
  }

variable "admin_ip" {
  description = "admin ssh IP must be set"
  default = "169.254.1.9"
}

variable "jitsi_user" {
  description = "Jitsi admin user login"
  default = "jitsi"
}

variable "jitsi_password" {
  description = "Jitsi admin password"
}


variable "kv_key_permissions_full" {
  type        = list(string)
  default     = [ "backup", "create", "decrypt", "delete", "encrypt", "get", "import", "list", "purge", "recover", "restore", "sign", "unwrapKey","update", "verify", "wrapKey" ]
}

variable "kv_secret_permissions_full" {
  type        = list(string)
  default     = [ "backup", "delete", "get", "list", "purge", "recover", "restore", "set" ]
}

variable "kv_certificate_permissions_full" {
  type        = list(string)
  default     = [ "backup", "create", "delete", "deleteissuers", "get", "getissuers", "import", "list", "listissuers", "managecontacts", "manageissuers", "purge", "recover", "restore", "setissuers", "update" ]
}

variable "kv_storage_permissions_full" {
  type        = list(string)
  default     = [ "backup", "delete", "deletesas", "get", "getsas", "list", "listsas", "purge", "recover", "regeneratekey", "restore", "set", "setsas", "update" ]
}

variable "default_language" {
  default = "es"
}

# WebRTC client
variable "video_quality" {
  type = map
  default = {
    resolution = 720,
    low_bitrate = 200000,
    med_bitrate   = 500000
    high_bitrate = 1500000
    lastN        = 1,
    layer_suspension = 1
  }
}
