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
    > File contains provider "google" to manage GCP resources
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
    ssh-keys = "appuser:${file("~/.ssh/appuser.pub")}"
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
1. Import existing infrastructure into terraform
2. Implicit and explicit resource dependencies
3. Separate VM for application and database
4. Using terraform modules
5. Create two environments and reuse existing modules
6. Use Google Storage bucket as backend for terraform

### Challenges
#### Challenge 1
Create module vpc with firewall rules and grant access to random IP address - see [step 9](#vpc-module)
#### Challenge 2
Move terraform backend to Cloug Bucket - [see](#remote-backend)
#### Challenge 3
Add provisioners that will install and start application - [see](#adding-provisioners-to-module-app)
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

## Homework #8: Ansilble first steps
### Summary
1. Ansible installation and configuration
2. Basic functions and inventory
3. Ansible modules
4. Simple playbook

### Challenges
#### Challenge 1
Create dynamic inventory based on script execution - see [here](#dynamic-inventories)
### Steps
#### Ansible installation
Ansible requires python 2.7, pip or easy_install nad python on all client machines
1. Install pip or easy_install:
    ```bash
    sudo apt install python-pip
    ```
1. Create file **requirements.txt** that will be used to specify dependencies for pip with content:
    ```
    ansible>=2.4
    ```
1. Install Ansible and check installation:
    ```
    sudo apt install ansible
    ```
    ```bash
    ansible --version
    ansible 2.8.6
    ```

#### Ansible structure
Ansible is based on concepts of:
 * [ansible.cfg](https://raw.githubusercontent.com/ansible/ansible/devel/examples/ansible.cfg) - main configuration file. Used for plugin management, default vaules and redefine of parameters, inventory location
 * [invetory](https://docs.ansible.com/ansible/latest/intro_inventory.html) - grouping of hosts, nested groups, aliases for hosts
 * [modules](https://docs.ansible.com/ansible/latest/modules_by_category.html) - libraries for task execution and tracking the state of tasks. OS operations, software of hardware, external resource management
 * playbooks - set of scenarios to describe software installation and configuration using host grouping

#### Ansible configuration
Ansible can use file as inventory of servers by specifiening **-i** option
1. Create **inventory** file and add *redditappserver* entry for reddit VM instance (replace reddit_external_ip by real IP address):
    ```
    redditappserver ansible_host=reddit_external_ip ansible_user=appuser \    ansible_private_key_file=~/.ssh/appuser
    ```
1. Check that ansible will connect to *redditappserver* by using module *ping*:
    ```bash
    ansible redditappserver -i ./inventory -m ping
    redditappserver | SUCCESS => {
        "ansible_facts": {
            "discovered_interpreter_python": "/usr/bin/python"
        }, 
        "changed": false, 
        "ping": "pong"
    }
    ```
1. Add *dbserver* entry for MongoDB VM instance (replace db_external_ip by real IP address):
    ```
    dbserver ansible_host=db_external_ip ansible_user=appuser \    ansible_private_key_file=~/.ssh/appuser
    ```
1. Check that ansible will connect to *dbserver* by using module *ping*:
    ```bash
    ansible dbserver -i ./inventory -m ping
    dbserver | SUCCESS => {
        "ansible_facts": {
            "discovered_interpreter_python": "/usr/bin/python"
        }, 
        "changed": false, 
        "ping": "pong"
    }
    ```

Ansible command looks too long: you have to specify inventory file for each invocation.
1. Let's create **ansible.cfg** file and specify all options from **inventory** file:
    ```
    [defaults]
    inventory = ./inventory
    remote_user = appuser
    private_key_file = ~/.ssh/appuser
    host_key_checking = False
    retry_files_enabled = False
    ```
1. Remove all duplicated option from inventory file. It should look like this:
    ```
    redditappserver ansible_host=reddit_external_ip
    dbserver ansible_host=db_external_ip
    ```
1. Use module **command** to execute *uptime* in remote hosts with **-a** module option (*-a* means argument):
    ```bash
    ansible dbserver -m command -a uptime
    dbserver | CHANGED | rc=0 >>
    08:54:48 up 14:07,  1 user,  load average: 0.00, 0.00, 0.00
    ```

#### Host grouping - INI format
We can specify the group of hosts to to manage all of them together in **inventory** file
1. Add group **app** and **db** to **inventory**:
    ```
    [app] # Group name
    redditappserver ansible_host=reddit_external_ip
    [db] # Group name
    dbserver ansible_host=db_external_ip
    ```
1. Now we can execute commands by groups instead of servers:
    ```bash 
    ansible app -m ping
    ```

#### Host grouping - YAML format
[Inventory's](https://docs.ansible.com/ansible/latest/user_guide/intro_inventory.html) yaml format have been added to Ansible tsrarting from v. 2.4
1. Create **inventory.yml** file (replace *reddit_external_ip* and *db_external_ip*):
    ```yml
    app:
      hosts:
        redditappserver:
          ansible_host: reddit_external_ip
    db:
      hosts:
        dbserver:
          ansible_host: db_external_ip
    ```
1. Validate **inventory.yml** using *-i* option of ansible:
    ```bash
    ansible all -m ping -i inventory.yml
    ```

#### Checking version of installed components
1. Check the version of Ruby at **app** group using **command** module:
    ```bash
    ansible app -m command -a 'ruby -v'
    edditappserver | CHANGED | rc=0 >>
    ruby 2.3.1p112 (2016-04-26) [x86_64-linux-gnu]
    ```
1. Check the version of Bunder at **app** group using **command** module:
    ```bash
    ansible app -m command -a 'bundler -v'
    redditappserver | CHANGED | rc=0 >>
    Bundler version 1.11.2```
    ```
1. Check version of Bunlder and Ruby with single command:
    ```bash
    ansible app -m command -a 'ruby -v; bundler -v'
    redditappserver | FAILED | rc=1 >>
    ruby: invalid option -;  (-h will show valid options) (RuntimeError)non-zero return code
    ```
    > Module **command** does not use shell (*sh* or *bash*). So stream redirection or pipes will not work. Use module **shell** in that case

1. Check version of Bunlder and Ruby with **shell** module in single command:
    ```bash
    ansible app -m shell -a 'ruby -v; bundler -v'
    redditappserver | CHANGED | rc=0 >>
    ruby 2.3.1p112 (2016-04-26) [x86_64-linux-gnu]
    Bundler version 1.11.2
    ```

#### Checking service status
Let's check status of *mongod* service of **db** intstance host using different approaches
1. Using module *command* or *shell*:
    ```bash
    ansible db -m command -a 'systemctl status mongod'
    ```
    ```bash
    ansible db -m shell -a 'systemctl status mongod'
    ```
1. Using module *systemd* dedicated to service management:
    ```bash
    ansible db -m systemd -a name=mongod
    ```
1. Using module *service* compatible with *init.d* services:
    ```bash
    ansible db -m service -a name=mongod
    ```

#### Using git module
1. Call *git* module twice
    ```bash
    ansible app -m git -a 'repo=https://github.com/express42/reddit.git dest=/home/appuser/reddit'
    ```
    ```bash
    ansible app -m git -a 'repo=https://github.com/express42/reddit.git dest=/home/appuser/reddit'
    ```
    All invocations are completed succesfully

1. Call module *command* and check the error:
    ```bash
    ansible app -m command -a 'git clone https://github.com/express42/reddit.git /home/appuser/reddit'
    redditappserver | FAILED | rc=128 >>
    fatal: destination path '/home/appuser/reddit' already exists and is not an empty directory.non-zero return code
    ```

#### Writing playbooks
Playbooks is a list of scenarios that will use ansible modules to reach target state of system. Single scenario called a *play*. Scenarios are executed in order of appearence. Tasks are executed sequentially.
1. Create file **ansible/clone.yml** with following content:
    ```yml
    - name: Clone
      hosts: app
      tasks:
        - name: Clone Reddit repo
          git:
            repo: https://github.com/express42/reddit.git
            dest: /home/appuser/reddit
    ```
    * **hosts** - target servers
    * **tasks** - list of modules to be executed
    * **git** - git module with arguments
1. Execute playbook **clone.yml**:
    ```bash
    ansible-playbook clone.yml
    PLAY RECAP ****************************************
    redditappserver            : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
    ```
1. Remove **reddit** directory of **app** server:
    ```bash
    ansible app -m command -a 'rm -rf ~/reddit'
    redditappserver | CHANGED | rc=0 >>
    ```

1. Execute playbook **clone.yml** once again:
    ```bash
    ansible-playbook clone.yml
    PLAY RECAP ****************************************
    redditappserver            : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
    ```
    > The only differnce of output is **changed=1**. After removal of *reddit* directory Ansible checked out a fresh copy of Reddit repository and reported that state of instance has changed

#### Dynamic inventories
Ansible supports dynamic generation of inventory by calling a [script](https://docs.ansible.com/ansible/latest/dev_guide/developing_inventory.html#developing-inventory-scripts) that shoud return json to standart output. But this json differs from static json inventory
1. Change yml-inventory to json-inventory and save content to file **inventory-static.json**:
    ```json
    {
      "app": {
          "hosts": {
            "redditappserver": {
                "ansible_host": "reddit.external.ip.address"
            }
          }
      },
      "db": {
          "hosts": {
            "dbserver": {
                "ansible_host": "db.external.ip.address"
            }
          }
      }
    }
    ```
    ```bash
    # Checking json-inventory
    ansible all -m ping -i inventory-static.json
    ```

1. Create script **dynamic_inventory.sh** that grabs output variables **reddit_external_ip** and **db_external_ip** using *terraform output* command, injects the vaules of terraform variables and prints content in json format:
    ```bash
    #!/bin/bash
    currentDir=$(pwd)
    cd $currentDir/../terraform/stage
    reddit_external_ip=$(terraform output reddit_external_ip)
    db_external_ip=$(terraform output db_external_ip)
    cd $currentDir
    scriptContent=" 
    {
        "_meta": {
          "hostvars": {}
        },
        "app": {
          "hosts": ["$reddit_external_ip"]
        },
        "db": {
          "hosts": ["$db_external_ip"]
        }
    }
    "
    echo $scriptContent
    echo $scriptContent > inventory.json
    ```
1. Execute the script and check the output:
    ```
    chmod +x dynamic_inventory.sh && ./dynamic_inventory.sh
    { _meta: { hostvars: {} }, app: { hosts: [reddit_external_ip] }, db: { hosts: [db_external_ip] } }
    ```
    > Have you noticed the difference between static and dynamic json? We have added *_meta* section to return all of the host variables in one script execution

1. Now we can add **dynamic_inventory.sh** as inventory to **ansible.cfg** and check that everything is working smoothly:
    ```
    [defaults]
    # Ini inventory
    #inventory = ./inventory
    # Dynamic inventory 
    inventory = ./dynamic_inventory.sh
    ```
    ```bash
    ansible all -m ping
    ```

## Homework # 9: Ansible advanced technics
### Summary
1. Using playbooks, handlers and templates with single playbook and single scenario (play)
2. Using playbooks, handlers and templates with single playbook and multiple scenarios (plays)
3. Using multiple playbooks
4. Change provisioners from packer to ansible playbooks

### Turning off provisioners of app and dm modules of terraform
#### Single playbook and single scenario
MongoDB is listening *127.0.0.1* by default. Since MongoDB now is working in separate VM we need to change configuration of database to listen on interface that is available to Reddit application VM
1. Create file **ansible/reddit_app_one_play.yml** and add *mongodb* configuration with tag **db-tag**:
    ```
    ---
    - name: Configure hosts & deploy application
      hosts: all
      tasks:
        - name: Change mongo config file
          become: true # <-- Execute under root
          template:
            src: templates/mongod.conf.j2 # <-- Path to local template
            dest: /etc/mongod.conf # <-- Path to remote host
            mode: 0644 # <-- Permisssions of file
          tags: db-tag
    ```
    > Adding tag **db-tag** into the task gives possibility to  execute task individually using comand *--limit*
1. Create file **templates/mongod.conf.j2**:
    ```yaml
    # Where and how to store data.
    storage:
      dbPath: /var/lib/mongodb
      journal:
        enabled: true
    # where to write logging data.
    systemLog:
      destination: file
      logAppend: true
      path: /var/log/mongodb/mongod.log
    # network interfaces
    net:
      # default - is a filter of Jinja2. Use value of argument when variable at the left is undefined
      port: {{ mongo_port | default('27017') }}
      bindIp: {{ mongo_bind_ip }}
    ```

1. Execute command **ansible-playbook** with option *--check* to verify the syntax and check modifications:
    ```bash
    ansible-playbook reddit_app_one_play.yml --check --limit db
    TASK [Change mongo config file]
    ************************************
    fatal: [35.247.70.59]: FAILED! => {"changed": false, "msg": "AnsibleUndefinedVariable: 'mongo_bind_ip' is undefined"}
    PLAY RECAP
    ************************************
    35.247.70.59               : ok=1    changed=0    unreachable=0    failed=1
    ```

    > option *--limit* overrides target hosts of playbook

2. Add missing variable **mongo_bind_ip** using *vars* block:
    ```yaml
    ...
    - name: Configure hosts & deploy application
      hosts: all
      vars:
        mongo_bind_ip: 0.0.0.0 # <-- Variable with default value
      tasks:
    ...
    ```

##### Ansible handlers
Ansible handlers are similar to tasks but are executed using notifcations from task when it changes the state. Userfull for resttart of services when cafiguration files are changed
1. Add block **handlers** to  *reddit_app_one_play.yml* and new task *"restart mongod"*:
    ```yaml
    ...
        tags: db-tag
      handlers: 
        - name: restart mongod
          become: true
          service: name=mongod state=restarted
    ```

1. Apply changes:
    ```bash
    ansible-playbook reddit_app_one_play.yml --limit db
    ```

##### Application tasks
1. Create file **files/puma.service** with following content:
    ```
    [Unit]
    Description=Puma HTTP Server
    After=network.target
    [Service]
    Type=simple
    EnvironmentFile=/home/appuser/db_config
    User=appuser
    WorkingDirectory=/home/appuser/reddit
    ExecStart=/bin/bash -lc 'puma'
    Restart=always
    [Install]
    WantedBy=multi-user.target
    ```

1. Add 2 tasks with module *copy* and systemd to copy prepared unit-file and configure autostart:
    ```yaml
    tasks:
    - name: Change mongo config file
    ...
    - name: Add unit file for Puma
      become: true
      copy:
        src: files/puma.service
        dest: /etc/systemd/system/puma.service
      tags: app-tag
      notify: reload puma
    - name: enable puma
      become: true
      systemd: name=puma enabled=yes
      tags: app-tag
    ```

1. Add notifier to restart puma service:
    ```
    handlers:
    - name: restart mongod
      become: true
      service: name=mongod state=restarted
    - name: reload puma
      become: true
      systemd: name=puma state=restarted
    ```

1. Create template file **templates/db_config.j2** containing value for environment variable *DATABASE_URL* to redefine address of MongoDB for Reddit app:
    ```
    DATABASE_URL={{ db_internal_ip }}
    ```

1. Add variable **db_internal_ip** to the variables section of playbook (replace ADDRESs.OF.MONGO.DB by internal ip address of mongodb instance). The placeholder **db_internal_ip** of *db_config.j2* will be replaced by the  value from palybook variable:
    ```
    db_internal_ip: ADDRES.OF.MONGO.DB
    ```

1. Add task to copy **db_config** to the directory of [EnvironmentFile](#application-unit):
    ```
    - name: Add unit file for Puma
    ...
    - name: Add config for DB connection
    template:
    src: templates/db_config.j2
    dest: /home/appuser/db_config
    tags: app-tag
    ```

1. Verify and apply changes:
    ```bash
    ansible-playbook reddit_app_one_play.yml --check --limit app --tags app-tag
    ```
    ```bash
    ansible-playbook reddit_app_one_play.yml --limit app --tags app-tag
    ```

##### Database tasks
1. Add new tasks with modules **git** and **bundler** to checkout Reddit application and install Ruby Gems:
    ```
    - name: Fetch the latest version of application code
      git:
        repo: 'https://github.com/express42/reddit.git'
        dest: /home/appuser/reddit
        version: monolith # <-- branch
      tags: deploy-tag
      notify: reload puma
    - name: Bundle install
      bundler:
        state: present
        chdir: /home/appuser/reddit # <-- working directory of bundler
      tags: deploy-tag
    ```

1. Verify and apply changes using tag **deploy-tag**:
    ```bash
    ansible-playbook reddit_app_one_play.yml --check --limit app --tags deploy-tag
    ```
    ```bash
    ansible-playbook reddit_app_one_play.yml --limit app --tags deploy-tag
    ```

#### Single playbook and several plays (scenarios)
Previously we have to specify *-limit* option to apply changes to selected groups of servers (app, db) only and *--tags* to execute limited set of tasks. It looks cumbersome. Let`s divide this single scenario
##### Play for MongoDB
1. Copy variables, tasks, handlers related to MongoDB to **reddit_app_multiple_plays.yml**
    ```
    ---
    - name: Configure MongoDB for Reddit app # < -- Changed description
      hosts: db # < -- Default server group
      become: true # < -- all nested tasks amd handlers will be executed as root
      tags: db-tag
      vars:
        mongo_bind_ip: 0.0.0.0 # <-- Variable with default value    
      tasks:
        - name: Change mongo config file      
          template:
            src: templates/mongod.conf.j2 # <-- Path to local template
            dest: /etc/mongod.conf # <-- Path to remote host
            mode: 0644 # <-- Permisssions of file      
          notify: restart mongod    
      handlers:
        - name: restart mongod      
          service: name=mongod state=restarted
    ```

> We have changed *hosts* to **db**, moved *become* and *tags* to upper level of play

##### Play for Reddit app installation
1. Copy variables, tasks, handlers related to Reddit app installation to **reddit_app_multiple_plays.yml**:
  ```
  - name: Download Reddit apllication # < -- Changed description
    hosts: app # < -- Default server group
    become: true # < -- all nested tasks amd handlers will be executed as root
    tags: deploy-tag
    tasks:
      - name: Fetch the latest version of application code
        git:
          repo: 'https://github.com/express42/reddit.git'
          dest: /home/appuser/reddit
          version: monolith # <-- branch      
        notify: reload puma

      - name: Bundle install
        bundler:
          state: present
          chdir: /home/appuser/reddit # <-- working directory of bundler
    handlers:    
      - name: reload puma      
        systemd: name=puma state=reloaded
  ```

> We've changed *tags* to **deploy-tag**, handler's name to **reload puma**

##### Play for Reddit app configuration
1. Copy variables, tasks, handlers related to Reddit app to **reddit_app_multiple_plays.yml**:
    ``` 
    - name: Configure Reddit apllication # < -- Changed description
      hosts: app # < -- Default server group
      become: true # < -- all nested tasks amd handlers will be executed as root
      tags: app-tag
      vars:
        db_internal_ip: IP.ADDRESS.OF.MONGODB
      tasks:
        - name: Add unit file for Puma      
          copy:
            src: files/puma.service
            dest: /etc/systemd/system/puma.service      
          notify: reload puma
          
        - name: Add config for DB connection
          template:
            src: templates/db_config.j2
            dest: /home/appuser/db_config
            owner: appuser
            group: appuser      
            
        - name: enable puma      
          systemd: name=puma enabled=yes      

      handlers:    
        - name: reload puma      
          systemd: name=puma state=restarted
    ```

##### Check and apply changes
1. Execute playbook with tag **db-tag**:
    ```bash
    ansible-playbook reddit_app_multiple_plays.yml --check --tags db-tag
    ```
    ```bash
    ansible-playbook reddit_app_multiple_plays.yml --tags db-tag
    ```

1. Execute playbook with tag **app-tag**:
    ```bash
    ansible-playbook reddit_app_multiple_plays.yml --check --tags app-tag
    ```
    ```bash
    ansible-playbook reddit_app_multiple_plays.yml --tags app-tag
    ```

1. Execute playbook with tag **deploy-tag**:
    ```bash
    ansible-playbook reddit_app_multiple_plays.yml --check --tags deploy-tag
    ```
    ```bash
    ansible-playbook reddit_app_multiple_plays.yml --tags deploy-tag
    ```

### Several playbooks
The content of reddit_app_multiple_plays.yml is pretty complex. We can split it to three playbooks: **app.yml**, **db.yml**, **deploy.yml** and remove tags
1. Create **site.yml** that will contain all three playbooks:
    ```
    ---
    - import_playbook: db.yml
    - import_playbook: app.yml
    - import_playbook: deploy.yml
    ```

1. And apply changes:
    ```bash
    ansible-playbook site.yml --check
    ansible-playbook site.yml
    ```

### Provisioning with Ansible
Using [documentation](https://docs.ansible.com/ansible/latest/list_of_all_modules.html) of modules we can replace provisioners of packer (**app.json**, **db.json**) from shell scripts (*packer/scripts/install_ruby.sh*,*packer/scripts/install_mongodb.sh*) to ansible modules
1. Create file **ansible/packer_app.yml** and use module [apt](https://docs.ansible.com/ansible/latest/modules/apt_module.html#apt-module) to install Ruby and Bundler:
    ```
    ---
    - name: Install Ruby and Packer 
      hosts: app 
      become: true # < -- sudo
      tasks:
        - name: Install Ruby and Bundler
          apt:
            name:
              - ruby-full
              - ruby-bundler
              - build-essential
            update_cache: true  # < -- apt update before install
    ```

1. Create file **ansible/packer_db.yml** and use modules:
   * [apt_key](https://docs.ansible.com/ansible/latest/modules/apt_key_module.html#apt-key-module) to add apt key,
   * [apt_repository](https://docs.ansible.com/ansible/latest/modules/apt_repository_module.html#apt-repository-module) to add apt repository,
   * [apt](https://docs.ansible.com/ansible/latest/modules/apt_module.html#apt-module) to install MongoDB,
   * [systemd](https://docs.ansible.com/ansible/latest/modules/systemd_module.html#systemd-module) to enable autostart  and start the service

 ```
 ---
 - name: Install and Start MongoDB for Reddit app # 
  hosts: db
  become: true # < -- sudo
  tasks:
    - name: Add an apt key
      apt_key:
        keyserver: hkp://keyserver.ubuntu.com:80
        id: D68FA50FEA312927

    - name: Add MongoDB repository into sources list
      apt_repository:
        repo: deb http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.2 multiverse
        state: present

    - name: Install mongodb-org package
      apt:
        name: mongodb-org          
        update_cache: true

    - name: Enable autostart of  MongoDB service
      systemd:
        name: puma
        enabled: true
        state: started        

 ```

1. Replace the provisioner of **packer/app.json** from *shell* to *ansible*:
    ```json
    "provisioners": [
    {
    "type": "ansible",
    "playbook_file": "ansible/packer_app.yml"
    }
    ]
    ```

1. Replace the provisioner of **packer/db.json** from *shell* to *ansible*:
      ```json
      "provisioners": [
      {
      "type": "ansible",
      "playbook_file": "ansible/packer_db.yml"
      }
      ]
      ```

1. Validate and build new images:
    ```bash
    packer validate -var-file=packer/variables.json packer/app.json
    ```
    ```bash
    packer validate -var-file=packer/variables.json packer/db.json
    ```
    ```bash
    packer build -var-file=packer/variables.json packer/app.json
    ```
    ```bash
    packer build -var-file=packer/variables.json packer/db.json
    ```

1. Apply new infrastructure
  ```bash
  cd terraform && terraform destroy && terraform apply
  ```

1. Apply ansible playbook
  ```bash
  ansible-playbook site.yml
  ```

## Homework #10: Ansible roles and environments
### Summary
1. Move playbooks to roles
1. Using community roles
1. Using Ansible Vault for environments
### Challenges
### Steps
#### Ansible roles
Playbooks are not suitable for enterprise solutions - a lot of files, no versioning, too much of hardcoded values. Ansible roles to the rescue - they are allow to group tasks, handlers, files, templates, variable into single and reusable component that can be shared with community ([Ansible galaxy](https://galaxy.ansible.com/))
##### Ansible galaxy
1. Create directory **roles** and initialize structure of new roles:
    ```bash
    ansible-galaxy init app
    ```
    ```bash
    ansible-galaxy init db
    ```

1. Check the structure:
    ```bash
    tree db
    db
    ├── defaults		# directory for default vaules
    │   └── main.yml
    ├── files
    ├── handlers
    │   └── main.yml
    ├── meta		# directory for roles, dependencies, authors
    │   └── main.yml
    ├── README.md
    ├── tasks		# directory for tasks
    │   └── main.yml
    ├── templates
    ├── tests
    │   ├── inventory
    │   └── test.yml
    └── vars			# directory for immutable variables
        └── main.yml
    ```

##### Database role
1. Copy task from **ansible/db.yml** to **ansible/roles/ db/tasks/main.yml**:
    ```yml
    - name: Change mongo config file      
        template:
          src: templates/mongod.conf.j2 # <-- Path to local template
          dest: /etc/mongod.conf # <-- Path to remote host
          mode: 0644 # <-- Permisssions of file      
        notify: restart mongod
    ```

1. Copy the template **ansible/templates/mongod.conf.j2** to **ansible/roles/db/templates/**:
    ```bash
    cp ../templates/mongod.conf.j2 db/templates/

    ```

> modules *template* and *copy* of role will lookup directories **files** and **templates**, so we can change the path to file of **src** parameter:

    ```yml
    ...
      template:
        src: mongod.conf.j2 # <-- Changed path
        dest: /etc/mongod.conf # 
    ...
    ```

1. Copy handler *restart mongod* to **ansible/roles/db/handlers/main.yml**:
    ```yml
    - name: restart mongod
        service: name=mongod state=restarted
    ```

1. Create default variables at **ansible/roles/db/defaults/main.yml**:
    ```yml
    mongo_port: 27017
    mongo_bind_ip: 127.0.0.1
    ```

1. Remove tasks and handlers from **ansible/db.yml** and use role **db**:
    ```yml
    ---
    - name: Configure MongoDB for Reddit app # < -- Changed description
      hosts: db # < -- Default server group
      become: true # < -- all nested tasks amd handlers will be executed as root

      vars:
        mongo_bind_ip: 0.0.0.0 # <-- Variable with default value 
      roles:
        - db
    ```

##### Application role
1. Copy all tasks of **app.yml*** to **app/tasks/main.yml** and adjust all pathes to files and templates
1. Copy unit file **ansible/files/puma.service** to **ansible/roles/app/files/**
```bash
cp ../files/puma.service app/files/
```

1. Copy template **ansible/templates/db_config.j2** to **ansible/roles/app/templates/**
1. Copy handler *restart puma* to **ansible/roles/db/handlers/main.yml**
1. Add default value for variable *db_host* at **ansible/roles/db/defaults/main.yml**:
    ```yml
    # defaults file for app
    db_host: 127.0.0.1
    ```

1. Remove tasks and handlers from **ansible/app.yml** and use role **app**:
    ```yml
    ---
    - name: Configure Reddit apllication
      hosts: app # < -- Default server group
      become: true # < -- all nested tasks amd handlers will be executed as root
      vars:
        db_internal_ip: 10.138.15.202
      roles:
        - app

    ```

##### Check results
```bash
ansible-playbook site.yml --check

```
```bash
ansible-playbook site.yml
```

#### Environments
Ansible allows to define variables for host groups of inventory file by reading files from **group_vars** directory

1. Create 2 directories **environments/stage/group_vars** and **environments/prod/group_vars**:
    ```bash
    mkdir -p environments/stage/group_vars && mkdir -p environments/prod/group_vars
    ```

1. Copy **ansible/inventory** to **environments/stage** and **environments/prod**
1. Create file **stage/group_vars/app** to define variables of group of hosts with name **app** by moving all variables of **ansible/app.yml**:
    ```yml
    db_internal_ip: 10.138.15.202
    ```

1. Create file **stage/group_vars/db** to define variables of group of hosts with name **db** by moving all variables of **ansible/db.yml**:
    ```yml
    db_internal_ip: 10.138.15.202
    ```

1. In addition we can use default group **all** to define variables for all groups (create file  **stage/group_vars/all**):
    ```yml
    env: stage
    ```

1. Copy **group_vars** of **stage** environment to **prod** and change the value of env to **prod**:
    ```yml
    env: prod
    ```

We've created variable **env**. Now it's time to add default value of varible to roles *app* and *db*:
  ```yml
  # content of ansible/roles/app/defaults/main.yml
  # defaults file for app
  db_host: 127.0.0.1
  env: local
  ```
  ```yml
  #content of ansible/roles/db/defaults/main.yml
  # defaults file for db
  mongo_port: 27017
  mongo_bind_ip: 127.0.0.1
  env: local
  ```

1. Add logging task to role *db* and *app* using module **debug** (*roles/db/tasks/main.yml* and *roles/db/tasks/main.yml*):
    ```
    - name: Show info about the env this host belongs to
    debug:
    msg: "This host is in {{ env }} environment!!!"
    ```

1. Move all playbooks to **ansible/playbooks** and update packer provisioners