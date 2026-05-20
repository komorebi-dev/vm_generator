#!/bin/bash

# Script with some commands needed to correctly setup the VM environment:
# - add the 'osboxes' user (default user of the VM)
# to the vboxsf group (VirtualBox shared folder group)
# - install some necessary utilities (background)
# reboot the VM to apply the group changes and other config

sudo usermod -aG vboxsf osboxes
sudo apt-get -y install vim git curl &
PID=$!
wait $PID

sudo reboot
