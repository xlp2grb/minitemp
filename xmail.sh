#!/bin/bash
#author: xlp
#date: 20131116
if [ $# -ne 2  ]
then
	echo "usage: xmail.sh file xl60cm@126.com"
	exit 1
fi
fitfile=$1
terminalEmail=$2
mutt  -s $fitfile -a $fitfile  -e 'set content_type="text/html"' -e 'my_hdr from:'xlp@nao.cas.cn -- $terminalEmail

