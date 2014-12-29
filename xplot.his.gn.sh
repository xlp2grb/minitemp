#!/bin/bash

ls *.fin.his >list_his

for FILE in `cat list_his`
do
	FITFILE=$FILE
	OUTPUT_Fwhmbinfre=`echo $FITFILE | sed 's/\.sex.fin.his/.binfrequency.png/'`
#	OUTPUT_Fwhmbinnum=`echo $FITFILE | sed 's/\.sexnew.his/.binnumber.png/'`
#	echo $OUTPUT

#echo "the name of the file is: " $FITFILE
#echo $FITFILE

echo "Name of png picure are : " $OUTPUT_Fwhmbinfre
#echo $OUTPUT_Fwhmbinfre 
#echo $OUTPUT_Fwhmbinnum

gnuplot << EOF

set term png
set output "$OUTPUT_Fwhmbinfre"

set size 1,1
set origin 0,0
set multiplot

set size 0.5,1
set origin 0,0
set title "Fwhm vs. Number"
set xlabel "Fwhm (pixel)"
set ylabel "Number"
set logscale x
set grid
plot [][] "$FITFILE" u 1:2 with lp title ''


set size 0.5,1
set origin 0.5,0
set title "Fwhm vs. Frequency"
set xlabel "Fwhm (pixel)"
set ylabel "frequency"
set logscale x
set grid
plot [][] "$FITFILE" u 1:3 with lp title ''

unset multiplot
reset
quit
EOF

continue
done
