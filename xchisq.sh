#!/bin/bash
#datafile is a file in which there are two columns, one is the time the other, the other is the magnitude which is used to be fitted
# like this   300 15.6
echo "This script is only for a single powerlaw"
echo "if one fit the light curves with double or more powerlaws"
echo "please use this script one by one" 
echo "alpha[fit] zero[fit]  datafile"
echo "sh xchisq.sh 1.15057 6.68771 magR_chis"
if [ $# -ne 3  ]
then
	echo "alpha[fit] zero[fit]  datafile"
	exit 0
fi
a=$1
b=$2
datafile=$3
#f(x)=2.512*a*log(x)/log(10)+b
ndof=`wc $datafile | awk '{print($1)}'`

rm -rf xfit.dat

for xdata in `cat $datafile | awk '{print($1)}'`
do
	echo $xdata | awk '{print(2.512*aa*log($1)/log(10)+bb)}' aa=$a  bb=$b >>xfit.dat
done

paste xfit.dat  $datafile | column -t >datatemp
cat datatemp | awk '{print(($3-$1)*($3-$1))}' >subtemp

chisq=0
for subdata in `cat subtemp | awk '{print($1)}'`
do
	chisq=`echo $chisq $subdata | awk '{print($1+$2)}'`	
done

echo "chisq2="$chisq   "  with dof="$ndof

