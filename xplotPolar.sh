#!/bin/bash
#aim.cat includes the xc and yc of the circular point by rotating the gwac 
#pall.cat includes the x and y of the polar point in the FOV of the gwac 
#*.polxy1 comes from the lot6c2.py when the mount points to the polar direction
if [ $# -ne 1 ]
then
	echo "usage: plotPolar.sh *.polxy1"
	exit 0
fi

if test ! -r pall.cat
then
	touch pall.cat
fi
cat pall.cat $1 >temp
mv temp pall.cat
cp $1 last
xp=`cat last | awk '{print($1)}'`
yp=`cat last | awk '{print($2)}'`
xc=`cat aim.cat | awk '{print($1)}'`
yc=`cat aim.cat | awk '{print($2)}'`
xc1=`cat aim.cat | awk '{print($1-2)}'`
yc1=`cat aim.cat | awk '{print($2+2)}'`
echo "last-x last-y aim-x aim-y" $xp $yp $xc $yc
echo $xp $yp $xc $yc | awk '{print($1-$3,$2-$4)}' >deltaxy.cat
deltax=`cat deltaxy.cat | awk '{print($1)}'`
deltay=`cat deltaxy.cat | awk '{print($2)}'`
echo  "delta-x delta-y" $deltax,$deltay
gnuplot <<EOF
set term png
set output "PolarAjust.png"
set xlabel "x pixel"
set ylabel "y pixel"
set grid
set key left
set key box
plot 'aim.cat' u 1:2 w p pt 7 ps 4,'pall.cat' u 1:2 w lp pt 6 ps 2, 'last' u 1:2 t 'new' w p pt 11 ps 3 
set output "final.png"
plot 'aim.cat' u 1:2 w p pt 7 ps 4,'last' u 1:2 w p pt 11 ps 3
reset
quit
EOF
display PolarAjust.png &
rm -rf  deltaxy.cat last 
