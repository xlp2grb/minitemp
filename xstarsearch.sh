#!/bin/bash
#author : xlp
#date: 20140413
usno_dir=/home/gwac/han/remote_py_v1.1-xinglong
otdata_dir=/home/gwac/otfile
redius_arcsec=30  #about 1 pixel scale
mag_max=1
mag_min=17
cd $otdata_dir
if test ! -r bakfile
then
	mkdir bakfile
fi
while :
do
	rm -rf OT*.txt
	if test ! -r *.radec
	then
		continue
	fi
	date >time1.log
	ls *.radec >list
	sleep 3
	if test -s list
	then
		otradecfile=`cat list | head -1`
	 	mcid=`echo $otradecfile | cut -c1-4`
		echo $otradecfile $mcid
	
		if test ! -r bakfile/"$mcid"
		then
			mkdir bakfile/"$mcid"
		fi
		cd $usno_dir
		python star_search_list_u.py $otdata_dir $otradecfile $redius_arcsec $mag_max $mag_min  
		wait
		cd $otdata_dir
		if test -r OT*.txt
		then
			ipaddressname=`echo "ip_address_"$mcid".dat"`
			ip=`cat $ipaddressname | awk '{print($1)}'`
        	        term_dir=`cat $ipaddressname | awk '{print($2)}'`
			xautocopyot_remote.f OT*.txt $ip  $term_dir
        	        wait
			mv OT*.txt $otradecfile bakfile/"$mcid"
		else
			echo "no OT*.txt is produced"
			echo `date` "no OT*.txt is produced   "  $otradecfile >>error.log
			mv  $otradecfile bakfile/"$mcid"
			date >>time1.log
			cat time1.log
		fi
		
	else
		continue		
	fi
done
