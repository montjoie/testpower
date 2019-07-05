#!/bin/sh 

apt -q -y install libxml2 libxml2-dev bison flex libcdk5-dev libavahi-client-dev cmake git || exit $?
apt -q -y install lavacli || exit $?
cd acme-utils/pyacmecapture  || exit $?
apt -q -y install python python-libiio python-numpy python-colorama || exit $?
apt -q -y install iputils-ping || exit $?
lava-group >> jobsid || exit $?
#devices number in the group role 
devicesnb=$(wc -l jobsid | awk '{print $1}')
echo "devices number"
echo $devicesnb
for i in `seq 1 $devicesnb`;
do
	JOBID=$(sed -n $i'p' jobsid | awk '{print $1'})
	echo $JOBID	
	devicename=""
	lavacli --uri $LAVA_URI jobs show $JOBID >> dict
	devicename=$(grep 'device ' dict | cut -d: -f2)
	lavacli --uri $LAVA_URI devices dict get $devicename >> file 
	probe_ip=$(grep 'probe_ip' file | awk '{print $6}' | tr -d "'" | tr -d ',')
	if [ -z $probe_ip ] 
	then
		echo "probe_ip unfound"
        	exit 1
	fi
	echo $probe_ip
	probe_channel=$(grep 'probe_channel' file | awk '{print $8}' | tr -d "'}]" | tr -d "'")
	if [ -z $probe_channel ]
	then
		echo "probe_channel unfound"
        	exit 1
	fi
        echo $probe_channel
	
	lava-sync client_ready
	lava-test-case measurement --shell ./pyacmecapture.py --ip $probe_ip -d 50 -s $probe_channel -o test_measurements -od . || exit $?
	cd ../.. || exit $?
	cat uuid
	y=$(cut -d _ -f1 uuid)
	echo "ARTI"
	echo $ARTI
	ls
	file1=$(curl -F "path=@/lava-$y/0/tests/0_server/acme-utils/pyacmecapture/test_measurements_Slot_$probe_channel.csv" http://10.2.3.2:8000/artifacts/output_files/ || exit $?)
	lava-test-reference RAW_DATA --result pass --reference $file1
	file2=$(curl -F "path=@/lava-$y/0/tests/0_server/acme-utils/pyacmecapture/test_measurements-report.txt" $ARTI || exit $?) 
	lava-test-reference ACME_SUMMARY --result pass --reference $file2	  
done
