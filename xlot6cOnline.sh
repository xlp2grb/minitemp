#!/bin/bash
#author: xlp
#aim: to build the temp image and temp catalog automatically.
#input are image and ipfiles in which the ip and terminal direction is set.
#Other softwares and files are needed:
# xautocopy_remote.f      -----to copy the results back automatically.
# xGetCatalog.sh
# list6c
# xcctran_temp.sh
# brightstar_extract_p.py
# template_extract_u.py
# lot6c2.py
# xTransRAtoXYacc.sh

#if [ $# -ne 1  ]
#then
#	echo "usage:   xlot6cOnline.sh 3 [mini-gwac CCD number(1-12)] "
#fi

xsentcatalogerror (  )
{
    xautocopy_remote.f errorimage.flag $ip  $term_dir
    wait
    rm -rf errorimage.flag $fitallfile
    mv GPoint_catalog_old GPoint_catalog
    continue 
    # break
}

xgetcatalog ( )
{
    echo "update the GPoint_catalog"
    #need to add the code to update the catalog immediately, and then copy it to the data reduction node.
    #The premeters in the GPoint_catalog are ra_sky dec_sky ra_mount dec_mount ra_sky_dc_mount ID_Camara
    ra_s=`cat $cenccfile | head -1 | awk '{print($1)}'`
    dec_s=`cat $cenccfile | head -1 | awk '{print($2)}'`
    ra_sky=`skycoor -d $ra_s $dec_s | awk '{printf("%.5f",$1)}'`
    dec_sky=`skycoor -d $ra_s $dec_s | awk '{printf("%.5f",$2)}'`
    sethead -kr X  RaTemp=$ra_sky DecTemp=$dec_sky $newfile
    cp GPoint_catalog GPoint_catalog_old
    echo $ra_sky $dec_sky $ra_mount $dec_mount $ra_sky"_"$dec_sky $ID_MountCamara | grep -v "^_" | awk '{if($3!="_")print($1,$2,$3,$4,$5,$6)}' >>GPoint_catalog 
    #%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%      
    echo "xGetCatalog.sh ------"
    xGetCatalog.sh $cenccfile $dir_reductionCCD  $CCDfile
    wait
    cd $dir_reductionCCD
    if test -s errorimage.flag
    then
        echo "no temp*.txt or bright*.txt "
        xsentcatalogerror
    else
        echo "xTransRAtoXYacc.sh -------"
        xTransRAtoXYacc.sh $newfile
        wait
	rm -rf errorimage.flag $fitallfile
    fi
}


xmakenewtemp (  )
{
    #===================================================
    #echo "To check the image quality"
    #xcheckimgquality
    #wait
    #=====================================================

    accfile=`echo $newfile | sed 's/\.fit/.acc/'`
    cenccfile=`echo $newfile | sed 's/\.fit/.cencc1/'`
    fitallfile=`echo $newfile | sed 's/\.fit/.*/'`
    #delete the RA and DEC keywords
    delhead -o $newfile RA DEC   
    ls $newfile >list
    echo "----------first-----------"
    sleep 1
    lot6c2.py $ID_MountCamara list 
    wait
    if test  -s $cenccfile
    then
        xgetcatalog
    else
        sleep 1
        echo "----------second-----------"
        lot6c2.py $ID_MountCamara list  
        wait
        if test -s $cenccfile
        then
            xgetcatalog
        else
            sleep 1
            echo "----------Third-----------"
            lot6c2.py $ID_MountCamara list  
            wait
            if test -s $cenccfile
            then
                xgetcatalog
            else
                rm -rf $newfile  $fitallfile
                echo "no cenccfile after lot6c2.py " >errorimage.flag
                echo "no cenccfile after lot6c2.py "
                xsentcatalogerror
            fi
        fi
    fi

}

xcheckimgquality ( )
{
    rm -rf image.sex
    sex $newfile  -c  daofind.sex  -CATALOG_NAME image.sex -DETECT_THRESH 5 -ANALYSIS_THRESH 5
    Num_imgquality=`wc -l image.sex | awk '{print($1)}'`
    Num_img1=`cat image.sex | awk '{if($1>200 && $1<600 && $2>200 && $2<600)print($1,$2)}' | wc -l  | awk '{print($1)}'`
    Num_img2=`cat image.sex | awk '{if($1>2400 && $1<2800 && $2>200 && $2<600)print($1,$2)}' | wc -l  | awk '{print($1)}'`
    Num_img3=`cat image.sex | awk '{if($1>200 && $1<600 && $2>2400 && $2<2800)print($1,$2)}' | wc -l  | awk '{print($1)}'`
    Num_img4=`cat image.sex | awk '{if($1>2400 && $1<2800 && $2>2400 && $2<2800)print($1,$2)}' | wc -l  | awk '{print($1)}'`
    Num_img5=`cat image.sex | awk '{if($1>1300 && $1<1700 && $2>1300 && $2<1700)print($1,$2)}' | wc -l  | awk '{print($1)}'`
    echo "The average number should be about 340 for normal image in 400*400 pixels"
    echo "The obj. num. in fields of four corners and center are: "$Num_img1 $Num_img2 $Num_img3 $Num_img4 $Num_img5
    if [ $Num_imgquality -lt 5000 ]
    then
        echo $newfile "is not good for the temp making ! "
        echo $newfile "is not good !" >errorimage.flag
        xautocopy_remote.f  errorimage.flag $ip  $term_dir
        wait
        rm -rf errorimage.flag list image.sex  $newfile $ipaddressname
        continue
    elif  [ $Num_img1 -lt 50 ] || [ $Num_img2 -lt 50 ] || [ $Num_img3 -lt 50 ] || [ $Num_img4 -lt 50 ]
    then
        echo "There are less objects in some corners"
        echo $newfile "is not good !" >errorimage.flag
        xautocopy_remote.f  errorimage.flag $ip  $term_dir
        wait
        rm -rf errorimage.flag list image.sex  $newfile $ipaddressname  $fitallfile
        continue
    else
        :
    fi
}

xRetrack (  )
{
    echo "xRetrack"
    #xcheckimgquality
    ccdid=`gethead $newfile "CCDID"`
    IDccdNum=`echo $newfile | cut -c4-5`
    IDccdNumPair=`echo $IDccdNum | awk '{print($1+1)}'`
    #imhead $newfile
    RA_Template=`gethead -u $newfile "RATEMP"`
    DEC_Template=`gethead -u $newfile "DECTEMP"`
	echo `date`
	echo $newfile
	echo "keywords RaTemp and DecTemp are:  $RA_Template and $DEC_Template "
    if [ "$RA_Template"  == "___"  ] || [  "$DEC_Template" == "___"  ] #for blank keywords
    then
	echo "keywords RaTemp and DecTemp are:  $RA_Template and $DEC_Template "
        echo "keywords of temp RA and DEC are not right, nothing to do!"
	rm -rf $newfile
	continue
    else
	echo "keywords are right"
    fi
    case $ccdid in
        A | C | E | G | I | K )
            CCD_set=South;;
        B | D | F | H | J | L )
            CCD_set=North;;
    esac
    if [ $CCD_set == "North"  ] # south CCD
    then
            rm -rf $newfile
            echo "This is the north CCD, no any track msg are sent"
    else
            echo "South CCD"
	
	    accfile=`echo $newfile | sed 's/\.fit/.acc/'`
	    cenccfile=`echo $newfile | sed 's/\.fit/.cencc1/'`
	    fitallfile=`echo $newfile | sed 's/\.fit/.*/'`
	    #delete the RA and DEC keywords
	    delhead -o $newfile RA DEC
	    ls $newfile >list
	    echo "----------first-----------"
	    sleep 1
	    echo `pwd`
	    echo `echo "lot6c2.py $ID_MountCamara list"`
	    lot6c2.py $ID_MountCamara list
	    wait
	    if test  ! -s $cenccfile
	    then
		echo "No $cenccfile, Astrometry failed ! "
	    else
	        RA_real=`head -1 $cenccfile | awk '{print($1)}'` 
	        DEC_real=`head -1 $cenccfile | awk '{print($2)}'`
		echo "###################### $RA_real $DEC_real $RA_Template $DEC_Template are: "	
		echo $RA_real $DEC_real $RA_Template $DEC_Template
		echo "############################################"
	        echo $RA_real $DEC_real $RA_Template $DEC_Template | awk '{print(($1-$3)*3600,($2-$4)*3600)}' >xtrackres.cat
	        rashiftarcsec=`cat xtrackres.cat | awk '{print($1)}'`
	        decshiftarcsec=`cat xtrackres.cat | awk '{print($2)}'`
	
	        if [ ` echo " $rashiftarcsec > 0 " | bc ` -eq 1 ]
	        then
	            echo "To east: new image relative to temp"
	            RA_guider=-
	        else
	            echo "To west: new image relative to temp"
	            RA_guider=+
	            yshiftG=`echo $rashiftarcsec | awk '{print(-1*$1)}'`
	        fi
	        if [ `echo " $decshiftarcsec > 0"  | bc ` -eq 1 ]
	        then
	            echo "To north: new image relative to temp"
	            DEC_guider=+
	        else
	            echo "To south: new image relative to temp"
	            DEC_guider=-
	            xshiftG=`echo $decshiftarcsec | awk '{print(-1*$1)}'`
	        fi
	        xshiftG_sky=`echo $xshiftG  | awk '{printf("%04d\n",$1)}'` # dec axis no any projection relative to the mount point (DEC)
	        yshiftG_sky=`echo $yshiftG  | awk '{printf("%04d\n",$1)}'` # ra axis 
	        RADECmsg_sky_tmp=`echo "d#"$IDccdNum"bias"$RA_guider$yshiftG_sky$DEC_guider$xshiftG_sky`
	        datestring=`gethead $newfile "date-obs"  | sed 's/-//g' | cut -c3-8`
	        timestring=`gethead $newfile "time-obs"  | sed 's/://g' | cut -c1-6`
	        guidertime=`echo $datestring$timestring | awk '{print($1"%")}'`
	        RADECmsg_sky=`echo $RADECmsg_sky_tmp$guidertime`
	        echo "new image relative to the temp in arcsec: " $RADECmsg_sky
	        echo "Will sent the South CCD msg"
	        echo `date` $RADECmsg_sky >>listmsgforHuang
	        echo $RADECmsg_sky >listmsgforHuang.last.cat
	        #cat listmsgforHuang.last.cat >>$stringtimeForMonitor
	        date
		cp /home/gwac/gwacsoft/xsentshift ./
	        ./xsentshift #sent the shift values to telescope controlers.  
	        # it will sent a fault mas for the North CCD mounted on the same mount.
	        echo "Will sent the Pair North CCD msg, which might be not very precise"
	        RADECmsg_sky_tmp=`echo "d#"$IDccdNumPair"bias"$RA_guider$yshiftG_sky$DEC_guider$xshiftG_sky`	
	        RADECmsg_sky=`echo $RADECmsg_sky_tmp$guidertime`
	        echo `date` $RADECmsg_sky >>listmsgforHuang
	        echo $RADECmsg_sky >listmsgforHuang.last.cat
	        ./xsentshift 
		wait 
		rm -rf  $fitallfile
             fi		

        fi

}

xLimitMagMonitor ( )
{
    echo "xLimitMagMonitor"
    echo "Nothing is done"

}


xmaketemp ( )
{
    echo "xmaketemp"
    #    echo `pwd`
    echo $1
    #        echo $1 >>oldlist
    ID_MountCamara=`gethead "IMAGEID" $newfile | cut -c14-17`
    Iccdtype=`gethead $newfile "CCDTYPE"`
    ra_m=`gethead $newfile "RA" `
    dec_m=`gethead $newfile "DEC" `
    ra_mount=`skycoor -d $ra_m $dec_m | awk '{print($1)}'`
    dec_mount=`skycoor -d $ra_m $dec_m | awk '{print($2)}'`

    ipaddressname=`echo "ip_address_"$ID_MountCamara".dat"`
    ip=`cat $ipaddressname | awk '{print($1)}'`
    term_dir=`cat $ipaddressname | awk '{print($2)}'`
    if [ $Iccdtype != "OBJECT"  ]
    then
        #echo "it is NOT an object file"
        #ipaddressname=`echo "ip_address_"$ID_MountCamara".dat"`
        #ip=`cat $ipaddressname | awk '{print($1)}'`
        #term_dir=`cat $ipaddressname | awk '{print($2)}'`
        echo "CCDTYPE: "$Iccdtype "is not OBJECT" >errorimage.flag
        echo "CCDTYPE: "$Iccdtype "is not OBJECT"
        xautocopy_remote.f  errorimage.flag $ip  $term_dir
        wait
        rm -rf errorimage.flag list $newfile $ipaddressname
        continue
        #break

    else
        echo "it is an object file"
        cp list $newfile $ipaddressname $dir_reductionCCD
        echo $dir_reductionCCD 
        rm -rf list $newfile
        cd $dir_reductionCCD
        rm -rf gototemp.xy gototemp.sex Tempfile.cat 
        
        #====================
        echo "To check the image quality"
        xcheckimgquality
        wait
        #====================

        todokeyword=`gethead $newfile "TODO"`
        Numtodokeyword=`gethead $newfile "TODO" | wc -l | awk '{print($1)}'` 	
        echo "Numtodokeyword : " $Numtodokeyword
        if [ "$todokeyword" = "ReTrack"   ]
        then
            xRetrack
        elif   [ "$todokeyword" = "LimMaking"   ]
        then
            xLimitMagMonitor
        fi
        if [ "$todokeyword" = "tempMaking"   ] || [ $Numtodokeyword = 0  ]
        then
            if test -s GPoint_catalog
            then
                #rm -rf Tempfile.cat
                echo $ra_mount $dec_mount $ID_MountCamara >newIdRADEC.cat
                xCrossGPointImage			
                #/home/gwac/gwacsoft/xCrossGPointImage 
                #output is Tempfile.cat in which rasky decsky ramount decmount rasky_decsky
                if test -s Tempfile.cat
                then
                    #echo `pwd`
                    echo "Have template files for this FOV and this Camera"
                    temp_dir=`cat Tempfile.cat | awk '{print($6"_"$5)}'`
                    #echo $temp_dir
                    #	result_dir=$HOME/tempfile/result
                    GP_dir=`echo $result_dir"/"$temp_dir`
                    #			ipaddressname=`echo "ip_address_"$ID_MountCamara".dat"`
                    #			ip=`cat $ipaddressname | awk '{print($1)}'`
                    #			term_dir=`cat $ipaddressname | awk '{print($2)}'`
                    xautocopy_remote.f $GP_dir $ip  $term_dir
                    wait
                    xautocopy_remote.f $GP_dir/GPoint_catalog  $ip  $term_dir
                    wait
                    rm -rf Tempfile.cat newIdRADEC.cat $newfile
                    continue
                else
                    echo "No template files for this FOV and this Camera"
                    xmakenewtemp
                fi
            else
                touch GPoint_catalog
                xmakenewtemp
            fi
        fi
    fi
}

checkimage ( )
{ 
    if test ! -r oldlist
    then
        touch oldlist
    fi
    diff oldlist newlist | grep  ">" | tr -d '>' | head -1 >list
    line=`cat list | wc -l`
    if  [ "$line" -ne 0 ]
    then 
        newfile=`cat list`
        echo $newfile >>oldlist
        #sleep 5
        xmaketemp $newfile
        #	#	sleep 5
        #		du -a $newfile  >mass
        #	        fitsMass=` cat mass | awk '{print($1)}'`	
        #	        echo "fitsMass =" $fitsMass
        #	#	until [  $fitsMass -gt 18248 ] 
        #	#	do
        #        #                xmaketemp $newfile
        #	#		echo "@@@@@@@@"
        #	#		du -a $newfile  >mass
        #	#		fitsMass=` cat mass | awk '{print($1)}'`
        #	#		echo "fitsMass =" $fitsMass
        #	#	done
        #		if [ "$fitsMass" -gt 18248 ]
        #		#if [ "$fitsMass" -gt 36490 ]
        #		#if [ "$fitsMass" -eq 36496 ]
        #		then 
        #			echo "@@@@@@@@"
        #			sleep 3
        #			xmaketemp $newfile
        #		else	
        #			sleep 5
        #			xmaketemp $newfile
        #		fi
    else
        #break
        continue
    fi
}
xsenterrormsgforSkyCoordcaliToCCDservice (  )
{
    CCDserver_dir=/data2/workspace/redufile/matchfile
    case $mountid in                                                                                                                                                   M1 )
  SouthCCD_IP=190.168.1.11;
  NorthCCD_IP=190.168.1.12;;   
  M2 )
  SouthCCD_IP=190.168.1.13;
  NorthCCD_IP=190.168.1.14;;   
  M3 )
  SouthCCD_IP=190.168.1.15;
  NorthCCD_IP=190.168.1.16;;   
  M4 )
  SouthCCD_IP=190.168.1.17;
  NorthCCD_IP=190.168.1.18;;   
  M5 )
  SouthCCD_IP=190.168.1.19;
  NorthCCD_IP=190.168.1.20;;   
  M6 )
  SouthCCD_IP=190.168.1.21;
  NorthCCD_IP=190.168.1.22;;   
  esac
  if test -r errorSkyCoordCali.flag
  then
        echo "xautocopy_remote.f errorSkyCoordCali.flag $SouthCCD_IP $CCDserver_dir" >> $Monitortimestring
        xautocopy_remote.f errorSkyCoordCali.flag $SouthCCD_IP $CCDserver_dir
        wait
        echo "xautocopy_remote.f errorSkyCoordCali.flag $NorthCCD_IP $CCDserver_dir " >> $Monitortimestring
        xautocopy_remote.f errorSkyCoordCali.flag $NorthCCD_IP $CCDserver_dir
        wait
        rm errorSkyCoordCali.flag
  elif test -r errorSkyCoordCali_no2CCDworking.flag
  then
        echo "xautocopy_remote.f errorSkyCoordCali_no2CCDworking.flag $SouthCCD_IP $CCDserver_dir" >> $Monitortimestring
        xautocopy_remote.f errorSkyCoordCali_no2CCDworking.flag $SouthCCD_IP $CCDserver_dir
        wait
        echo "xautocopy_remote.f errorSkyCoordCali_no2CCDworking.flag $NorthCCD_IP $CCDserver_dir " >> $Monitortimestring
        xautocopy_remote.f errorSkyCoordCali_no2CCDworking.flag $NorthCCD_IP $CCDserver_dir
        wait
        rm errorSkyCoordCali_no2CCDworking.flag
 fi

}

xfindSameMountImageFromDiffCCD (  )
{
    echo "xfindSameMountImageFromDiffCCD" `date` >>$Monitortimestring
    ls *cencc1 >allcencc1.lst
    ls *.cencc1 >>$Monitortimestring
    for mountid in M1 M2 M3 M4 M5 M6;
    do
        cencc1lst=`echo $mountid"_cencc1.lst"`
        Res_cencc1lst=`echo $mountid"_cencc1_RealSkyCoord.txt"`
        cat allcencc1.lst | grep "$mountid" >$cencc1lst
        if test -s $cencc1lst  #the num of files in $cencc1lst is 1 or 2
        then
             echo $cencc1lst >>$Monitortimestring
             NumbImageForSkyCoordCali=`cat $cencc1lst | wc -l | awk '{print($1)}'`
             if [ $NumbImageForSkyCoordCali == 2 ]
             then
                 SouthImage=`head -1 $cencc1lst`
                 NorthImage=`tail -1 $cencc1lst`
		echo "Files in SouthImage are : "
		cat $SouthImage
		echo "Files in Northimage are : "
		cat $NorthImage
                 ra_sky_southImage=`cat $SouthImage | head -1  | awk '{print($1)}'`
                 dec_sky_southImage=`cat $SouthImage | head -1 |  awk '{print($2)}'`
                 ra_sky_NorthImage=`cat $NorthImage | head -1 |  awk '{print($1)}'`
                 dec_sky_NorthImage=`cat $NorthImage | head -1 |  awk '{print($2)}'`
               
		echo $ra_sky_southImage $dec_sky_southImage $ra_sky_NorthImage $dec_sky_NorthImage
                 echo "python minigwac_center_cal.py $ra_sky_southImage $dec_sky_southImage $ra_sky_NorthImage  $dec_sky_NorthImage" >>$Monitortimestring 
                 python minigwac_center_cal.py $ra_sky_southImage $dec_sky_southImage $ra_sky_NorthImage $dec_sky_NorthImage | head -2 | tail -1 |  awk '{print(MM"_RA_"$4"_DEC_"$5"%")}' MM=$mountid >$Res_cencc1lst
                 wait
                 cp $Res_cencc1lst listForSkyCoordCal.cat 
                 cp /home/gwac/gwacsoft/xsentSkyCoorCali ./
                 ./xsentSkyCoorCali  #port is 18852 and ip is 190.168.1.32 
                 wait
                 cat listForSkyCoordCal.cat >>$Monitortimestring
             else  # the number of $mountid cencc1 files is 1 
                 echo "No enough image in $cencc1lst"
                 echo "No enough image in $cencc1lst"  >>Monitortimestring
                 Num_fitsfileSkyC=`ls $mountid"*.fit" | wc -l | awk '{print($1)}'`
                 if [ $Num_fitsfileSkyC == 2 ]  # the number of $mountid fits  is 2 , this means Astrometry is failed
                 then
                     echo "there are 2 fit for $mountid"
                    touch errorSkyCoordCali.flag
                #    xsenterrormsgforSkyCoordcaliToCCDservice
                 else  # the number of $mountid fits is 1, A CCD on this mount might be unworked.
                     echo "there is only 1 fits for $mountid"
                    echo "No enough fits for mount $mountid " >>$Monitortimestring
                    touch errorSkyCoordCali_no2CCDworking.flag
                fi 
                xsenterrormsgforSkyCoordcaliToCCDservice
            fi
        fi
    done
	cd $dirs_source
}

xmkSkycoordCalibration ( )
{
    echo "xmkSkycoordCalibration"
    
    rm -rf $dir_reductionCCD/*
	
    cp *.fit /$dir_reductionCCD
    if test ! -r bakfile
    then
        mkdir bakfile
    fi
    mv *.fit bakfile
    
    cd $dir_reductionCCD
    ls *.fit >list
    ls *.fit >>$Monitortimestring
    echo "=======" >>$Monitortimestring
    head -4 list >list04
    head -8 list | tail -4 >list58
    tail -4 list >list912
    lot6c2.py M1AA list04
    wait
    lot6c2.py M1AA list58
    wait
    lot6c2.py M1AA list912
    wait
    rm list04 list58 list912
    #cp $skyC_code/home/gwac/han/GWAC_tools/minigwac_center_codelist/* $dir_reductionCCD
    cp $skyC_code $dir_reductionCCD
    wait
    Num_cencc=`ls *.cencc1 | wc -l | awk '{print($1)}'`
    if [ $Num_cencc > 0 ]
    then
        xfindSameMountImageFromDiffCCD
    else
        echo "Astrometry is failed" 
        echo "Astrometry is failed" >> $Monitortimestring
    fi
    cd $dir_source
}


xBeginToMakeTemp ( )
{
    cd $dir_source
    if test -r delete.flag
    then
        echo "=====Have delete.flag======"
        echo $dir_source
        tempfilename=`cat delete.flag | awk '{print($1)}'`
        if test -r  $result_dir/$tempfilename
        then
            datetimeForDelete=`date +%Y%m%d%H%M%S`
            newTempFilebak=`echo $tempfilename"."$datetimeForDelete`
            mv $result_dir/$tempfilename $result_dir/$newTempFilebak
        fi
        xccdid=`echo $tempfilename | sed 's/_/ /g' | awk '{print($1)}'`
        xra=`echo $tempfilename | sed 's/_/ /g' | awk '{print($2)}'`
        xdec=`echo $tempfilename | sed 's/_/ /g' | awk '{print($3)}'`
        echo $xra $xdec $xccdid  >newimageCoordForDelete
        cat newimageCoordForDelete
        cp -f newimageCoordForDelete $dir_reductionCCD
        rm -rf newimageCoordForDelete
        cd $dir_reductionCCD	
        echo $dir_reductionCCD
        if test -r GPoint_catalog
        then
            wc GPoint_catalog
            cp GPoint_catalog GPoint_catalog.old
            xcheckskyfieldAndDelete	#input files are newimageCoordForDelete GPoint_catalog, output file is xcheckResultForDelete
            mv xcheckResultForDelete GPoint_catalog
            wc GPoint_catalog
        fi 	
        cd $dir_source
        rm -rf delete.flag oldlist
        touch oldlist
        echo " Have deleted the tempfile "
        continue
    fi	
    #    cd $dir_source
    #echo $dir_source
    if test ! -r  *.fit
    then
        :                
    else
        echo `pwd`
        ls *.fit >newlist
        echo "There is an image in current folder"
        date
        sleep 3
    	if [ "$CCDfile"x == "SkyC"x ]
    	then
            echo "this the the file for SkyC"
            echo `date` >>$Monitortimestring
            echo "Sky coord coordinates " >>$Monitortimestring
    		sleep 120  #waiting for all images from all working CCD for Sky coord calibration
            xmkSkycoordCalibration
    
    	else
            	checkimage
            	wait
    	fi
    fi
}


xmakeSameMountToMakeTemp (  ) 
{
    #to check whether there are some new images in the file of south  CCD on the same mount, to make sure the tempfiles for both CCD on the same mount was made in the short time delay.
    #this makes sure the the Track of the mount in the reduction online. 
    if [ "$CCDfile" = "M1AB" ] 
    then
        dir_source=/home/gwac/newfile/M1AA
        xBeginToMakeTemp
    fi
    if [ "$CCDfile" = "M2AD" ] 
    then
        dir_source=/home/gwac/newfile/M2AC
        xBeginToMakeTemp
    fi
    if [ "$CCDfile" = "M3AF" ] 
    then
        dir_source=/home/gwac/newfile/M3AE
        xBeginToMakeTemp
    fi
    if [ "$CCDfile" = "M4AH" ] 
    then
        dir_source=/home/gwac/newfile/M4AG
        xBeginToMakeTemp
    fi
    if [ "$CCDfile" = "M5AJ" ] 
    then
        dir_source=/home/gwac/newfile/M5AI
        xBeginToMakeTemp
    fi
    if [ "$CCDfile" = "M6AL" ] 
    then
        dir_source=/home/gwac/newfile/M6AK
        xBeginToMakeTemp
    fi
}


echo "Temp making is preparing: "
filelist=$HOME/gwacsoft/list6c
dir_reduction=$HOME/reddir
result_dir=$HOME/tempfile/result
Monitor_dir=/home/gwac/reddir/monitor
skyC_code=/home/gwac/han/GWAC_tools/minigwac_center_codelist/*
#dir_source=`head -$1 $filelist | tail -1`
#cd $dir_source
#CCDfile=`echo $dir_source | cut -c20-24`
#dir_reductionCCD=`echo $dir_reduction/$CCDfile`
#echo "delte the oldlist"
for dir_source in `cat $filelist`
do
    cd $dir_source
    if test -r oldlist
    then
        rm -rf oldlist
        touch oldlist
    else
        touch oldlist
    fi
done
#echo "delete the oldlist, finished!"
#=====================================================
#echo "Process id: $1;	Work dir: $dir_source"
while :
do
    Monitortimestring=`date -u +%y%m%d`
    monitorstring=`echo $Monitor_dir"/tempmaking_"$Monitortimestring`
    #=====================================================
    for dir_source in `cat $filelist`
    do
        #echo $dir_source
        #dir_source=`head -$1 $filelist | tail -1`
        cd $dir_source
        #echo "====Begin====="
        #echo $dir_source
        CCDfile=`echo $dir_source | cut -c20-24`
        #echo $CCDfile
        dir_reductionCCD=`echo $dir_reduction/$CCDfile`			
       # echo $dir_reductionCCD
        #=====================================================
        cd $dir_source
        xBeginToMakeTemp
        xmakeSameMountToMakeTemp
        #echo "=============="

        #			echo $dir_source
        #echo "new process is beginning"
        #		if test ! -r  *.fit
        #		then
        #			:
        #		else

        #			ls *.fit >newlist
        #			echo "There is an image in current folder"
        #			sleep 3
        #		 	checkimage
        #			wait
        #		 	xmakeSameMountToMakeTemp
        #			
        #		fi
        sleep 1
    done
done

