# madwarp_infra
madwarp Infra repository
# Markup editors
* [Remarkable](https://remarkableapp.github.io)
* [Haroopad](http://pad.haroopress.com)
## Homework #3: GCP
### Summary
1. GCP registration and review
1. Adding 2 virtual machines into the project: 
   * **bastion** - machine with external static address available over ssh with key authorization 
   * **internal** - machine available through internal network only
1. Check access over ssh by key from client to **bastion**
1. Check access over ssh from **bastion** to **internal**
1. Configure pritunl vpn-server at **bastion** and check vpn-connection from client

### Challenges
#### Challenge 1
Find the way to establish connection from your machine to **internal** using only single command (without intermediary ssh on **bastion**) - see [step 3](#connect-through-ssh)
#### Challenge 2
Add alias someinternalhost to simplify connection from client machine to **internal** - see [step 4](#connect-through-ssh)
#### Challenge 3
Add valid certificate into pritunl vpn-server using sslip.io/xip.io or Let’s Encrypt services
### Steps
#### GCP
1. Register your GCP account using https://cloud.google.com/free/. Provide a valid Credit Card information if neccesary. GCP gives a year of trial period with 300$ credit account to use any services or you can use limited free of charge common services  
1. Create new project with https://console.cloud.google.com/projectcreate. All subsequent actions will be performed under this project
1. Generate private/pubplic key pair using *ssh-keygen* and enter the passphrase:
   ```bash
   user@host:~$ ssh-keygen 
   Generating public/private rsa key pair.
   Enter file in which to save the key (/home/user/.ssh/id_rsa):    
   Enter passphrase (empty for no passphrase): 
   Enter same passphrase again: 
   Your identification has been saved in /home/user/.ssh/id_rsa.
   Your public key has been saved in /home/user/.ssh/id_rsa.pub.
   The key fingerprint is:
   SHA256:yUZmen/3nGSjOAsP52O1fZKeQ1MQisMgAJhJoqtsWTY user@host
   The key's randomart image is:
   +---[RSA 2048]----+
   |o=..... .     .. |
   |*      . o . ..  |
   |.       + + .  . |
   | .     * . .    .|
   |.  E  . S      . |
   |o + .  o .   .o  |
   |.+       o..o.+* |
   |.         *=.oB=+|
   |          .=+oo++|
   +----[SHA256]-----+
   ```
   * id_rsa is your private key. It will be used to authenticate your client identity by matching with public key 
   * id_rsa.pub is your public key. It should be added into trusted keys of desired server to be connected
1. Add public ssh-key (id_rsa.pub) into global [Metadata](https://console.cloud.google.com/compute/metadata) of Compute Engine. This key will be available for all new projects that will use Compute Engine

#### VM instances of Compute Engine
1. Add *f1-micro* VM instance of region *us-west1* with name **bastion** based on Ubuntu 16.04 LTS and two network interfaces: external(with static IP address) and internal
1. Add *f1-micro* VM instance of region *us-west1* with name **internal** and internal network interface only
1. Add your private key (id_rsa) to the authentication agent of ssh with command
```bash
ssh-add ~/.ssh/id_rsa
```

#### Connect through ssh
1. Connect to the **bastion** server from your client machine using command (replace *EXTERNAL.ADDRESS.OF.BASTION* by IP address):
```bash
ssh -A user@EXTERNAL.ADDRESS.OF.BASTION
```
1. Connect to the **internal** server from the **bastion** machine using command (replace *IP.ADDRESS.OF.INTERNAL* by IP address):
```bash
ssh IP.ADDRESS.OF.INTERNAL
```
1. Connect to the **internal** server from your client machine using advanced command:
```bash
ssh -A user@EXTERNAL.ADDRESS.OF.BASTION "ssh -t -t IP.ADDRESS.OF.INTERNAL"
```
> the command *"ssh -t -t IP.ADDRESS.OF.INTERNAL"* in quotes executes immediately on client machine right the after succesful login. As result second ssh session is established at **bastion** and connects to **internal**. Multiple -t parameter forces terminal allocation
1. Create alias of long connection command for convenience
```bash
echo "alias internalhost='ssh -A user@EXTERNAL.ADDRESS.OF.BASTION \"ssh -t -t IP.ADDRESS.OF.INTERNAL\"'" >> ~/.bashrc
```

#### Connect through vpn
1. Turn on http and https traffic for [**bastion**](https://console.cloud.google.com/compute/instancesDetail/zones/us-east1-b/instances/bastion) VM
1. Install vpn service and mongodb at **bastion** vm
```bash
cat <<EOF> setupvpn.sh
#!/bin/bash
echo "deb http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.4 multiverse" > /etc/apt/sources.list.d/mongodb-org-3.4.list
echo "deb http://repo.pritunl.com/stable/apt xenial main" > /etc/apt/sources.list.d/pritunl.list
apt-key adv --keyserver hkp://keyserver.ubuntu.com --recv 0C49F3730359A14518585931BC711F9BA15703C6
apt-key adv --keyserver hkp://keyserver.ubuntu.com --recv 7568D9BB55FF9E5287D586017AE645C0CF8E292A
apt-get --assume-yes update
apt-get --assume-yes upgrade
apt-get --assume-yes install pritunl mongodb-org
systemctl start pritunl mongod
systemctl enable pritunl mongod
EOF
```
1. sudo bash setupvpn.sh
1. Open https://EXTERNAL.ADDRESS.OF.BASTION/setup and copy result of the command into Setup Key:
   ```bash
   sudo pritunl setup-key
   ```
1. When pritunl will ask for user and password copy result of command:
   ```bash
   sudo pritunl default-password
   ```
1. Add new organization, user with pin code and server. Don't foget to attach organization to server and finally start the server. Remember the *PORT* of running server
1. Mark **bastion** vm instance with network tag *vpn-server-PORT*
1. Open [firewall rules](https://console.cloud.google.com/networking/firewalls/list) of VPC network and add new rule:
tag: *vpn-server-PORT*
source addresses: 0.0.0.0/0
protocol/ports: udp/PORT
policy: allow
direction: ingress
1. Move to the Users section of pritunl UI and download profile (tar archive with *connection.ovpn* file inside)
1. Establish vpn connection using command (enter user and password if necessary):
   ```bash
   sudo openvpn --config connection.ovpn --daemon
   ```
1. Check than **internal** vm is available from your desktop
   ```sudo
   ssh -A user@IP.ADDRESS.OF.INTERNAL
   ```
### Travis CI
bastion_IP = 35.212.183.241
someinternalhost_IP = 10.138.0.2

## Homework #4: Main services of GCP
### Summary
1. Install and configure gcloud
1. Create new instance of Compute VM using gcloud
1. Install a couple of apps: Ruby, Bundler, MongoDB manually
1. Clone and install [application](https://github.com/express42/reddit.git)

### Challenges
#### Challenge 1
Combine installation steps of Ruby, MongoDB and application into scripts - see [step 1](#ruby-installation), see [step 1](#mongodb-installation) and [step 1](#application-installation)
#### Challenge 2
Create [startupscript](https://cloud.google.com/compute/docs/startupscript) and use it as a part of gcloud command to install all necessary applications automatically - see [step 2](#using-startup-scripts-with-gcloud)
#### Challenge 3
Add [firewall rule](#opening-of-port-for-reddit-application) with gcloud - [see](#adding-firewall-rule-with-gcloud)
### Steps
#### gcloud installation
The Cloud SDK is a set of tools for Google Cloud Platform. It contains gcloud, gsutil, and bq command-line tools, which you can use to access Compute Engine, Cloud Storage, BigQuery, and other products and services from the command-line. You can run these tools interactively or in your automated scripts.
Open [GCP sdk](https://cloud.google.com/sdk/docs/) and select your platform for installation instructions. Mine is Ubuntu 18.04 LTS and  instructions for this system are following:
1. Add the Cloud SDK distribution URI as a package source:
```bash
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
```
Make sure you have apt-transport-https installed:
```bash
sudo apt-get install apt-transport-https ca-certificates
```
1. Import the Google Cloud public key: 
```bash
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
```
1. Update and install the Cloud SDK:
```bash
sudo apt update && sudo apt install google-cloud-sdk
```
1. Optionally, you can install any of these additional components:
 * google-cloud-sdk-app-engine-python
 * google-cloud-sdk-app-engine-python-extras
 * google-cloud-sdk-app-engine-java
 * google-cloud-sdk-app-engine-go
 * google-cloud-sdk-datalab
 * google-cloud-sdk-datastore-emulator
 * google-cloud-sdk-pubsub-emulator
 * google-cloud-sdk-cbt
 * google-cloud-sdk-cloud-build-local
 * google-cloud-sdk-bigtable-emulator
 * kubectl
1. Run gcloud init to get started and follow the procedure of registration:
 ```bash
gcloud init
 ```
1. Enter auth information (login into your google accout and grant access of Google Cloud Account SDK to your GCP )
1. Choose desired GCP project or create new
1. Choose default Compute Region and Zone
> You can change it later by running [gcloud config set compute/zone NAME] or [gcloud config set compute/region NAME][gcloud config set compute/region NAME]
1. Verify setup with command
```bash
gcloud info
```
and
```bash
gcloud auth list
Credentialed Accounts
ACTIVE  ACCOUNT
\*       someaccount@gmail.com
```

#### New compute VM instance with gcloud
1. Create new Compute vm instanse using command:
```bash
gcloud compute instances create reddit-app\
--boot-disk-size=10GB \
--image-family ubuntu-1604-lts \
--image-project=ubuntu-os-cloud \
--machine-type=f1-micro \
--tags puma-server \
--restart-on-failure
```
All options are self explanatory. gcloud will create vm of type *g1-small* with name reddit-app using Ubuntu 16.04 LTS tagged by *puma-server*
Remeber you tag: **puma-server**

#### Ruby installation
1. Login into brand new compute vm via ssh [see this section for details](#connect-through-ssh) and install Ruby and Bundler:
```bash
cat <<EOF> install_ruby.sh
#!/bin/bash
sudo apt update && sudo apt install -y ruby-full ruby-bundler build-essential
EOF
```
```bash
chmod +x install_ruby.sh && ./install_ruby.sh
```

#### MongoDB installation
1. Install MongoDB
```bash
cat <<EOF> install_mongodb.sh
#!/bin/bash
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv D68FA50FEA312927
sudo bash -c 'echo "deb http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.2 multiverse" > /etc/apt/sources.list.d/mongodb-org-3.2.list'
sudo apt update && sudo apt install -y mongodb-org
sudo systemctl start mongod
sudo systemctl enable mongod
EOF
```
```bash
chmod +x install_mongodb.sh && ./install_mongodb.sh
```
1. Check the status of MongoDB
```bash
sudo systemctl status mongod
```

#### Reddit installation
1. Clone and install "Reddit" application
```bash
cat <<EOF> deploy.sh
#!/bin/bash
git clone -b monolith https://github.com/express42/reddit.git
cd reddit && bundle install
puma -d
EOF
```
```bash
chmod +x deploy.sh && deploy.sh
```
1. check running port of puma
```bash
ps -aux | grep puma
user     10729  1.7  4.5 515408 26848 ?        Sl   20:22   0:00 puma 3.10.0 (tcp://0.0.0.0:*PORT_PUMA*) [reddit]
```

#### Opening of port for Reddit application
1. Open [firewall rules](https://console.cloud.google.com/networking/firewalls/list) of VPC network and add new rule (replace *PORT_PUMA* by real value):
 * tag: **puma-server**
 * source addresses: 0.0.0.0/0
 * protocol/ports: tcp/*PORT_PUMA*
 * policy: allow
 * direction: ingress
1. Check that application is available to the outer world by opening browser with external IP address of **reddit-app** vm and *PORT_PUMA* of running puma.

#### Using startup scripts with gcloud
gcloud has a option to perform automated tasks every time your instance boots up. It's called startup script and has many options to specify source of th script:
* local startup script - script located on your local computer and provided by file or directly
```bash
gcloud compute instances create example-instance \
--metadata-from-file startup-script=examples/scripts/install.sh
```
or 
```bash
gcloud compute instances create example-instance --tags http-server \
--metadata startup-script='#! /bin/bash
# Installs apache and a custom homepage
sudo su -
apt-get update
```

*  [Cloud Storage](https://cloud.google.com/storage) startup script
```bash
gcloud compute instances create example-instance --scopes storage-ro \
--metadata startup-script-url=gs://bucket/startupscript.sh
```

> I'll choose file as a source of startup script and modify [command](new-compute-vm-instance-with-gcloud) slightly to create new instance of VM with ready to go "Reddit" application right after start

1. Combine **deploy.sh**, **install_mongodb.sh**, **install_ruby.sh** into single script (startupscript.sh) and clean up unnecessary lines 

> You don't have to set permissions on the file to make it executable - gcloud will do it for you

1. Create new VM instance adding *--metadata-from-file startup-script* option:
```bash
gcloud compute instances create reddit-app-with-startup \
--boot-disk-size=10GB \
--image-family ubuntu-1604-lts \
--image-project=ubuntu-os-cloud \
--machine-type=f1-micro \
--tags puma-server \
--restart-on-failure \
--metadata-from-file startup-script=./startupscript.sh
```

#### Adding firewall rule with gcloud
```bash
gcloud compute firewall-rules create puma-server-9292 --direction=INGRESS --priority=1000 --network=default --action=ALLOW --rules=tcp:9292 --source-ranges=0.0.0.0/0 --target-tags=puma-server
```
### Travis CI
testapp_IP = 34.82.59.50
testapp_port = 9292

## Homework #5: Using Packer 
### Summary
1. Install and configure packer
1. Manage Application Default Credentials (ADC) of GCP
1. Create json-template for packer and play with
     * builders section
     * provisioners section
1. Create brande new VM instance from baked image
1. Parametrize packer template
### Challenges
#### Challenge 1
Parametrize packer-template with *projectId*, *sourceImageFamily*, *machineType*, *image description*, *type and size of storage*, *network name*, *tags* - [see](#packer-template-paramterization)
#### Challenge 2
Bake the fully operational image of VM with all dependecies and running application - [see](#immutable-image)
#### Challenge 3
Create new instance of VM backed from image using gcloud - see [step 6](#immutable-image)
### Steps
#### packer installation
1. [Download](https://www.packer.io/downloads.html) packer for your platform, extract the archive and add directory to PATH
```bash
wget https://releases.hashicorp.com/packer/1.4.4/packer_1.4.4_linux_amd64.zip
```

```bash
sudo unzip packer_1.4.4_linux_amd64.zip -d /opt/packer/
```
```bash
#Add this line to the end of ~/.profile
export PATH=$PATH:/opt/packer
#Apply changes
source ~/.profile
```
```bash
packer -v
1.4.4
```
#### Application Default Credentials (ADC)
Packer uses GCP API to manage the cloud resources using auth credentials. Let's create credentials from packer:
```bash
gcloud auth application-default login
```
### Packer Template
1. Prepare template of your image for packer:
```bash
cat <<EOF> ubuntu16.json
{
 "builders": [
 {
 "type": "googlecompute",
 "project_id": "infra-189607",
 "image_name": "reddit-base-{{timestamp}}",
 "image_family": "reddit-base",
 "source_image_family": "ubuntu-1604-lts",
 "zone": "us-west1-c",
 "ssh_username": "appuser",
 "machine_type": "f1-micro"
 }
 ]
}
EOF
```
1. Replace **project_id** by value from you GCP project and change **ssh_username**. You can find projectId by running command:
```bash
gcloud projects list
PROJECT_ID            NAME              PROJECT_NUMBER
numeric-point-256019  My First Project  978260595302
infra-256019          Infra             645207766587
```

The **builders** section defines what will be built by a set of attribute:
* type - cloud platform type of resource ([googlecompute](https://www.packer.io/docs/builders/googlecompute.html) in our case)
* image_name - desired image name with dynamic placeholder filled by current timestamp
* image_family - image group
* source_image_family -  basic image for building
* ssh_username - temporary user for script running (provisioning) durning build process
* etc.

1. Add section "provisioners" right after the builders to template:
```json
"provisioners": [
 {
 "type": "shell",
 "script": "scripts/install_ruby.sh",
 "execute_command": "sudo {{.Path}}"
 },
 {
 "type": "shell",
 "script": "scripts/install_mongodb.sh",
 "execute_command": "sudo {{.Path}}"
 }
 ]
```

The **provisioners** section allows to install software, change system settings and configure applications. We will use scripts from previous sections to install Ruby (*install_ruby.sh*) and mongoDB (*install_mongodb.sh*) to install required software automatically with [shell provisioner](https://www.packer.io/docs/provisioners/shell.html)

1. validate template using *validate* option and fix errors if necessary:
```bash
packer validate ./ubuntu16.json
Template validated successfully.

```
1. And finally build the image:
```bash
packer build ubuntu16.json
...
==> Builds finished. The artifacts of successful builds are:
--> googlecompute: A disk image was created: reddit-base-1571564434
```
1. Check GCP console that [image](https://cloud.google.com/compute/images) is succesfully created
1. Create new instance of VM using gcloud:
```bash
gcloud compute instances create reddit-app-from-image \
--boot-disk-size=10GB \
--image-family reddit-base \
--image-project=infra-256019 \
--machine-type=f1-micro \
--tags puma-server \
--restart-on-failure 
Created [https://www.googleapis.com/compute/v1/projects/otus-infra-256019/zones/us-west1-c/instances/reddit-app-from-image].
NAME                   ZONE        MACHINE_TYPE  PREEMPTIBLE  INTERNAL_IP  EXTERNAL_IP     STATUS
reddit-app-from-image  us-west1-c  f1-micro                   10.138.0.9   35.233.186.249  RUNNING

```
#### Packer template paramterization
User [variables](https://www.packer.io/docs/templates/user-variables.html) allow your templates to be further configured with variables from the command-line, environment variables, Vault, or files
1. Add variables section to template **ubuntu16.json**:
```json
"variables": {
    "project_id": null,
    "source_image_family": null,
    "machine_type":"f1-micro",
    "disk_size":"10",
    "disk_type":"pd-standard",
    "image_description":null,
    "tags":["puma-server"]
}
```
If the default value is null, then the user variable will be required. This means that the user must specify a value for this variable or template validation will fail
1. Modify **builders** section to substitute variables using *{{user `variable`}}* template:
```json
"builders": [
 {
 "type": "googlecompute",
 "project_id": "{{user `project_id`}}",
 "image_name": "reddit-base-{{timestamp}}",
 "image_family": "reddit-base",
 "image_description":"{{user `image_description`}}",
 "source_image_family": "{{user `source_image_family`}}",
 "zone": "us-west1-c",
 "ssh_username": "user",
 "machine_type": "{{user `machine_type`}}",
 "disk_size": "{{user `disk_size`}}",
 "disk_type":"{{user `disk_type`}}",
 "tags":"{{user `tags`}}"
 
 }
 ]
```
1. Create new file **variables.json** and specify actual values for variables:
```bash
cat <<EOF> variables.json
{
  "project_id":"infra-256019",
  "source_image_family": "ubuntu-1604-lts",
  "image_description":"Basic image with Ruby and MongoDB"
}
EOF
```
1. Verify parameterized template using command:
```bash
packer validate -var-file=variables.json ubuntu16.json
```
1. Create new image
```
packer build -var-file=variables.json ubuntu16.json

```

### Immutable image
Reddit-base image still requires to install apllication and start it manually. We can "bake" new image **reddit-full** based on **reddit-base** by adding installation of Reddit and creating reddit.service
1. Copy **ubuntu16.json** to **immutable.json**
1. Change *source_image_family* from variables to **reddit-base** -  new image will be built on top of latest *reddit-base-XXXXXXXXXXX* image with Ruby and MongoDB preinstalled
1. Change *image_name* and *image_family* of *builders* section to **reddit-full**:
```
 "image_name": "reddit-full-{{timestamp}}",
 "image_family": "reddit-full",
```

1. Replace **provisioners** section by
```json
 "provisioners": [
 {
 "type": "shell",
 "script": "scripts/deploy.sh",
 "execute_command": "sudo {{.Path}}"
 },
 {
 "type": "shell",
 "script": "scripts/install_service.sh",
 "execute_command": "sudo {{.Path}}"
 }
 ]
```

where 
* scripts/deploy.sh will clone Reddit repository
* scripts/install_service.sh will create service *reddit* that autostarts after vm instance is up

1. Since template has only one mandatory variable we can specify it directly from command using *-var* option:
```bash
packer validate -var project_id=infra-256019 immutable.json 
```
```bash
packer build -var project_id=infra-256019 immutable.json
```
1. And finally create new instance from **reddit-full** image family:
```bash
gcloud compute instances create reddit-app-from-baked-image \
--boot-disk-size=10GB \
--image-family reddit-full \
--image-project=infra-256019 \
--machine-type=f1-micro \
--tags puma-server \
--restart-on-failure
```

## Homework #6: Infrastructure as a Code with Terraform
### Summary
1. Install and configure Terraform
2. Create vm instances and provisions with terraform
3. Parametrization (input variables) and output values
4. Ssh key and firewall management with teraform

### Challenges
#### Challenge 1
Create input variable for private key - see [step 2](#terraform-parameterizition)
#### Challenge 2
Add multiple ssh keys to GCP project metadata after manual removal - [see](#terraform-and-compute-metadata)
#### Challenge 3
What will happen when changes to resource are made manually and configuration is applied by teradata? - [see](#terraform-immutablity)

### Steps
#### Terraform installation
1. [Download](https://terraform.io/downloads.html) Terraform for your paltform, extract the archive and add directory to PATH
```bash
wget https://releases.hashicorp.com/terraform/0.11.11/terraform_0.11.11_linux_386.zip
```
```bash
sudo unzip terraform_0.11.11_linux_386.zip -d /opt/terraform/
```
```bash
#Add this line to the end of ~/.profile
export PATH=$PATH:/opt/terraform
#Apply changes
source ~/.profile
```
```bash
terraform -v
Terraform v0.11.11
```

#### Terraform configuartion
1. Create file terrafrom/main.tf - this file will be used as main configuration of infrastructure:
```bash
cat <<EOF> main.tf
terraform {
# Version of terraform
required_version = "0.11.11"
}
provider "google" {
# Version of provider
version = "2.0.0"
# project ID
project = "infra-256019"
region = "us-west-c"
}
EOF
```
File contains provider "google" to manage GCP resources
1. All providers of Terraform are loadable modules and should be initialized using command:
```bash
terraform init
```

1. Add new **resource** of *google_compute_instance* after **provider** section:
```
resource "google_compute_instance" "app" {
name = "reddit-app-terraform"
machine_type = "f1-micro"
zone = "us-west1-c"
# Boot disk definition
boot_disk {
initialize_params {
image = "reddit-base"
}
}
# Network interface definition
network_interface {
# Network attach to
network = "default"
# Use ephemeral IP 
access_config {}
}
}
```
1. Validate your plan and check output:
```bash
terraform plan
Plan: 1 to add, 0 to change, 0 to destroy.
```
1. And apply your changes:
```bash
terraform apply
```

#### Terraform state
Terraform has created file **terraform.tfstate** and stores state of managable resouces. Let's find IP address of created VM instance with command:
```bash
cat terraform.tfstate | grep nat_ip
"network_interface.0.access_config.0.nat_ip": "IP.ADDRESS.OF.VM"
```

Terradata provides option *show* that doess pretty much the same:

```bash
terraform show | grep nat_ip
```
As alternative terraform can store values of **terraform.tfstate** in separate files. Lets create new file **output_resources.tf**:
```bash
output "reddit_external_ip" {
value="${google_compute_instance.app.network_interface.0.access_config.0.nat_ip}"
}
```
Now when you call terraform with option *output* you will see exactly what is needed:
```bash
terraform refresh
Outputs:
reddit_external_ip = IP.ADDRESS.OF.VM
```
```bash
terraform output reddit_external_ip
IP.ADDRESS.OF.VM
```
#### Ssh key management
1. Check that VM instance is available via ssh:
```bash
ssh user@IP.ADDRESS.OF.VM
```

1. Now remove your public key from project [metadata](https://cloud.google.com/compute/metadata/sshKeys) and check ssh connection once again:
```bash
ssh user@IP.ADDRESS.OF.VM
Permission denied (publickey)
```
1. Let's add your public key directly into metadata of VM instead of globally defined section:
```json
metadata {
# Path to public key
ssh-keys = "appuser:${file("~/.ssh/warp.pub")}"
}
```
1. Validate updated plan and apply changes:
```bash
terraform plan && terraform apply
Plan: 0 to add, 1 to change, 0 to destroy.
```
1. Check that ssh connection is available again:
```bash
ssh user@IP.ADDRESS.OF.VM
```
#### Firewall rule management
1. Add firewall rule into **main.tf**:
```
resource "google_compute_firewall" "firewall_reddit_puma" {
name = "allow-reddit-9292"
# Network name
network = "default"
# Rules
allow {
protocol = "tcp"
ports = ["9292"]
}
# Address pool
source_ranges = ["0.0.0.0/0"]
# Tags
target_tags = ["reddit-app"]
}
```
1. And add tag **reddit-app** into resource of vm to apply firewall rule:
```
...
zone = "us-west1-c"
# Tag for firewall
tags = ["reddit-app"]
metadata {
...
```
1. Apply changes:
```bash
terraform plan && terraform apply
```

#### Terraform provisioners
[Provisioners](https://www.terraform.io/docs/provisioners/index.html) are called when resource is created/deleted and allow to execute commands on local or remote machine. Let's add provisioner to install reddit application (using **deploy.sh**) and create service 
1. Add new provisioner with name **file** inside VM - it will copy content from **local** *source* (path is relative) to **remote** *destination* :
```
provisioner "file" {
 source = "files/puma.service"
 destination = "/tmp/puma.service"
}
```
1. Add new provisioner with name **remote-exec** - it will execute local script on remote machine:
```
provisioner "remote-exec" {
script = "files/deploy.sh"
}
```

1. Create file **puma.service** and copy to *files* subdirectory:
```
cat <<EOF> puma.service
[Unit]
Desription=Puma HTTP SERVER
After=network.target
[Service]
Type=simple
WorkingDirectory=/home/appuser/reddit
ExecStart=/bin/bash -lc 'puma'
Restart=always
[Install]
WnatedBy=multi-user.target
EOF
```
1. All provisioners are working through ssh so we need to specify connection parameters:
```
connection {
type = "ssh"
user = "appuser"
agent = false
# Path to private key
private_key = "${file("~/.ssh/appuser")}"
}
```
1. Since provisioners are running after create/removal of resource, terraform has option *taint* to mark resource for disposal right before *apply*:
```bash
terraform taint google_compute_instance.app
The resource google_compute_instance.app in the module root
has been marked as tainted!
```

1. Apply changes:
```bash
terraform plan && terraform apply
```

#### Terraform parameterizition
Terraform allows to organize parameteriztion by using input variables
1. Create file variables.tf with following content:
```
# General section
variable project {
  description = "GCP project indetificator"
}
variable region {
  description = "Region"

  # Default value
  default = "us-west1-c"
}
# Ssh section
variable public_key_path {
  description = "Path to the public key used for ssh access"
}
variable private_key_path {
  description = "Path to the private key used for ssh access"
}
variable ssh_user {
  description = "User for ssh sessions during provisioning"
}
# Instance section
variable disk_image {
  description = "Basic Disk image"
}
variable compute_instance_zone {
  description = "VM instance zone"
  default     = "us-west1-c"
}
```

1. Now we can reference to this variables using syntax *${var.variable_name}* in **main.tf**:
```
provider "google" {
version = "2.0.0"
project = "${var.project}"
region = "${var.region}"
}
...
boot_disk {
initialize_params {
image = "${var.disk_image}"
}
}
...
metadata {
ssh-keys = "appuser:${file(var.public_key_path)}"
}
...
# Connections for provisioning
  connection {
    type  = "ssh"
    user  = "${var.ssh_user}"
    agent = false

    # Path to private key
    private_key = "${file(var.private_key_path)}"
  }
```
1. Define variables in file **terraform.tfvars**:
```
project = "infra-179015"
public_key_path = "~/.ssh/appuser.pub"
disk_image = "reddit-base"
```

1. Now destroy all previously created infrastructure using option *destoy*:
```bash
terraform destroy
```

1. And create all ifranstructure from scratch (terraform will use variables from **terraform.tfvars**)
```bash
terraform plan
```
```bash
terraform apply
```
1. Check that everything is up and running by openning url
```
http://reddit_external_ip:9292
```

#### Terraform and Compute metadata
Now we can restore ssh key from metadata of the whole project by adding **google_compute_project_metadata** resource and specifing **ssh-keys** of *metadata* (multiple keys are separated by *\n*):
```
# Global project metadata
resource "google_compute_project_metadata" "default" {
  metadata = {
    # Path to public key
    ssh-keys = "appuser1:${file(var.public_key_path)}\nappuser2:${file(var.public_key_path)}"
  }
}
```

#### Terraform immutablity
If we will add new key manually using GCP console and apply configuration with *terraform apply* all changes that are not in configuration will be destroyed

## Homework #7: Infratructure as a Code with Terraform (continues)
### Summary
### Challenges
#### Challenge 1
Create module vpc with firewall rules
### Steps
#### Add existing firewall rule
1. Add default firewall rule for ssh:
```json
resource "google_compute_firewall" "firewall_ssh" {
  name    = "default-allow-ssh"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
}
```

1. Try to apply:
```bash
terraform apply
Error: Error applying plan:
1 error(s) occurred:
google_compute_firewall.firewall_ssh: 1 error(s) occurred:
google_compute_firewall.firewall_ssh: Error creating Firewall: googleapi: Error 409: The resource 'projects/infra-256019/global/firewalls/default-allow-ssh' already exists, alreadyExists
```
It's obvious that we can't add two firewall rules with the same name

#### Import existing resources
Terraform has an option to [import](https://www.terraform.io/docs/import/importability.html) existing infrastructure resources
```bash
terraform import google_compute_firewall.firewall_ssh default-allow-ssh
google_compute_firewall.firewall_ssh: Importing from ID "default-allow-ssh"...
google_compute_firewall.firewall_ssh: Import complete!
  Imported google_compute_firewall (ID: default-allow-ssh)
google_compute_firewall.firewall_ssh: Refreshing state... (ID: default-allow-ssh)

Import successful!

The resources that were imported are shown above. These resources are now in
your Terraform state and will henceforth be managed by Terraform.

```
#### Adding static IP address
1. Add to **main.tf**
```
resource "google_compute_address" "app_ip" {
name = "reddit-app-ip"
}
```
1. Apply changes
```bash
terraform apply
```
> If you got an error similar to *Quota 'STATIC_ADDRESSES' exceeded.  Limit: 1.0 in region us-west1* just remove all static leases from [VPC network](https://console.cloud.google.com/networking/addresses/list)
1. Bind static IP to VM instance by adding value to **nat_ip** property of *access_config*:
```json
...
access_config = {
nat_ip = "${google_compute_address.app_ip.address}"
}
...
```

#### Implicit and explicit dependecies
When one resource has a reference to the property of another one terraform builds dependency graph of resources and creates resources according to this dependecies. This impacts the order of resources creation. Thus terraform will start from static IP address and then create VM instance cause this resources have **implicit** dependency. There is also **explicit** dependency by using [depends on](https://www.terraform.io/docs/configuration/resources.html)

#### Create separate VM for MongoDB and Reddit App
1. Copy packer/ubuntu16.json to app.json and db.json
```bash
cd packer && cp ubuntu16.json app.json && cp ubuntu16.json db.json
```

**app.json** image will contain Ruby and Reddit app and **db.json** will contain MongoDB
2. Change image_name and image_family leave only necessary provisioners
```
...
 "image_name": "mongodb-reddit-base-{{timestamp}}",
 "image_family": "mongodb-reddit-base",
...
"provisioners": [
 {
 "type": "shell",
 "script": "scripts/install_mongodb.sh",
 "execute_command": "sudo {{.Path}}"
 }
 ]
```
and
```
...
"image_name": "reddit-app-ruby-base-{{timestamp}}",
 "image_family": "reddit-app-ruby-base",
...
"provisioners": [
 {
 "type": "shell",
 "script": "scripts/install_ruby.sh",
 "execute_command": "sudo {{.Path}}"
 },
 {
 "type": "shell",
 "script": "scripts/deploy.sh",
 "execute_command": "sudo {{.Path}}"
 }
```

1. Move Reddit app VM resource with firewall rule to separate **app.tf**
2. Move MongoDB VM resource with firewall rule to separate **db.tf**
3. Move ssh firewall rule to **vpc.tf**:
```
# Ssh default rule
resource "google_compute_firewall" "firewall_ssh" {
  name        = "default-allow-ssh"
  network     = "default"
  description = "Allow SSH from anywhere"
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
}
```

#### Terraform modules
1. Create directory **modules** and copy tf files
```bash
mkdir -p modules/db && mkdir -p modules/app && cp db.tf modules/db/main.tf && cp app.tf modules/app/main.tf && cp output_resources.tf modules/app/
```

1. Copy variables.tf to **db** and **app** module:
```bash
cp variables.tf modules/app/ && cp variables.tf modules/db/
```

1. Insert into **main.tf**:
```
# Modules
module "app" {
  source          = "modules/app"
  public_key_path = "${var.public_key_path}"
  compute_instance_zone = "${var.compute_instance_zone}"
  app_disk_image  = "${var.app_disk_image}"
  ssh_user = "${var.ssh_user}"
}
module "db" {
  source          = "modules/db"
  public_key_path = "${var.public_key_path}"
  compute_instance_zone = "${var.compute_instance_zone}"
  db_disk_image   = "${var.db_disk_image}"
  ssh_user = "${var.ssh_user}"
}
```

1. And initialize new modules (they are will be loaded from *source* path)
```bash
terraform get
- module.app
  Getting source "modules/app"
- module.db
  Getting source "modules/db"
```

1. Try to validate infrastructure:
```bash
terraform validate
Error: output 'reddit_external_ip': unknown resource 'google_compute_instance.app' referenced in variable google_compute_instance.app.network_interface.0.access_config.0.nat_ip
```

1. Edit *output_variables.tf* and replace **google_compute_instance.app** by **module.app**:
```
output "reddit_external_ip" {
  value = "${module.app.reddit_external_ip}"
}
```

#### VPC module
1. Create directory **vpc** inside **modules** and copy files:
```bash
mkdir -p modules/vpc && cp vpc.tf modules/vpc/main.tf
```

1. Add new module to main.tf:
```
module "vpc" {
  source          = "modules/vpc"
}
```

1. Initalize new module:
```bash
terraform get
 - module.app
 - module.db
 - module.vpc
Getting source "modules/vpc"
```

1. Apply changes:
```bash
terraform apply
```

1. Add new variable **source_ranges** by creating the file **variables.tf** into *vpc* module:
```
variable source_ranges {
description = "Allowed IP addresses"
default = ["0.0.0.0/0"]
}
```

1. Add reference to the variable **source_ranges** of **modules/vpc/main.tf**: 
```
source_ranges = "${var.source_ranges}"
```

1. Add variable to module **vpc** of **main.tf**:
```
module "vpc" {
  source = "modules/vpc"
  source_ranges = "${var.ssh_source_ip_ranges}"
}
```

1. Add variable **ssh_source_ip_ranges** to **variables.tf**:
```
variable ssh_source_ip_ranges {
  description = "Allowed IP-address ranges to connect to shh"
  default = ["0.0.0.0/0"]
}
```

1. Try to change the value of ssh_source_ip_ranges and check how terraform will aplly new rules:
```
~ module.vpc.google_compute_firewall.firewall_ssh
source_ranges.1080289494: "0.0.0.0/0" => ""
source_ranges.898092250:  "" => "34.82.6.244/32"
```

#### Module reusability
The main purpose of modules is to solve the problem of reusability and follow **DRY** (Don't Repeat Yourself) principle.
1. Create two directories **stage** and **prod** and copy *main.tf*, *variables.tf* and *output_resources.tf*:
```
mkdir stage prod && cp main.tf variables.tf output_resources.tf stage/ && cp main.tf variables.tf output_resources.tf prod/
```

1. Change the module **source** path of newly created main.tf of each environment to **../module/XXX**:
```
...
module "app" {
  source = "../modules/app"
...
module "db" {
  source = "../modules/db"
...
module "vpc" {
  source = "../modules/vpc"
...
```

1. And initialize terraform and modules for each environment:
```
cd stage && terraform init && terraform apply
```

#### Module registry
HashiCorp has created public module [registry](https://registry.terraform.io/) for terrform. Let's use module [storage-bucket](https://registry.terraform.io/modules/SweetOps/storage-bucket/google) to create Storage
1. Create file **storage-bucket.tf** inside *terraform* directory with content:
```
provider "google" {
  version = "2.0.0"
  project = "${var.project}"
  region  = "${var.region}"
}
module "storage-bucket" {
  source  = "SweetOps/storage-bucket/google"
  version = "0.1.1"
  # Change names if necessary
  name = ["storage-bucket-terraform-stage", "storage-bucket-terraform-prod"]
}
output storage-bucket_url {
  value = "${module.storage-bucket.url}"
}
```

1. Define variables inside **variables.tf**:
```
# General section
variable project {
  description = "GCP project indetificator"
}
variable region {
  description = "Project region"
  # Default value
  default = "us-west1"
}
```

1. Apply changes:
```bash
terraform init && terraform apply
Apply complete! Resources: 2 added, 0 changed, 0 destroyed.
Outputs:
storage-bucket_url = [
    gs://storage-bucket-terraform-stage,
    gs://storage-bucket-terraform-prod
]
```

1. Check that both storage are created using [console](https://console.cloud.google.com/storage/browser) or using gcloud
```bash
TBD
```

#### Remote backend
1. Create remote backend configuration in **backend.tf** of *stage*:
```
terraform {
  backend "gcs" {
    bucket = "storage-bucket-terraform-stage"
    prefix = "stage"
  }
}
```

1. And renitialize terraform:
```bash
terraform init
Initializing the backend...
Do you want to copy existing state to the new backend?
Previous (type "local"): /tmp/terraform448522822/1-local.tfstate  New      (type "gcs"): /tmp/terraform448522822/2-gcs.tfstate
Successfully configured the backend "gcs"! Terraform will automatically
use this backend unless the backend configuration changes.
```

#### Adding provisioners to module app
1. Add connection and provisioners to *modules/app/main.tf*:
```
# Connections for provisioning
  connection {
    type  = "ssh"
    user  = "${var.ssh_user}"
    agent = false

    # Path to private key
    private_key = "${file(var.private_key_path)}"
  }
 # Provisioners
  provisioner "file" {

    # Commented since terraform copies file into 
    # .terraform/modules/XXXX/files/puma.service
    # and calls it without adding '/files'
    # source    = "${path.module}/files/puma.service"
    source      = "${path.module}/puma.service"
    destination = "/tmp/puma.service"
  }

  provisioner "remote-exec" {

    # Commented since terraform copies file into 
    # .terraform/modules/XXXX/files/deploy.sh
    # and calls it without adding '/files'
    # script = "${path.module}files/deploy.sh"
    script   = "${path.module}/deploy.sh"
}
```
${path.module} - is dynamic variable that will be replaced by real path of module location. Otherwise all files are looked up using relative path to the working directory of terraform execution
> Don't know why but terraform does not handle subdirectories for module files correctly
1. Add variable **mongo_db_internal_ip** into *outputs.tf* file of *db*:
```
output "mongo_db_internal_ip" {
  value = "${google_compute_instance.db.network_interface.0.network_ip}"
}
```

1. Add output variable to **outputs.tf** of *stage* and *prod*:
```
output "db_internal_ip" {
  value = "${module.db.mongo_db_internal_ip}"
}
```

1. Add input variable **db_address** to variables.tf of **app** module:
```
# MongoDB environment variable
variable db_address {
  description = "Environment variable DATABASE_URL for MongoDB connection"
  default = "localhost"
}
```

1. Add new provisioner to **app** module that will export **DATABASE_URL** variable with value of using db_address:
```
 provisioner "remote-exec" {
    inline = [
      "export DATABASE_URL=${var.db_address}:27017"
    ]
  }
```

1. Use output variable **mongo_db_internal_ip** of *db* module as input value for **db_address** of *app* module :
```
# Modules
module "app" {
  source                = "../modules/app"
  public_key_path       = "${var.public_key_path}"
  private_key_path      = "${var.private_key_path}"
  compute_instance_zone = "${var.compute_instance_zone}"
  app_disk_image        = "${var.app_disk_image}"
  ssh_user              = "${var.ssh_user}"
  db_address            = "${module.db.mongo_db_internal_ip}"
}
```
