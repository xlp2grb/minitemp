#include  <stdio.h>
#include  <math.h>
#include  <stdlib.h>
#include <sys/io.h>
#include <unistd.h>
#include <string.h>
#include <stdbool.h>
main()
{
        int     i,j,k,m,N2,N1,cmp;
        float   rxc1,ryc2,rxc3,ryc4,oxc1,oyc2;
	float   k1,k2;
        float   x1[20000],x2[20000],x3[20000],x4[20000];
	char    x5[20000][50],x6[20000][50],k3[50];
	//char	filename,mountid_c,mountid_new;
	char	filename[100],mountid_c[10],mountid_new[10];
        FILE    *fp1;
        FILE    *fave;
        //char    *refall, *objall;
        char	refall[20],objall[20];

        //sprintf(refall,"GPoint_catalog");
	//sprintf(objall,"newIdRADEC.cat");
	strcpy(refall,"GPoint_catalog");
	strcpy(objall,"newIdRADEC.cat");

        printf("refall = %s\n",refall);
        printf("objall = %s\n",objall);

        i=0;
        j=0;
        m=0;
        fave=fopen("Tempfile.cat","w+");

        fp1=fopen(refall,"r");
        if(fp1)
        {
                while((fscanf(fp1,"%f %f %f %f %s %s \n",&rxc1,&ryc2,&rxc3,&ryc4,filename,mountid_c))!=EOF)
                {
                x1[i]=rxc1;
                x2[i]=ryc2;
                x3[i]=rxc3;
		x4[i]=ryc4;
		sprintf(x5[i],"%s",filename);
		sprintf(x6[i],"%s",mountid_c);
                i++;
                }
                N1=i;
        }
        fclose(fp1);

        fp1=fopen(objall,"r");
        if(fp1)
        {
          fscanf(fp1,"%f %f %s\n",&oxc1,&oyc2,mountid_new);
          {
          k1=oxc1;
          k2=oyc2;
          sprintf(k3,"%s",mountid_new);	
          }
        }
        fclose(fp1);
	
 
       for(i=0;i<N1;i++)
       {
	cmp=strcmp(x6[i],k3);
       		if(cmp==0 && abs(x3[i]-k1)<1 && abs(x4[i]-k2)<1 )
       		{
       			printf("Have template for this FOV\n");		
	       		fprintf(fave,"%f %f %f %f %s %s\n",x1[i],x2[i],x3[i],x4[i],x5[i],x6[i]);
       			break;
       		}
       }
        
        fclose(fave);
}

