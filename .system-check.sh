#!/bin/bash

check_dmesg()
{
	dmesg > ./dmesg
	cat ./dmesg | grep -i -E "fail|error|fatal|warn" > ./check_src.log
#	sed -i 's/^.\{14\}//g' ./check_src.log
	cut -d "]" -f 2- ./check_src.log > ./check_src.tmp
	mv ./check_src.tmp ./check_src.log
	if [ $? -eq 0 ];then
		rm -f ./check.log
		cat ./check_src.log | while read line
		do
			if [ -f "./normal.rec" ];then
				find_out=0
				while read LINE
				do
					if [ "$LINE" = "$line" ];then
						find_out=1
					fi
				done < ./normal.rec

				if [ "$find_out" = "0" ];then
					echo $line >> ./check.log
				fi
			else
				echo $line >> ./check.log
			fi
		done
		if [ -f "./check.log" ]; then
			echo "======================WARNING:fail|error|fatal|warn==============="
			echo "There are some exception information in the dmesg, please double check"
			echo
			cat ./check.log
		fi
	fi

	if [ -f "./exception.rec" ]; then
		while read line
		do
			cat ./demsg | grep $line > /dev/null
			if [ $? -eq 0 ]; then
				echo
				echo
				echo "======================WARNING:exception log==============="
				echo
				cat ./dmesg | grep $line
			fi
		done < ./exception.rec
	fi

	cat ./dmesg | grep -B 5 -A 10 -E  "Call Trace|Oops|panic" > ./check.log
	if [ $? -eq 0 ];then
		echo
		echo
		echo "======================WARNING:Call Trace|Oops|panic==============="
		echo "There are some error logs regarding 'Call Trace|Oops|panic' in the dmesg, please double check"
		echo
		cat ./dmesg | grep -10 -E  "Call Trace|Oops|panic"
	fi
	cat ./dmesg | grep "BUG"
	if [ $? -eq 0 ];then
		echo
		echo
		echo "======================WARNING:Bug=================================="
		echo "There are some BUG log in the dmesg, please double check"
		echo
		cat ./dmesg | grep "BUG"
	fi

	rm -f ./dmesg -f
	rm -f ./check.log -f
	rm -f ./check_src.log -f
}

check_cpu()
{
	processor=`cat /proc/cpuinfo |grep "processor" |wc -l`
	socket=`cat /proc/cpuinfo |grep "physical id"  | tail -n 1|awk -F " " '{print $4}'`
	socket=$(($socket+1))
	echo "Total CPU SOCKET: $socket"
	echo "Total CPU: $processor"
}

check_mem()
{
	cat /proc/meminfo > ./meminfo
	sed -i '2,$d' ./meminfo
	total=`cat ./meminfo | awk -F " " '{print $2}'`
	total=$(($total/1024))
	echo "Total memory: $total MB (It should be little smaller than fact total memory)"
	rm -f ./meminfo
}

check_disk()
{
	fdisk -l |grep -E "Disk /dev/s|Disk /dev/nvme"
	total=`fdisk -l |grep -E "Disk /dev/s|Disk /dev/nvme" |wc -l`
	echo "Total disk: $total"

}

check_cpu_perf()
{
	if [ -f ./vmstat ];then
		cp ./vmstat  ./cpustat
		sed -i '1d' ./cpustat
		cat ./cpustat | awk -F " " '{print $15}' > ./cpustat1
		while read line
		do
			if [ $line -lt 95 ]; then
				echo "Please double check the CPU utilization in idle, it should be not little than 95"
			fi
		done < ./cpustat1
		rm -f ./cpustat ./cpustat1
	fi
	return
}

check_mem_perf()
{
	free -h
}

check_io_perf()
{
	return
}

echo "@@@@@@@@@@@@@@@@@@@@@@@Checking dmesg log@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
check_dmesg

echo
echo
echo
echo
echo
echo "@@@@@@@@@@@@@@@@@@@@@@@Checking information regarding CPU ,memory and Disk@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
check_cpu
check_mem
check_disk
echo

#echo "@@@@@@@@@@@@@@@@@@@@@@@Checking some performance issue regarding CPU, memory and IO when the system is in idle@@@@@@@@@@@@@@@@@@@@@"
#vmstat 1 10 > ./vmstat
#sed -i "1d" ./vmstat
#check_cpu_perf
#check_mem_perf
#check_io_perf
#rm ./vmstat

