#!/bin/sh 

apt -q -y install libxml2 libxml2-dev bison flex libcdk5-dev libavahi-client-dev cmake git || exit $?
apt -q -y install lavacli || exit $?
cd acme-utils/pyacmecapture  || exit $?
apt -q -y install python python-libiio python-numpy python-colorama || exit $?
apt -q -y install iputils-ping || exit $?
lava-group >> jobsid || exit $?
LAVAURI=http://10.2.3.2:10080/RPC2 >> uri
DISPATCHER_IP= $(cut -d: f2 uri | tr -d "//")
devicesnb=$(wc -l jobsid | awk '{print $1}')
echo $devicesnb
for i in `seq 1 $devicesnb`;
do
JOBID=$(sed -n $i'p' jobsid | awk '{print $1'})
echo $JOBID
devicename=""
lavacli --uri $LAVAURI jobs show $JOBID >> dict
devicename=$(grep 'device ' dict | cut -d: -f2)
lavacli --uri $LAVAURI devices dict get $devicename >> file 
probe_ip=$(grep 'probe_ip' file | awk '{print $6}' | tr -d "'" | tr -d ',')
if [ -z $probe_ip ] 
then
	exit
fi
probe_channel=$(grep 'probe_channel' file | awk '{print $8}' | tr -d "'}]" | tr -d "'")
if [ -z $probe_channel ]
then
        exit
fi

lava-send lava_start
./pyacmecapture.py --ip $probe_ip -d 60 -s $probe_channel -o boot_measurements -od .
lava-sync clients
./pyacmecapture.py --ip $probe_ip -d 50 -s $probe_channel -o test_measurements -od .
cd ../..
cat uuid
y=$(cut -d _ -f1 uuid)
file1=$(curl -F "path=@/lava-$y/0/tests/0_server/acme-utils/pyacmecapture/boot_measurements-report.txt" http://$DISPATCHER_IP:8000/artifacts/output_files/ || exit $?)
lava-test-reference file1 --result pass --reference $file1
file2=$(curl -F "path=@/lava-$y/0/tests/0_server/acme-utils/pyacmecapture/test_measurements-report.txt" http://$DISPATCHER_IP:8000/artifacts/output_files/ || exit $?)
lava-test-reference file_2 --result pass --reference $file2
file3=$(curl -F "path=@/lava-$y/0/tests/0_server/acme-utils/pyacmecapture/boot_measurements_Slot_$probe_channel.csv" http://$DISPATCHER_IP:8000/artifacts/output_files/ || exit $?)
lava-test-reference file3 --result pass --reference $file3
file4=$(curl -F "path=@/lava-$y/0/tests/0_server/acme-utils/pyacmecapture/test_measurements_Slot_$probe_channel.csv" http://$DISPATCHER_IP:8000/artifacts/output_files/ || exit $?) 
lava-test-reference file4 --result pass --reference $file4	  
done
