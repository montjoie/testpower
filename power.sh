#!/bin/sh 

apt -q -y install libxml2 libxml2-dev bison flex libcdk5-dev libavahi-client-dev cmake git
apt -q -y install lavacli
cd acme-utils/pyacmecapture
apt -q -y install python python-libiio python-numpy python-colorama
apt -q -y install iputils-ping
lava-group >> jobsid
cat jobsid
LAVAURI=http://10.2.3.2:10080/RPC2
devicesnb=$(wc -l jobsid | awk '{print $1}')
echo $devicesnb
for i in `seq 1 $devicesnb`;
do
JOBID=$(sed -n $i'p' jobsid | awk '{print $1'})
echo $JOBID
devicename=""
lavacli --uri $LAVAURI jobs show $JOBID >> dict
devicename=$(grep 'device ' dict | cut -c15- >> dicti && cat dicti)
lavacli --uri http://10.2.3.2:10080/RPC2 devices dict get $devicename >> file 
probe_ip=$(grep 'probe_ip' file | awk '{print $6}' | tr -d "'" | tr -d ',')
echo $probe_ip
probe_channel=$(grep 'probe_channel' file | awk '{print $8}' | tr -d "'}]" | tr -d "'")
echo $probe_channel
lava-send lava_start
./pyacmecapture.py --ip 10.65.34.1 -d 60 -s 8 -o boot_measurements -od .
lava-sync clients
./pyacmecapture.py --ip 10.65.34.1 -d 50 -s 8 -o test_measurements -od .
cd ../..
cat uuid
y=$(cut -d _ -f1 uuid)
file1=$(curl -F "path=@/lava-$y/0/tests/0_server/acme-utils/pyacmecapture/boot_measurements-report.txt" http://10.2.3.2:8000/artifacts/output_files/)
lava-test-reference file1 --result pass --reference $file1
file2=$(curl -F "path=@/lava-$y/0/tests/0_server/acme-utils/pyacmecapture/test_measurements-report.txt" http://10.2.3.2:8000/artifacts/output_files/)
lava-test-reference file_2 --result pass --reference $file2
file3=$(curl -F "path=@/lava-$y/0/tests/0_server/acme-utils/pyacmecapture/boot_measurements_Slot_$probe_channel.csv" http://10.2.3.2:8000/artifacts/output_files/)
lava-test-reference file3 --result pass --reference $file3
file4=$(curl -F "path=@/lava-$y/0/tests/0_server/acme-utils/pyacmecapture/test_measurements_Slot_$probe_channel.csv" http://10.2.3.2:8000/artifacts/output_files/)
lava-test-reference file4 --result pass --reference $file4	  
done
