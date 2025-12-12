#!/bin/bash

# Script with some commands needed to correctly setup the VM environment
# add the 'osboxes' user (default user of the VM) to the vboxsf group (VirtualBox shared folder group)
# install some necessary utilities in the background
# wait for it before rebooting the VM to apply the group updates

sudo usermod -aG vboxsf osboxes
sudo apt-get -y install virtualenv curl &
PID=$!
wait $PID

curl -fsSL https://get.docker.com -o get-docker.sh &
PID=$!
wait $PID
sudo sh ./get-docker.sh &
PID=$!
wait $PID
sudo usermod -aG docker osboxes && newgrp docker

sudo reboot
