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
### Challenges
#### Challenge 1
Find the way to establish connection from your machine to **internal** using only single command (without intermediary ssh on **bastion**)
#### Challenge 2
Add alias someinternalhost to simplify connection from client machine
### Steps
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
1. Add *f1-micro* VM instance of region *us-west1* with name **bastion** and two network interfaces: external(with static IP address) and internal
1. Add *f1-micro* VM instance of region *us-west1* with name **internal** and internal network interface only
1. Add your private key (id_rsa) to the authentication agent of ssh with command
```bash
ssh-add ~/.ssh/id_rsa
```
1. Connect to the **bastion** server from your client machine using command (replace *EXTERNAL.ADDRESS.OF.BASTION* by IP address):
```bash
ssh -A user@EXTERNAL.ADDRESS.OF.BASTION
```
1. Connect to the **internal** server from the **bastion** machine using command (replace *IP.ADDRESS.OF.INTERNAL* by IP address):
```bash
ssh IP.ADDRESS.OF.INTERNAL
```

