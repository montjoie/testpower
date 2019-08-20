#!/bin/sh 

apt -q -y install libxml2 libxml2-dev bison flex libcdk5-dev libavahi-client-dev cmake git curl || exit $?
apt -q -y install lavacli || exit $?
cd acme-utils/pyacmecapture  || exit $?
apt -q -y install python python-libiio python-numpy python-colorama || exit $?
apt -q -y install iputils-ping || exit $?
lava-group >> jobsid || exit $?
#devices number in the group role 
devicesnb=$(wc -l jobsid | awk '{print $1}')
for i in `seq 1 $devicesnb`;
do
	JOBID=$(sed -n $i'p' jobsid | awk '{print $1'}) #recuperate the job id of the target
	echo "DEBUG: $JOBID"
	devicename=""
	lavacli --uri $LAVA_URI jobs show $JOBID >> dict #use lavacli tool to know the devicename
	devicename=$(grep 'device ' dict | cut -d: -f2) #recuperate the device name
	if [ -z "$devicename" ];then
		echo "ERROR: devicename is empty"
		exit 1
	fi
	echo "DEBUG: devicename is $devicename"
	lavacli --uri $LAVA_URI devices dict get $devicename >> file #recuperate the device dict of our board using the devicename
	probe_ip=$(grep 'probe_ip' file | awk '{print $6}' | tr -d "'" | tr -d ',') #recuperate probe ip from device dict
	if [ -z $probe_ip ];then
		echo "probe_ip not found via $LAVA_URI"
        	exit 1
	fi
	echo "DEBUG: probe_ip=$probe_ip"
	probe_channel=$(grep 'probe_channel' file | awk '{print $8}' | tr -d "'}]" | tr -d "'") #recuperate probe channel from device dict
	if [ -z $probe_channel ]
	then
		echo "probe_channel unfound"
        	exit 1
	fi
	echo "DEBUG: probe_channel=$probe_channel"
	lava-sync target_ready # synchronise with the host
	./pyacmecapture.py --ip $probe_ip -s $probe_channel -o test_measurements -od . & pid=$!  || exit $? #begin measurement in background
        lava-sync target_finished # waiting for the target to complete its test section
        kill $pid #stop the measurement
	wait $pid
	cd ../.. || exit $?
	cat uuid
	y=$(cut -d _ -f1 uuid) #recuperate the job id of the host
	echo "DEBUG: jobid: $y"
	cd acme-utils/pyacmecapture || exit $?
	ls -l /lava-$y/0/tests/0_server/acme-utils/pyacmecapture/
	if [ ! -z "$ARTI" ];then
	        ACME_SUMMARY=$(curl -F "path=@/lava-$y/0/tests/0_server/acme-utils/pyacmecapture/test_measurements-report.txt" $ARTI) 
		echo "DEBUG: ACME SUMMARY: $ACME_SUMMARY"
	        lava-test-reference ACME_SUMMARY --result pass --reference $ACME_SUMMARY
	        RAW_DATA=$(curl -F "path=@/lava-$y/0/tests/0_server/acme-utils/pyacmecapture/test_measurements_Slot_$probe_channel.csv" $ARTI)
		echo "DEBUG: RAW_DATA $RAW_DATA"
	        lava-test-reference RAW_DATA --result pass --reference $RAW_DATA
	else
		echo "ERROR: ARTI is empty"
		lava-test-reference ACME_SUMMARY --result fail --reference "empty"
		lava-test-reference RAW_DATA --result fail --reference "empty"
	fi
done
