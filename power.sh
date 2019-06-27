#!/bin/sh 

apt -q -y install libxml2 libxml2-dev bison flex libcdk5-dev libavahi-client-dev cmake git
apt -q -y install lavacli
cd acme-utils/pyacmecapture
apt -q -y install python python-libiio python-numpy python-colorama
apt -q -y install iputils-ping
lava-send lava_start
./pyacmecapture.py --ip 10.65.34.1 -d 60 -s 8 -o boot_measurements -od .
lava-sync clients
./pyacmecapture.py --ip 10.65.34.1 -d 50 -s 8 -o test_measurements -od .
JOBID=$(lava-group target | cut -d' ' -f1)
LAVAURI=http://10.2.3.2:10080/RPC2
lavacli --uri $LAVAURI jobs show $JOBID
file1=$(curl -F "path=@/lava-$JOBID/0/tests/0_server/acme-utils/pyacmecapture/boot_measurements-report.txt" http://10.2.3.2:8000/artifacts/output_files/)
lava-test-reference curl_1 --result pass --reference $file1
file2=$(curl -F "path=@/lava-$JOBID/0/tests/0_server/acme-utils/pyacmecapture/test_measurements-report.txt" http://10.2.3.2:8000/artifacts/output_files/)
lava-test-reference curl_2 --result pass --reference $file2
file3=$(curl -F "path=@/lava-$JOBID/0/tests/0_server/acme-utils/pyacmecapture/boot_measurements_Slot_8.csv" http://10.2.3.2:8000/artifacts/output_files/)
lava-test-reference curl_3 --result pass --reference $file3
file4=$(curl -F "path=@/lava-$JOBID/0/tests/0_server/acme-utils/pyacmecapture/test_measurements_Slot_8.csv" http://10.2.3.2:8000/artifacts/output_files/)
lava-test-reference curl_4 --result pass --reference $file4	  

# TODO get device name

# lavacli devices dict get $devicename
