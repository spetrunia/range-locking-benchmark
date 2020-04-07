#!/bin/bash

sudo apt-get -y install linux-tools-common
sudo apt-get -y install linux-tools-`uname -r`
sudo sh -c "echo 0 >/proc/sys/kernel/kptr_restrict"

