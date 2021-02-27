# sic-mundus-creatus

Terraform configuration to deploy Jitsi-Meet Videoconferencing service on Azure.


Features:

* automatic installation
* load balanced Azure Linux VM Scale Set (hybrid/high availability/spot instance) 
* deploy from Azure Shared Image Gallery
* setup video quality, customization per scale-set
* Build and deploy Jitsi Meet server image (Prosody, Jicofo, Meet, Coturn) 
* Etherpad screensharing
* Azure PostgreSQL server or Ubuntu PostgreSQL storage
* simple Let's Encrypt Certificate management with Azure KeyVault
* Bastion server for admin access and Ansible
* single shard/region. could support scaling to shards/regions with prefix/resource group


### References

https://github.com/hermanbanken/jitsi-terraform-scalable
https://github.com/mavenik/jitsi-terraform
https://github.com/hajowieland/terraform-aws-jitsi
https://medium.com/agranimo/deploy-jitsi-meet-server-using-azure-terraform-7e42bdbd3a9c
[Jitsi Community)[https://jitsi.github.io/handbook/docs/devops-guide/devops-guide-scalable]


### Terraform Cloud

*requires to integrate Terraform Cloud account with Github, or run Terraform locally/somewhere

1. Setup Azure service principal, register application and secret as Terraform environment variables
2. Configure domain, initial username, admin IP address and ssh public key (if exists) as Terraform Variables


### Building the Image

Use the Azure portal or CLI. Separate resource group allows Terraform destroy 

RG=myresourcegroup
GALLERY=mygalleryname
IMAGE_DEF=jitsi_meet_image
VERSION=0.0.1
LOCATION=eastus
SUBSCRIPTION=
VM_IMAGE=
VM_ID="/subscriptions/$SUBSCRIPTION/resourceGroups/$RG/providers/Microsoft.Compute/virtualMachines/$VM_IMAGE"

az sig image-version create --resource-group $RG --gallery-name $GALLERY --gallery-image-definition $IMAGE_DEF --gallery-image-version $VERSIOn --target-regions $LOCATION --managed-image $VM_ID


### Let's Encrypt SSL Certificates

Uses the builtin Jitsi Meet LE cert generation. Additionally upload the certificate dir as base64 to Azure Key Vault and download automatically on new autoscale instances. 

The VMSS instance with permanent public IP should be used for Let's Encrypt steps either on fresh Ubuntu or prior built Jitsi image (just need to run the Let's Encrypt ACME client). To prevent exhausting max ssl certs (5 per 7 days) manually run script steps in image/setup.tpl or uncomment as needed.


### Configure video quality and customization

We can reduce maximum resolution and/or video codec bitrate and set the default codec *VP9*.

Todo: 
**convert to .pfx and use Key Vault for proper certificates**
**Deploy Azure Kubernetes for scale regional Videobridges **
**Migrate configuration, SSL, token, scale set monitoring via Ansible**
**Telephony SIP integration**
**Ideas?**


