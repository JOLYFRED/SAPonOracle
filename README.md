# 2-Tier-configuration for SAP on Oracle Linux on Azure

## Create the environment

### Step 1: Create the Virtual Network on the Azure Portal
<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fhsirtl%2Fsap-2-tier-on-oracle-linux%2Fmaster%2Fnetwork.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

This creates a Virtual Network with two subnets. The Virtual Machines to be provisioned in
following steps will be installed into these subnets.

The Virtual Network will be installed with following configuration:

Parameter | Name | Address Space
--------- | ------- | -------------
VNet | IT-DevTest-Vnet | 10.26.1.0/24
App Server Subnet | SAPPoc-APP | 10.26.1.32/28
DB Server Subnet | SAPPoc-DB | 10.26.1.48/28

### Step 2 (optional): Create a jumpbox VM on the Azure Portal
<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fhsirtl%2Fsap-2-tier-on-oracle-linux%2Fmaster%2Fjumpbox.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

A deployment creates a small jumpbox machine into the network. This jumpbox is equipped with
a public IP address. So it can be used for administrating the SAP VMs (to be provisioned in 
the next step).

### Step 3: Create and setup the SAP VMs on the Azure Portal
<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fhsirtl%2Fsap-2-tier-on-oracle-linux%2Fmaster%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

This creates two Oracle-Linux 7.2 based Virtual Machines: one application server
machine, one database server. These VMs can be used to install SAP Netweaver.
The deployment script not only provisions the machines but also does some initial setup.

**Beware:** due to some issues with newest kernels, the script excludes the kernel while updating the system via `sudo yum update`!