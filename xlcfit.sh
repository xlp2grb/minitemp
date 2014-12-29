#!/bin/bash
#author: xlp at 20130909
#citation is Rhoads et al. 2001, ApJ, 546, 117
#The parameters are mb1,s1,a11,a21,tb1,mb2,s2,a21,a22,tb2

#f(x)=mb+2.5*g(x)/s
#g(x)=log( k(x) )/log(10)-log(2)/log(10)
#k(x)=(x/tb)**(a1*s)+(x/tb)**(a2*s)

echo "usage: xlcfit.sh datafilename"
echo "in the data file, col1 is time, col2 is timeerror, col3 is mag, col4 is merr"
datafile=$1

gnuplot <<EOF
set term png
set output "lcfit.png"
set logscale x
set grid
set xlabel "time sec"
set ylabel "mag"
set title "Light curve and multi-powerlaw fit"

m1(x)=mb1+2.5*g1(x)/s1
g1(x)=log( k1(x) )/log(10)-log(2)/log(10)
k1(x)=(x/tb1)**(a11*s1)+(x/tb1)**(a21*s1)
s1=3
a11=-0.6
a21=2
tb1=1000

m2(x)=mb2+2.5*g2(x)/s2
g2(x)=log( k2(x) )/log(10)-log(2)/log(10)
k2(x)=(x/tb2)**(a12*s2)+(x/tb2)**(a22*s2)
s2=3
a12=-5
a22=1.5
tb2=5000

m1p2(x)=-2.5*log(10**(-0.4*m1(x))+10**(-0.4*m2(x)))/log(10)

fit m1p2(x) '$datafile' u 1:3:4 via mb1,a11,a21,tb1,mb2,a12,a22,tb2

plot [][24:13] '$datafile' u 1:3:2:4 with xyerrorbars  pt 7 ps 2 title 'data', m1(x) w l ls 3 title '', m2(x) w l lt 4 title '' ,m1p2(x) w l ls -1 lw 3 title 'fit'

quit
EOF
display lcfit.png
