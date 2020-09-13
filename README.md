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

