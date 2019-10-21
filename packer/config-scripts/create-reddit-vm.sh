#/bin/bash
gcloud compute instances create reddit-app-from-baked-image --boot-disk-size=10GB --image-family reddit-full --image-project=infra-256019 --machine-type=f1-micro --tags puma-server --restart-on-failure
