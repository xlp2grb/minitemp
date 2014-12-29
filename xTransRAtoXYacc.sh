#!/bin/bash
#$1 is the fit file.
#aim is to check the *.acc file, and then move them to the resultfile 
#20131026
Data_dir=`pwd`
fitfile=$1
cd $HOME
mkdir result
cd result
mkdir bak
cd $Data_dir
result_bak=$HOME/result/bak
prefix=`echo $fitfile | sed 's/\.fit//'`
allfile=`echo $prefix"*"`
cenccfile=`echo $fitfile | sed 's/.fit/.cencc1/'`
RA2XYfile=`echo $fitfile | sed 's/.fit/.acc/'`
ID_MountCamara=`gethead $fitfile "IMAGEID" | cut -c14-17`
cctran_dir=$HOME/tempfile/reddir/
result_dir=$HOME/tempfile/result/
xtranslot2res ( )
{
	if test -r $HOME/result/$ID_MountCamara
	then
		rm -rf $HOME/result/$ID_MountCamara/*.*
		cp  $allfile $HOME/result/$ID_MountCamara
		mv $allfile $result_bak
	else
		cd $HOME/result
		mkdir $ID_MountCamara
		cd $Data_dir
		cp $allfile $HOME/result/$ID_MountCamara
		mv $allfile $result_bak
	fi
}

ra1=`cat $cenccfile | head -1 | awk '{print($1)}'`
dec1=`cat $cenccfile | head -1 | awk '{print($2)}'`
Ra=`skycoor -d $ra1 $dec1 | awk '{printf("%.5f",$1)}'`
Dec=`skycoor -d $ra1 $dec1 | awk '{printf("%.5f",$2)}'`

GP_dir=`echo $result_dir"/"$ID_MountCamara"_"$Ra"_"$Dec`

if test -r $RA2XYfile
then
	xtranslot2res
	wait
else
        lot6c2.py $ID_MountCamara list
	wait
	xtranslot2res
	wait
fi
ipaddressname=`echo "ip_address_"$ID_MountCamara".dat"`
ip=`cat $ipaddressname | awk '{print($1)}'`
term_dir=`cat $ipaddressname | awk '{print($2)}'`

#xautocopy_remote.f  $HOME/result/$ID_MountCamara  $ip  $term_dir
#wait
xautocopy_remote.f $GP_dir $ip  $term_dir
wait
cd $result_dir
xautocopy_remote.f $GP_dir/GPoint_catalog  $ip  $term_dir
wait
sleep 20
cd $data_dir 
echo $HOME/result/$ID_MountCamara  $ip  $term_dir >>logfile
mv $ipaddressname  $HOME/result/$ID_MountCamara
rm -rf list centralCoord
cd $Data_dir
