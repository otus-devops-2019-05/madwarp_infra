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
