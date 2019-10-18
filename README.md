# madwarp_infra
madwarp Infra repository
# Markup editors
[Remarkable](https://remarkableapp.github.io)
[Haroopad](http://pad.haroopress.com)
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
Find the way to establish connection from your machine to **internal** using only single command (without intermediary ssh on **bastion**) - see [step 3 ](#connect-through-ssh)
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
  > You can change it later by running [gcloud config set compute/zone NAME] or [gcloud config
 set compute/region NAME][gcloud config set compute/region NAME]
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
   Remeber you tag: **puma-server**
#### Ruby installation
  All options are self explanatory. gcloud will create vm of type *g1-small* with name reddit-app using Ubuntu 16.04 LTS tagged by *puma-server*
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
tag: **puma-server**
source addresses: 0.0.0.0/0
protocol/ports: tcp/*PORT_PUMA*
policy: allow
direction: ingress
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
gcloud compute firewall-rules create puma-server-9292 --direction=INGRESS --priority=1000 --network=default --action=ALLOW --rules=tcp:9292 --source-ranges=0.0.0.0/0 --target-tags=puma-server
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
### Challenges
#### Challenge 1
Parametrize packer-template with *projectId*, *sourceImageFamily*, *machineType*
#### Challenge 2
Parametrize packer-template with *image description*, *type and size of storage*, *network name*, *tags*
#### Challenge 3
Bake the fully operational image of VM with all dependecies and running application
#### Challenge 4
Create new instance of VM backed from image using gcloud
### Steps
#### packer installation
1. [Download](https://www.packer.io/downloads.html) packer for your platform, extract the archive and add directory to PATH
     ```bash
     wget https://releases.hashicorp.com/packer/1.4.4/packer_1.4.4_linux_amd64.zip
     ```
     ```bash
     TBD: extraction
     ```
     ```bash
     TBD: adding to path
     ```
     ```bash
     TBD: checking version
     ```
#### Application Default Credentials (ADC)
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
 "project_id": "infra-189607"
,
 "image_name": "reddit-base-{{timestamp}}",
 "image_family": "reddit-base",
 "source_image_family": "ubuntu-1604-lts",
 "zone": "europe-west1-b",
 "ssh_username": "appuser",
 "machine_type": "f1-micro"
 }
 ]
}
EOF
```
where:

* type: "googlecompute"
* project_id: "infra-189607"
* image_family: "reddit-base" 
* image_name: "reddit-base-{{timestamp}}
* source_image_family: "ubuntu-1604-lts"
* zone: "europe-west1-b" 
* ssh_username: "appuser"
* machine_type: "f1-micro"

1. Add section "provisioners" right after the builders to template:
```
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
1. Replace **project_id** by the name of your project using GCP UI or with gcloud:
```bash
gcloud projects list
PROJECT_ID NAME PROJECT_NUMBER
infra-189607 Infra 529004887562
```
1. validate template using *validate* option and fix errors if necessary:
```bash
packer validate ./ubuntu16.json
```
1. build the image:
```bash
 packer build ubuntu16.json
```