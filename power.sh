#!/bin/sh

LAVAURI=http://10.2.3.2:10080/RPC2
lava-group

JOBID=$(lava-group | cut -d' ' -f1)
lavacli --uri $LAVAURI jobs show $JOBID

# TODO get device name

# lavacli devices dict get $devicename
