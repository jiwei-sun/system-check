#!/bin/bash

name=`whoami`
if [ "$name" = "root" ];then
	./.system-check.sh > report.log
	cat report.log
else
	echo "==============================================="
	echo "	Please run the script as root user"
	echo "==============================================="
fi

