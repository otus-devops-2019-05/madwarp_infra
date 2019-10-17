# madwarp_infra
madwarp Infra repository
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
Find the way to establish connection from your machine to **internal** using only single command (without intermediary ssh on **bastion**) - see [step 3 ](connect-through-ssh)
#### Challenge 2
Add alias someinternalhost to simplify connection from client machine to **internal** - see [step 4](connect-through-ssh)
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
direction: inbound
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
2. Create new instance of Compute VM using gcloud
3. Install a couple of apps: Ruby, Bundler, MongoDB manually
4. Clone and install application [application](https://github.com/express42/reddit.git)
5. Create [startupscript](https://cloud.google.com/compute/docs/startupscript) and use it asl part of gcloud command to install all necessary applications automatically
### Steps
#### gcloud
The Cloud SDK is a set of tools for Google Cloud Platform. It contains gcloud, gsutil, and bq command-line tools, which you can use to access Compute Engine, Cloud Storage, BigQuery, and other products and services from the command-line. You can run these tools interactively or in your automated scripts.
Open [GCP sdk](https://cloud.google.com/sdk/docs/) select your platform for installation instructions. Mine is Ubuntu 18.04 LTS and follow instructions below
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
1. Run gcloud init to get started: 
   ```bash
   gcloud init
   ```
1. Enter auth information
1. Create new Compute vm instanse using command:
   ```bash
   gcloud compute instances create reddit-app\
   --boot-disk-size=10GB \
   --image-family ubuntu-1604-lts \
   --image-project=ubuntu-os-cloud \
   --machine-type=f1-micro \
   --tags puma-server \
   --restart-on-failure \
   --zone=us-west1-c
   ```
  All options are self explanatory. gcloud will create vm of type *g1-small* with name reddit-app using Ubuntu 16.04 LTS tagged by *puma-server*
### Travis CI
testapp_IP = 35.198.167.169
testapp_port = 9292
