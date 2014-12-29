#!/bin/bash
echo 'usage: sh twoccdplot.sh s.cencc1 n.cencc1 2(number of mount)'
file1=$1
file2=$2
NumberMount=$3
NM=`echo "#"$NumberMount "mount at "$(date +%Y%m%d_)$(date +%H:%M:%S)`
gwac1=`echo $file1 | sed 's/\.cencc1/.coord/'`
gwac2=`echo $file2 | sed 's/\.cencc1/.coord/'`
twoccdplot=`echo "#"$NumberMount"-mount"-$file1"-"$file2".png"`
cat $file1 | head -5  >$gwac1
cat $file1 | head -2 | tail -1 >>$gwac1
cat $file2 | head -5  >$gwac2
cat $file2 | head -2 | tail -1 >>$gwac2
xc1=`cat $file1 | head -1 | awk '{print($1)}'`
yc1=`cat $file1 | head -1 | awk '{print($2)}'`
xc2=`cat $file2 | head -1 | awk '{print($1)}'`
yc2=`cat $file2 | head -1 |  awk '{print($2)}'`
echo $xc1 $yc1 $xc2 $yc2
skycoor  -r $xc1 $yc1 $xc2 $yc2 | awk '{print($1/3600)}'
delta=`skycoor  -r $xc1 $yc1 $xc2 $yc2 | awk '{print($1/3600)}'`
delta1=`skycoor  -r $xc1 0 $xc2 0 | awk '{print($1/3600)}'`
gnuplot <<EOF
set term png
set output "$twoccdplot"
set xlabel "ra deg"
set ylabel "dec deg"
set grid
set key box
set title "$NM"
#set title "#2 mount at 20131203_23:38:14"
set label 1 "$delta deg, $delta1 deg" at $xc1,$yc1
plot '$gwac1' u 1:2 w lp pt 7 ps 1,'$gwac2' u 1:2 w lp pt 6 ps 1
reset
quit
EOF
display $twoccdplot &
rm -rf $gwac1 $gwac2
