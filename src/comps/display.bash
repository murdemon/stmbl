#! /bin/sh
# Script to bring a network (tap) device for qemu up.
# The idea is to add the tap device to the same bridge
# as we have default routing to.

# in order to be able to find brctl
sudo insmod /lib/modules/6.8.0-31-generic/misc/ms912x.ko


wget https://cloud.mail.ru/public/1cEN/yWijxshfp