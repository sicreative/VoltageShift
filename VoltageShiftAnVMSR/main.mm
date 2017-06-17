//
//  main.mm
//
//
//  Created by SC Lee on 12/09/13.
//  Copyright (c) 2017 SC Lee . All rights reserved.
//
//
//  MSR Kext Access modifiyed from AnVMSR by  Andy Vandijck Copyright (C) 2013 AnV Software
//
//   This is licensed under the
//      GNU General Public License v3.0
//
//
//


#import <Foundation/Foundation.h>
#import <sstream>
#import <vector>
#import <string>




#define kAnVMSRClassName "VoltageShiftAnVMSR"


#define MSR_OC_MAILBOX			0x150
#define MSR_OC_MAILBOX_CMD_OFFSET	32
#define MSR_OC_MAILBOX_RSP_OFFSET	32
#define MSR_OC_MAILBOX_DOMAIN_OFFSET	40
#define MSR_OC_MAILBOX_BUSY_BIT		63
#define OC_MAILBOX_READ_VOLTAGE_CMD	0x10
#define OC_MAILBOX_WHITE_VOLTAGE_CMD	0x11
#define OC_MAILBOX_VALUE_OFFSET		20
#define OC_MAILBOX_RETRY_COUNT		5


io_connect_t connect ;
Boolean damagemode = false;

io_service_t service ;

double basefreq = 0;
double maxturbofreq = 0;
double multturbofreq = 0;
double fourthturbofreq = 0;
double power_units = 0;
uint64 dtsmax = 0;
uint64 tempoffset = 0;




enum {
    AnVMSRActionMethodRDMSR = 0,
    AnVMSRActionMethodWRMSR = 1,
    AnVMSRNumMethods
};





typedef struct {
	UInt32 action;
    UInt32 msr;
    UInt64 param;
} inout;

io_service_t getService() {
	io_service_t service = 0;
	mach_port_t masterPort;
	io_iterator_t iter;
	kern_return_t ret;
	io_string_t path;
	
	ret = IOMasterPort(MACH_PORT_NULL, &masterPort);
	if (ret != KERN_SUCCESS) {
		printf("Can't get masterport\n");
		goto failure;
	}
	
	ret = IOServiceGetMatchingServices(masterPort, IOServiceMatching(kAnVMSRClassName), &iter);
	if (ret != KERN_SUCCESS) {
		printf("VoltageShift.kext is not running\n");
		goto failure;
	}
	
	service = IOIteratorNext(iter);
	IOObjectRelease(iter);
	
	ret = IORegistryEntryGetPath(service, kIOServicePlane, path);
	if (ret != KERN_SUCCESS) {
		// printf("Can't get registry-entry path\n");
		goto failure;
	}
	
failure:
	return service;
}

void usage(const char *name)
{
    
    printf("--------------------------------------------------------------------------\n");
    printf("VoltageShift Undervoltage Tool v 0.1 for Intel Haswell / Broadwell \n");
    printf("Copyright (C) 2017 SC Lee \n");
    printf("--------------------------------------------------------------------------\n");

    printf("Usage:\n");
    printf("set voltage:  \n    %s offset <CPU> <GPU> <CPUCache> <SA> <AI/O> <DI/O>\n\n", name);
    printf("set boot and auto apply:\n  sudo %s buildlaunchd <CPU> <GPU> <CPUCache> <SA> <AI/O> <DI/O> <UpdateSecond>\n\n", name);
    printf("remove boot and auto apply:\n    %s removelaunchd \n\n", name);
     printf("get info of current setting:\n    %s info \n\n", name);
    printf("continus monitor of CPU:\n    %s mon \n\n", name);
    printf("read MSR: %s read <HEX_MSR>\n\n", name);
    printf("write MSR: %s write <HEX_MSR> <HEX_VALUE>\n\n", name);
}

unsigned long long hex2int(const char *s)
{
    return strtoull(s,NULL,16);
}

// Read OC Mailbox
// Ref of Intel Turbo Boost Max Technology 3.0 legacy (non HWP) enumeration driver
// https://github.com/torvalds/linux/blob/master/drivers/platform/x86/intel_turbo_max_3.c
//
//
//    offset 0x40 is the OC Mailbox Domain bit relative for:
//
//
//   domain : 0 - CPU
//            1 - GPU
//            2 - CPU Cache
//            3 - System Agency
//            4 - Analogy I/O
//            5 - Digtal I/O
//
//






int writeOCMailBox (int domain,int offset){
    

    
    if (offset > 0 && !damagemode){
        printf("--------------------------------------------------------------------------\n");
        printf("VoltageShift offset Tool\n");
        printf("--------------------------------------------------------------------------\n");
        printf("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n");
        printf("You setting require over-clocked. This May Damaged you Computer !!!! \n");
        printf("use --damaged for override\n");
        printf("     usage: voltageshift --damage offset ... for run\n");
        printf("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n");
        printf("--------------------------------------------------------------------------\n");
        
        return -1;
    }
    
    if (offset < -250  && !damagemode){
        printf("--------------------------------------------------------------------------\n");
        printf("VoltageShift offset Tool\n");
        printf("--------------------------------------------------------------------------\n");
        printf("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n");
        printf("You setting too low. Are you sure you want that values \n");
        printf("use --damaged for override\n");
        printf("     usage: voltageshift --damage offset ... for run\n");
        printf("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n");
        printf("--------------------------------------------------------------------------\n");

        return -1;
    }
    
    if (damagemode){
        printf("--------------------------------------------------------------------------\n");
        printf("VoltageShift offset Tool Damage Mode in Process \n");
        printf("--------------------------------------------------------------------------\n");
        printf("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n");
    }
    
    uint64 offsetvalue;
    
    if (offset < 0){
        offsetvalue = 0x1000 + ((offset) * 2);
    }else{
        offsetvalue = offset * 2;
    }
    
    
    
    uint64 value = offsetvalue << OC_MAILBOX_VALUE_OFFSET;
    
    
    // MSR 0x150 OC Mailbox 0x11 for write of voltage offset values
    uint64 cmd = OC_MAILBOX_WHITE_VOLTAGE_CMD;
    int ret;
    
    inout in;
    inout out;
    size_t outsize = sizeof(out);
    
    /* Issue favored core read command */

    value |= cmd << MSR_OC_MAILBOX_CMD_OFFSET;
     /* Domain for the values set for */
    value |= ((uint64)domain) << MSR_OC_MAILBOX_DOMAIN_OFFSET;
  
    /* Set the busy bit to indicate OS is trying to issue command */
    value |= ((uint64)0x1) << MSR_OC_MAILBOX_BUSY_BIT;
   
    
    
    in.msr = (UInt32)MSR_OC_MAILBOX;
    in.action = AnVMSRActionMethodWRMSR;
    in.param = value;
    
  //  printf("WRMSR %x with value 0x%llx\n", (unsigned int)in.msr, (unsigned long long)in.param);
    
   // return (0);
    
    
    ret = IOConnectCallStructMethod(connect,
                                    AnVMSRActionMethodWRMSR,
                                    &in,
                                    sizeof(in),
                                    &out,
                                    &outsize
                                    );
    
    
    
    
    
    if (ret != KERN_SUCCESS) {
        printf("cpu OC mailbox write failed\n");
        return 0;
    }
    
    return 0;
  
    
}



int readOCMailBox (int domain){
  
    
    // MSR 0x150 OC Mailbox 0x10 for read of voltage offset values
    uint64 value, cmd = OC_MAILBOX_READ_VOLTAGE_CMD;
    int ret, i;
    
    inout in;
    inout out;
    size_t outsize = sizeof(out);
    
    /* Issue favored core read command */
    value = cmd << MSR_OC_MAILBOX_CMD_OFFSET;
    /* Domain for the values set for */
    value |= ((uint64)domain) << MSR_OC_MAILBOX_DOMAIN_OFFSET;
    /* Set the busy bit to indicate OS is trying to issue command */
    value |= ((uint64)0x1) << MSR_OC_MAILBOX_BUSY_BIT;
    
    
    in.msr = (UInt32)MSR_OC_MAILBOX;
    in.action = AnVMSRActionMethodWRMSR;
    in.param = value;
    
    //printf("WRMSR %x with value 0x%llx\n", (unsigned int)in.msr, (unsigned long long)in.param);
    
    
    

    ret = IOConnectCallStructMethod(connect,
                                    AnVMSRActionMethodWRMSR,
                                    &in,
                                    sizeof(in),
                                    &out,
                                    &outsize
                                    );

    

    
  
    if (ret != KERN_SUCCESS) {
        printf("cpu OC mailbox write failed\n");
        return 0;
    }
    
    
    for (i = 0; i < OC_MAILBOX_RETRY_COUNT; ++i) {
        
        in.msr = MSR_OC_MAILBOX;
        in.action = AnVMSRActionMethodRDMSR;
        in.param = 0;
        ret = IOConnectCallStructMethod(connect,
                                        AnVMSRActionMethodRDMSR,
                                        &in,
                                        sizeof(in),
                                        &out,
                                        &outsize
                                        );
        
        if (ret != KERN_SUCCESS)
        {
            printf("Can't read voltage 0xe7 \n");
            
            
        }
        
        

     
        
        if (out.param & (((uint64)0x1) << MSR_OC_MAILBOX_BUSY_BIT)) {
            printf(" OC mailbox still processing\n");
            ret = -EBUSY;
            continue;
        }
        
        if ((out.param >> MSR_OC_MAILBOX_RSP_OFFSET) & 0xff) {
            printf("OC mailbox cmd failed\n");
           
            break;
        }
     
        

        
        
        break;
    }
    
  //  printf("RDMSR %x returns value 0x%llx\n", (unsigned int)in.msr, (unsigned long long)out.param);

    int returnvalue = (int)(out.param >> 20) & 0xFFF;
    if (returnvalue > 2047){
        returnvalue = -(0x1000-returnvalue);
    }
    
    return returnvalue / 2 ;
    
}


int showcpuinfo(){
    
    kern_return_t ret;
    
    inout in;
    inout out;
    size_t outsize = sizeof(out);
    
    double freq = 0;
    double powerpkg = 0;
    double powercore = 0;
    
    
    
    in.action = AnVMSRActionMethodRDMSR;
    in.param = 0;
    
    if (basefreq==0){
    in.msr = 0xce;
    ret = IOConnectCallStructMethod(connect,
                                    AnVMSRActionMethodRDMSR,
                                    &in,
                                    sizeof(in),
                                    &out,
                                    &outsize
                                    );
    
    if (ret != KERN_SUCCESS)
    {
        printf("Can't read  0xce ");
       
        return (1);
        
    }
    
    basefreq = (double)(out.param >> 8 & 0xFF ) * 100;
        
    }
    
    if (power_units == 0){
    in.msr = 0x606;
    in.action = AnVMSRActionMethodRDMSR;
    in.param = 0;
    ret = IOConnectCallStructMethod(connect,
                                    AnVMSRActionMethodRDMSR,
                                    &in,
                                    sizeof(in),
                                    &out,
                                    &outsize
                                    );
    
    if (ret != KERN_SUCCESS)
    {
        printf("Can't read  0x0606 ");
        return (1);

        
    }
    
    
    
   // double power_units = pow(0.5,(double)(out.param &0xf));
    power_units =pow(0.5,(double)((out.param>>8)&0x1f)) * 10;
    }
    
    if (maxturbofreq == 0){
        in.msr = 0x1AD;
        in.action = AnVMSRActionMethodRDMSR;
        in.param = 0;
        ret = IOConnectCallStructMethod(connect,
                                        AnVMSRActionMethodRDMSR,
                                        &in,
                                        sizeof(in),
                                        &out,
                                        &outsize
                                        );
        
        if (ret != KERN_SUCCESS)
        {
            printf("Can't read  0x01AD ");
            return (1);
            
        }
        
        
        
        // double power_units = pow(0.5,(double)(out.param &0xf));
          maxturbofreq =(double)(out.param & 0xff) * 100.0;
        multturbofreq =(double)(out.param>>8 & 0xff) * 100.0;
        fourthturbofreq =(double)(out.param>>24 &0xff) * 100.0;
        printf("CPU BaseFreq: %.0f, CPU MaxFreq(1/2/4): %.0f/%.0f/%.0f (mhz) \n",basefreq ,maxturbofreq,multturbofreq,fourthturbofreq);
    }
    
    
    
    
    
    
    
    do {
        
        
        in.msr = 0x611;
        in.action = AnVMSRActionMethodRDMSR;
        in.param = 0;
        ret = IOConnectCallStructMethod(connect,
                                        AnVMSRActionMethodRDMSR,
                                        &in,
                                        sizeof(in),
                                        &out,
                                        &outsize
                                        );
        
        if (ret != KERN_SUCCESS)
        {
            printf("Can't read  0x611 ");
            return (1);

            
        }
        
        
        
        
        
        unsigned long long lastpowerpkg = out.param;
        
        in.msr = 0x639;
        in.action = AnVMSRActionMethodRDMSR;
        in.param = 0;
        ret = IOConnectCallStructMethod(connect,
                                        AnVMSRActionMethodRDMSR,
                                        &in,
                                        sizeof(in),
                                        &out,
                                        &outsize
                                        );
        
        if (ret != KERN_SUCCESS)
        {
            printf("Can't read  0x639 ");
            return (1);

            
        }
        
        
        
        
        
        unsigned long long lastpowercore = out.param;
        

        
        
        
        in.msr = 0xe7;
        in.action = AnVMSRActionMethodRDMSR;
        in.param = 0;
        ret = IOConnectCallStructMethod(connect,
                                        AnVMSRActionMethodRDMSR,
                                        &in,
                                        sizeof(in),
                                        &out,
                                        &outsize
                                        );
        
        if (ret != KERN_SUCCESS)
        {
            printf("Can't read  0xe7 ");
            return (1);

            
        }
        
        unsigned long long le7 = out.param;
        //   printf("RDMSR %x returns value 0x%llx\n", (unsigned int)in.msr, le7);
        
        in.msr = 0xe8;
        
        ret = IOConnectCallStructMethod(connect,
                                        AnVMSRActionMethodRDMSR,
                                        &in,
                                        sizeof(in),
                                        &out,
                                        &outsize
                                        );
        
        if (ret != KERN_SUCCESS)
        {
            printf("Can't read 0xe8 ");
            return (1);

            
        }
        unsigned long long le8 = out.param;
        
   
        
        uint64 firsttime = clock_gettime_nsec_np(CLOCK_REALTIME);
        
        
        
        
        usleep(100000);
        
        
        
        in.msr = 0xe7;
        in.action = AnVMSRActionMethodRDMSR;
        in.param = 0;
        ret = IOConnectCallStructMethod(connect,
                                        AnVMSRActionMethodRDMSR,
                                        &in,
                                        sizeof(in),
                                        &out,
                                        &outsize
                                        );
        
        if (ret != KERN_SUCCESS)
        {
            printf("Can't read  0xe7 ");
            return (1);

            
        }
        
        
        unsigned long long e7 = out.param;
        
        
        
        
        in.msr = 0xe8;
        
        ret = IOConnectCallStructMethod(connect,
                                        AnVMSRActionMethodRDMSR,
                                        &in,
                                        sizeof(in),
                                        &out,
                                        &outsize
                                        );
        
        if (ret != KERN_SUCCESS)
        {
            printf("Can't read 0xe8 ");
            
            return (1);

        }
        unsigned long long e8 = out.param;
        
        
        
        
        
        
          uint64 secondtime = clock_gettime_nsec_np(CLOCK_REALTIME);
        
        secondtime -= firsttime;
        double second = (double)secondtime / 100000000;
        
        freq =   basefreq  / second * (  ((double)e8-le8)/((double)e7-le7));
        
        //    printf("RDMSR %x volt %f\n", (unsigned int)in.msr, basefreq);
        
        
        
        in.msr = 0x611;
        in.action = AnVMSRActionMethodRDMSR;
        in.param = 0;
        ret = IOConnectCallStructMethod(connect,
                                        AnVMSRActionMethodRDMSR,
                                        &in,
                                        sizeof(in),
                                        &out,
                                        &outsize
                                        );
        
        if (ret != KERN_SUCCESS)
        {
            printf("Can't read power 0x611 ");
            
            return (1);

        }
        
         powerpkg = power_units * ((double)out.param - lastpowerpkg) / second;
        
        
        in.msr = 0x639;
        in.action = AnVMSRActionMethodRDMSR;
        in.param = 0;
        ret = IOConnectCallStructMethod(connect,
                                        AnVMSRActionMethodRDMSR,
                                        &in,
                                        sizeof(in),
                                        &out,
                                        &outsize
                                        );
        
        if (ret != KERN_SUCCESS)
        {
            printf("Can't read  0x639 ");
            return (1);

            
        }
        
        
        
        
        powercore =  power_units * ((double)out.param - lastpowercore) / second;

        
        
        
        
        
        
        
    }while( freq < 200.0 || freq > (maxturbofreq + 100));
    
    
    
  
    
    
    
    
    in.msr = 0x198;
    
    ret = IOConnectCallStructMethod(connect,
                                    AnVMSRActionMethodRDMSR,
                                    &in,
                                    sizeof(in),
                                    &out,
                                    &outsize
                                    );
    
    if (ret != KERN_SUCCESS)
    {
        printf("Can't read voltage 0x198\n");
        return (1);

        
    }
    
    

    
    
    double voltage  = out.param >> 32 & 0xFFFF;
    voltage /= pow(2,13);
    
    if (dtsmax==0){
    
    in.msr = 0x1A2;
    
    
    ret = IOConnectCallStructMethod(connect,
                                    AnVMSRActionMethodRDMSR,
                                    &in,
                                    sizeof(in),
                                    &out,
                                    &outsize
                                    );
    
    if (ret != KERN_SUCCESS)
    {
        printf("Can't read voltage 0x1A2 \n");
        
        return (1);

    }
    

     dtsmax = out.param >> 16 & 0xFF;
     
    tempoffset = out.param >> 24 & 0x3F;
    }
    
    in.msr = 0x19C;
    
    
    ret = IOConnectCallStructMethod(connect,
                                    AnVMSRActionMethodRDMSR,
                                    &in,
                                    sizeof(in),
                                    &out,
                                    &outsize
                                    );
    
    if (ret != KERN_SUCCESS)
    {
        printf("Can't read voltage 0x19C \n");
        
        return (1);
    }
    
        uint64 margintothrottle = out.param >> 16 & 0x3F;
    
    
    

    
    
    
    
    
    
    

    

    
    uint64 temp = dtsmax - tempoffset - margintothrottle;
    
    
    
    printf("CPU Freq: %.2fmhz, Voltage: %.4fv, Power:pkg %.2fw /core %.2fw,Temp: %llu c", freq,voltage,powerpkg,powercore,temp);
    

    return (0);
    

    
    
    
}



int setoffsetdaemons(int argc,const char * argv[]){
    
   
    
    
  
    
        
    for (int i=0;i<argc-2;i++){

        int offset = (int)strtol((char *)argv[i+2],NULL,10);
        if (readOCMailBox(i)!=offset){
             writeOCMailBox(i, offset);
        }
    
    }
  
    
    return(0);
    
    
}





int setoffset(int argc,const char * argv[]){
    
    long cpu_offset = 0;
    long gpu_offset = 0;
    long cpuccache_offset = 0;
    long systemagency_offset = 0;
    long analogy_offset = 0;
    long digitalio_offset = 0;
    
    
    if (argc >= 3)
    {
        
    
        
        cpu_offset = strtol((char *)argv[2],NULL,10);
        if (argc >=4)
            gpu_offset = strtol((char *)argv[3],NULL,10);
        if (argc >=5)
            cpuccache_offset = strtol((char *)argv[4],NULL,10);
        if (argc >=6)
            systemagency_offset = strtol((char *)argv[5],NULL,10);
        if (argc >=7)
            analogy_offset = strtol((char *)argv[6],NULL,10);
        if (argc >=8)
            digitalio_offset = strtol((char *)argv[7],NULL,10);
        
        
    } else {
        usage(argv[0]);
        
        return(1);
    }
    
    
  
    printf("--------------------------------------------------------------------------\n");
    printf("VoltageShift offset Tool\n");
    printf("--------------------------------------------------------------------------\n");

    
    
    if (argc >= 3)
        printf("Before CPU voltageoffset: %dmv\n",readOCMailBox(0));
    if (argc >= 4)
        printf("Before GPU voltageoffset: %dmv\n",readOCMailBox(1));
    if (argc >= 5)
        printf("Before CPU Cache: %dmv\n",readOCMailBox(2));
    if (argc >= 6)
        printf("Before System Agency: %dmv\n",readOCMailBox(3));
    if (argc >= 7)
        printf("Before Analogy I/O: %dmv\n",readOCMailBox(4));
    if (argc >= 8)
        printf("Before Digital I/O: %dmv\n",readOCMailBox(5));
     printf("--------------------------------------------------------------------------\n");
                            
                            
                            
    
    if (argc >= 3)
            writeOCMailBox(0, (int)cpu_offset);
    if (argc >= 4)
            writeOCMailBox(1, (int)gpu_offset);
    if (argc >= 5)
        writeOCMailBox(2, (int)cpuccache_offset);
    if (argc >= 6)
        writeOCMailBox(3, (int)systemagency_offset);
    
    if (argc >= 7)
        writeOCMailBox(4,(int) analogy_offset);
    if (argc >= 8)
        writeOCMailBox(5, (int)digitalio_offset);
    
    if (argc >= 3)
        printf("After CPU voltageoffset: %dmv\n",readOCMailBox(0));
    if (argc >= 4)
        printf("After GPU voltageoffset: %dmv\n",readOCMailBox(1));
    if (argc >= 5)
        printf("After CPU Cache: %dmv\n",readOCMailBox(2));
    if (argc >= 6)
        printf("After System Agency: %dmv\n",readOCMailBox(3));
    if (argc >= 7)
        printf("After Analogy I/O: %dmv\n",readOCMailBox(4));
    if (argc >= 8)
        printf("After Digital I/O: %dmv\n",readOCMailBox(5));
     printf("--------------------------------------------------------------------------\n");
    
    
    
    
    
            return(0);
    
    
}


void unloadkext() {
    
 
    
  
    
    
    if(connect)
    {
       kern_return_t ret = IOServiceClose(connect);
        if (ret != KERN_SUCCESS)
        {
          
        }
    }
    
    if(service)
        IOObjectRelease(service);
    


    
    std::stringstream output;
    output << "sudo kextunload -q -b "
      << "com.sicreative.VoltageShift"
    << " " ;
    
    system(output.str().c_str());

}

void loadkext() {
    
    std::stringstream output;
    output << "sudo kextutil -q -r ./  -b "
    << "com.sicreative.VoltageShift"
    << " " ;

    system(output.str().c_str());
    
    output.str("");
    
    output << "sudo kextutil -q -r /Library/Application\\ Support/VoltageShift/ -b "
    << "com.sicreative.VoltageShift"
    << " " ;
    
    system(output.str().c_str());
    
    
}

void removeLaunchDaemons(){
    std::stringstream output;
    
    output.str("sudo rm /Library/LaunchDaemons/com.sicreative.VoltageShift.plist ");
    system(output.str().c_str());
    
    output.str("sudo rm -R /Library/Application\\ Support/VoltageShift/ ");
    system(output.str().c_str());
    
    // Check process of build sucessful
    int error  = 0;
    
    FILE *fp = popen("sudo ls /Library/LaunchDaemons/com.sicreative.VoltageShift.plist","r");
    
    if (fp != NULL)
    {
        char str [255] ;
       
        
        while (fgets(str, 255, fp) != NULL){
            printf("%s", str);
            if (strstr(str,"/Library/LaunchDaemons/com.sicreative.VoltageShift.plist")!=NULL) {
                error ++;
            }
        }
        
        
        
        
        
        pclose(fp);
    }
    
    
    fp = popen("sudo ls /Library/Application\\ Support/VoltageShift/","r");
    if (fp != NULL)
    {
        char str [255] ;
        
        
        while (fgets(str, 255, fp) != NULL){
            
            printf("%s", str);
            
            if (strstr(str,"VoltageShift.kext")!=NULL) {
                error ++;
                continue;
            }
            
            if (strstr(str,"voltageshift")!=NULL) {
                error ++;
            }
            
        }
     //   printf("%s", str);
        
        
        
        pclose(fp);
    }
    
    // error message
    
    if (error != 0){
        printf("\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n");
        printf("--------------------------------------------------------------------------\n");
        printf("VoltageShift remove Launchd daemons Tool\n");
        printf("--------------------------------------------------------------------------\n");
        printf("    Can't Remove the launchd.  No Sucessful of delete the files,\n\n");

       
               
        printf("or manual delete by:\n");
        
        printf("      sudo rm /Library/LaunchDaemons/com.sicreative.VoltageShift.plist\n ");
        printf("      sudo rm -R /Library/Application\\ Support/VoltageShift \n");

        printf("--------------------------------------------------------------------------\n");
        printf("--------------------------------------------------------------------------\n");
        
        
        return ;
    }
    
    printf("\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n");
    printf("--------------------------------------------------------------------------\n");
    printf("VoltageShift remove Launchd daemons Tool\n");
    printf("--------------------------------------------------------------------------\n");
    printf("    Sucessed Full remove the Launchd daemons\n");
    printf("    Fully Switch off (no reboot) for the system back to \n        non-undervoltage status\n");
    printf("--------------------------------------------------------------------------\n");
    printf("Don't forget enable the CSR protect by following methond:\n");
    printf("1. Boot start by Command-R to recovery mode :\n");
    printf("2. In \"Terminal\" >> csrutil enable  \n");
    printf("--------------------------------------------------------------------------\n");
    printf("--------------------------------------------------------------------------\n");
    

    
    
    


}

void writeLaunchDaemons(std::vector<int>  values = {0},int second = 9000  ) {
    std::stringstream output;
    

    printf("Build for LaunchDaemons of Auto Apply for VoltageShift\n");
    printf("------------------------------------\n");
   
    
   

    
     output.str("sudo rm /Library/LaunchDaemons/com.sicreative.VoltageShift.plist");
     system(output.str().c_str());
    
     output.str("");
    
    //add 0 for no user input field
    for (int i=(int)values.size();i<=6;i++){
        values.push_back(0);
    }
    
    
   output << "sudo echo \""
   << "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
   << "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">"
   <<  "<plist version=\"1.0\">"
   << "<dict>"
    << "<key>RunAtLoad</key><true/>"
   << "<key>Label</key>"
   << "<string>com.sicreative.VoltageShift</string>"
   << "<key>ProgramArguments</key>"
   << "<array>"
   << "<string>/Library/Application Support/VoltageShift/voltageshift</string>"
   << "<string>offsetdaemons</string>";
   
    for (int i=0;i<values.size();i++){
       output << "<string>"
       << values[i]
       << "</string>";
    }
      
   output << "</array>"
   << "<key>StartInterval</key>"
   << "<integer>"
   << second
   << "</integer>"
   << "</dict>"
   << "</plist>"
    << "\" > /Library/LaunchDaemons/com.sicreative.VoltageShift.plist"
    << " ";
    system(output.str().c_str());
    
    output.str("sudo chown  root:wheel /Library/LaunchDaemons/com.sicreative.VoltageShift.plist ");
    
     system(output.str().c_str());
 output.str("sudo mkdir  /Library/Application\\ Support/VoltageShift/ ");
    system(output.str().c_str());
    
      output.str("sudo cp  -R ./VoltageShift.kext /Library/Application\\ Support/VoltageShift/ ");
    system(output.str().c_str());
       output.str("sudo cp  ./voltageshift /Library/Application\\ Support/VoltageShift/ ");
    system(output.str().c_str());
      output.str("sudo chown  -R root:wheel /Library/Application\\ Support/VoltageShift/VoltageShift.kext ");
    system(output.str().c_str());
      output.str("sudo chown  root:wheel /Library/Application\\ Support/VoltageShift/voltageshift ");
    system(output.str().c_str());
    
    
    
    // Check process of build sucessful
    int error  = 3;
    
    FILE *fp = popen("sudo ls /Library/LaunchDaemons/com.sicreative.VoltageShift.plist","r");

    if (fp != NULL)
    {
        char str [255] ;
        
        
        while (fgets(str, 255, fp) != NULL){
            printf("%s", str);
            if (strstr(str,"/Library/LaunchDaemons/com.sicreative.VoltageShift.plist")!=NULL) {
                error --;
            }
        }
        
      
        
      
        
        pclose(fp);
    }
    
    
    fp = popen("sudo ls /Library/Application\\ Support/VoltageShift/","r");
    if (fp != NULL)
    {
        char str [255] ;
       
        
        while (fgets(str, 255, fp) != NULL){
         
            printf("%s", str);
            
            if (strstr(str,"VoltageShift.kext")!=NULL) {
                error --;
                continue;
            }
            
            if (strstr(str,"voltageshift")!=NULL) {
                error --;
            }

        }
          //  printf("%s", str);
        
        
        
        pclose(fp);
    }

// error message
    
    if (error != 0){
        printf("\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n");
        printf("--------------------------------------------------------------------------\n");
        printf("VoltageShift builddaemons Tool\n");
        printf("--------------------------------------------------------------------------\n");
        printf("    Can't build the launchd.  No Sucessful of creat the files, please use:\n\n");
                                                                                   
        printf("             sudo ./voltageshift buildlaunchd .... \n\n");
        printf("for Root privilege.\n");
        printf("--------------------------------------------------------------------------\n");
        printf("--------------------------------------------------------------------------\n");
     
        
        return ;
    }

    
    
    
//Sucess and Caution message
    
    printf("\n\n\n\n\n");
    printf("--------------------------------------------------------------------------\n");
    printf("VoltageShift builddaemons Tool\n");
    printf("--------------------------------------------------------------------------\n");

    printf("Finished install the LaunchDaemons, Please Reboot\n\n");
    printf("--------------------------------------------------------------------------\n");
    
    printf("The system will apply below undervoltage setting \n value for boot and Amend every %d mins\n", second/60);

   printf("--------------------------------------------------------------------------\n");
     printf("************************************************************************\n");
    printf("Please CONFIRM and TEST the system STABLE in below setting, \n otherwise REMOVE this launchd IMMEDIATELY \n");
    printf("You can remove this by use: ./voltageshift removelaunchd\n ");
    printf("Or manual remove by:\n");
    printf("sudo rm /Library/LaunchDaemons/com.sicreative.VoltageShift.plist\n ");
    printf("sudo rm -R /Library/Application\\ Support/VoltageShift \n");

    printf("--------------------------------------------------------------------------\n");
    printf("CPU             %d %s mv\n",values[0],values[0]>0?"!!!!!":"");
    printf("GPU             %d %s mv\n",values[1],values[1]>0?"!!!!!":"");
    printf("CPU Cache       %d %s mv\n",values[2],values[2]>0?"!!!!!":"");
    printf("System Agency   %d %s mv\n",values[3],values[3]>0?"!!!!!":"");
    printf("Analog IO       %d %s mv\n",values[4],values[4]>0?"!!!!!":"");
    printf("Digital IO       %d %s mv\n",values[5],values[5]>0?"!!!!!":"");
    printf("--------------------------------------------------------------------------\n");
    printf("************************************************************************\n");

    printf("Please notice if you cannot boot the system after installed, you need for:\n");
    printf("1. Fully Switch off Computer (not reboot):\n");
    printf("2. Boot start by Command-R to recovery mode :\n");
    printf("3. In \"Terminal\" Enable the CSR protect for stop undervoltage run when boot \n");
    printf("4.       csrutil enable    \n");
    printf("5. Reboot and Remove all file by above method\n");
    printf("--------------------------------------------------------------------------\n");

    
    

    
    
   // output.str("sudo cp ./test.plist /Library/LaunchDaemons ");
    
   //     system(output.str().c_str());
    
}

void intHandler(int sig)
{
    char  c;
    
       signal(sig, SIG_IGN);
     printf("\n quit? [y/n] ");
    c = getchar();
    if (c == 'y' || c == 'Y'){
        
            unloadkext();
        
        exit(0);
    }
    else
        signal(SIGINT, intHandler);
    getchar(); // Get new line character
}


int main(int argc, const char * argv[])
{
    char * parameter;
    char * msr;
    char * regvalue;
    service = getService();
 
    
    if (argc >= 2)
    {
        parameter = (char *)argv[1];
        
    } else {
        usage(argv[0]);
        
        return(1);
    }
    
    int count = 0;
    while (!service && strncmp(parameter, "loadkext", 8) && strncmp(parameter, "unloadkext", 10) ){
        loadkext();

        service = getService();
        
        count++;
        
        // Try load 10 times, otherwise error return
        if (count > 10)
            return (1);
    }
		
    
	kern_return_t ret;
	//io_connect_t connect = 0;
	ret = IOServiceOpen(service, mach_task_self(), 0, &connect);
	if (ret != KERN_SUCCESS)
    {
        printf("Couldn't open IO Service\n");
    }

    
    


    if (argc >= 3)
    {
        msr = (char *)argv[2];
    }
    
    if (!strncmp(parameter, "info", 4)){
        printf("------------------------------------------------------\n");
        printf("   VoltageShift Info Tool\n");
        printf("------------------------------------------------------\n");
        printf("CPU voltage offset: %dmv\n",readOCMailBox(0));
        printf("GPU voltage offset: %dmv\n",readOCMailBox(1));
        printf("CPU Cache voltage offset: %dmv\n",readOCMailBox(2));
        printf("System Agency offset: %dmv\n",readOCMailBox(3));
        printf("Analogy I/O: %dmv\n",readOCMailBox(4));
        printf("Digital I/O: %dmv\n",readOCMailBox(5));
        showcpuinfo();
           printf("\n");

        
    }else if (!strncmp(parameter, "mon", 3)){
        printf("------------------------------------------------------\n");
       printf("   VoltageShift Monitor Tool\n");
        printf("------------------------------------------------------\n");
        printf("    Ctl-C for Exit\n\n");
             signal(SIGINT, intHandler);
            printf("   CPU voltage offset: %dmv\n",readOCMailBox(0));
            printf("   GPU voltage offset: %dmv\n",readOCMailBox(1));
            printf("   CPU Cache voltage offset: %dmv\n",readOCMailBox(2));
            printf("   System Agency offset: %dmv\n",readOCMailBox(3));
            printf("   Analogy I/O: %dmv\n",readOCMailBox(4));
            printf("   Digital I/O: %dmv\n\n",readOCMailBox(5));
            
            //   domain : 0 - CPU
            //            1 - GPU
            //            2 - CPU Cache
            //            3 - System Agency
            //            4 - Analogy I/O
            //            5 - Digtal I/O
            
            do{
                
                
                
                if (showcpuinfo() > 0){
                     fflush(stdout);
                    printf("\r");
                     sleep(1);
                    
           
                //    printf("\r");
                 
                    
                   
                  
                   
                    
                  
                    
                    for (int i=0;i<5;i++){
                    
                    sleep(1);
                        loadkext();
                        service = getService();
                    kern_return_t ret;
                    //io_connect_t connect = 0;
                    ret = IOServiceOpen(service, mach_task_self(), 0, &connect);
                    if (ret != KERN_SUCCESS)
                    {
                        printf("Couldn't open IO Service\n");
                       if (i==4)
                           return (1);
                    }else{
                    
                        break;
                    }
                   }

                    
                }
                
                sleep(1);
                
               
                
                
                 fflush(stdout);
               
                 printf("\r");
              // printf("\r");
            }while (true);
        
        }else if (!strncmp(parameter, "--damage", 8)){
           
            if (argc >=2){
                if (!strncmp((char *)argv[2], "offset", 6)){
                    damagemode = true;
                    
             
                    std::vector<std::string> arg;
                    
                
                    arg.push_back(argv[0]);
                    
         
                    
                    
                    for (int i=1; i<argc-1;i++){
                        arg.push_back(argv[i+1]);
            
                    }
                    
           
                    
                    const char **arrayOfCstrings = new const char*[arg.size()];
                    
                    for (int i = 0; i < arg.size(); ++i)
                        arrayOfCstrings[i] = arg[i].c_str();
                    
                  
                
                   
                    
                    setoffset(argc-1,arrayOfCstrings);

                }else if (!strncmp((char *)argv[2], "offsetdaemons", 6)){
                    
                    damagemode = true;
                    
                    
                    std::vector<std::string> arg;
                    
                    
                    arg.push_back(argv[0]);
                    
                    
                    
                    
                    for (int i=1; i<argc-1;i++){
                        arg.push_back(argv[i+1]);
                        
                    }
                    
                    
                    
                    const char **arrayOfCstrings = new const char*[arg.size()];
                    
                    for (int i = 0; i < arg.size(); ++i)
                        arrayOfCstrings[i] = arg[i].c_str();
                    
                    
                    
                    
                    
                    setoffsetdaemons(argc-1,arrayOfCstrings);

                    
                    
                    }else{
                   
                        usage(argv[0]);
                        
                        return(1);
                    
                }
            }
            
        }else if (!strncmp(parameter, "unloadkext", 10)){
            unloadkext();
       
            
        
        }else if (!strncmp(parameter, "loadkext", 8)){
            loadkext();
            return 0;
            
            
        }else if (!strncmp(parameter, "removelaunchd", 13)){
            removeLaunchDaemons();
        }else if (!strncmp(parameter, "buildlaunchd", 12)){
            
          std::vector<int> arg;
            
            
            if (argc >=3 )
                arg.push_back((int)strtol((char *)argv[2],NULL,10));
            if (argc >=4)
                arg.push_back((int)strtol((char *)argv[3],NULL,10));
            if (argc >=5)
                arg.push_back((int)strtol((char *)argv[4],NULL,10));
            if (argc >=6)
                arg.push_back((int)strtol((char *)argv[5],NULL,10));
            if (argc >=7)
                arg.push_back((int)strtol((char *)argv[6],NULL,10));
            if (argc >=8)
                arg.push_back((int)strtol((char *)argv[7],NULL,10));
            if (argc >=9){
                writeLaunchDaemons(arg,(int)strtol((char *)argv[8],NULL,10));
            }else{
            
            writeLaunchDaemons(arg);
            }
            
        }else if (!strncmp(parameter, "offsetdaemons",12)){
            setoffsetdaemons(argc,argv);
        }
        else if (!strncmp(parameter, "offset", 6)){
            
             setoffset(argc,argv);
            
            

        
    }
    else if (!strncmp(parameter, "read", 4))
    {
        
        inout in;
        inout out;
        size_t outsize = sizeof(out);
        
        in.msr = (UInt32)hex2int(msr);
        in.action = AnVMSRActionMethodRDMSR;
        in.param = 0;

#if MAC_OS_X_VERSION_MIN_REQUIRED <= MAC_OS_X_VERSION_10_4
        ret = IOConnectMethodStructureIStructureO( connect, AnVMSRActionMethodRDMSR,
											  sizeof(in),			/* structureInputSize */
											  &outsize,    /* structureOutputSize */
											  &in,        /* inputStructure */
											  &out);       /* ouputStructure */
#else
        ret = IOConnectCallStructMethod(connect,
									AnVMSRActionMethodRDMSR,
									&in,
									sizeof(in),
									&out,
									&outsize
									);
#endif

        if (ret != KERN_SUCCESS)
        {
            printf("Can't connect to StructMethod to send commands\n");
        }

        printf("RDMSR %x returns value 0x%llx\n", (unsigned int)in.msr, (unsigned long long)out.param);
    } else if (!strncmp(parameter, "write", 5)) {
        if (argc < 4)
        {
            usage(argv[0]);
            
            return(1);
        }
        
        inout in;
        inout out;
        size_t outsize = sizeof(out);

        regvalue = (char *)argv[3];

        in.msr = (UInt32)hex2int(msr);
        in.action = AnVMSRActionMethodWRMSR;
        in.param = hex2int(regvalue);

       // printf("WRMSR %x with value 0x%llx\n", (unsigned int)in.msr, (unsigned long long)in.param);
        
        


        ret = IOConnectCallStructMethod(connect,
                                        AnVMSRActionMethodWRMSR,
                                        &in,
                                        sizeof(in),
                                        &out,
                                        &outsize
                                        );
       

        if (ret != KERN_SUCCESS)
        {
            printf("Can't connect to StructMethod to send commands\n");
        }
    } else {
        usage(argv[0]);

        return(1);
    }

 
        if(connect)
        {
            ret = IOServiceClose(connect);
            if (ret != KERN_SUCCESS)
            {
              //  printf("IOServiceClose failed\n");
            }
        }
        
        if(service)
            IOObjectRelease(service);
    
    

        unloadkext();

    

   
    return 0;
}
           
