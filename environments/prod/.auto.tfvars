prefix = "meet1"
location = "eastus"
web_host = "meet"
video_host = "bridge"
vmss_count = 1
vmss_sku = "Standard_D2a_v4" #spot pricing | "Standard_A1_v2"
imagevm_sku = "Standard_D2a_v4" #"Standard_A2_v2"
bastion_sku = "Standard_B1s"
# edit RG, SIG and image name
vmss_image_resource_id = "/subscriptions/ACCOUNT_NO/resourceGroups/jitsi_images/providers/Microsoft.Compute/galleries/jitsi/images/jitsi-shared-general"
publisher = "Canonical"
offer = "0001-com-ubuntu-server-focal"
sku = "20_04-lts"
image_version = "latest"
ssh_file= null
jitsi_user="open"
jitsi_password="sesame"
default_language = "es"

/*
 also sets VP9 default request.
 "0" to disable
  remove to leave Jitsi defaults (1.5 mbps/500/200)
*/
video_quality = {
  resolution = 720,
  low_bitrate = 150000,
  med_bitrate   = 450000
  high_bitrate = 1450000
  lastN        = 1,
  layer_suspension = 1
}