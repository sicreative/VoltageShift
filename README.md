# VoltageShift 
Undervoltage Tools for MacOS (Haswell and Broadwell)<br />
All source code under protected by      The GNU General Public License V 3.0   <br />
MSR Kext Driver modifiyed from 
[AnVMSR](http://www.insanelymac.com/forum/topic/291833-anvmsr-v10-tool-and-driver-to-read-from-or-write-to-cpu-msr-registers/)
by  Andy Vandijck Copyright (C) 2013 AnV Software

    NOTICE: THIS TOOL IS FOR ADVANCED USER AND MAY BE DAMAGED YOUR COMPUTER PERMANENTLY. 

You can download this software binary from our site -
[VoltageShift](http://sitechprog.blogspot.com/2017/06/voltageshift.html)

Building
--------
[Xcode](https://developer.apple.com/xcode/) is required. 
Build the kernel extension (kext):

     xcodebuild  -target VoltageShift.kext
     
change the owner to root:wheel for the kext <br />
      sudo chown -R root:wheel build/Release/VoltageShift.kext
    
Build the command line tool:

     xcodebuild  -target voltageshift
     
   

Usage
--------
This program is a command tools that support Haswell and Broadwell  Mac Device for undervoltage.

This use 'Intel Overclock Mailbox' for control the voltage offset, 
Your system may locked of the OC Mailbox and not avilable for undervoltage.

Undervoltage can reduced heat and sustain Turbo boost longer, provide longer battery preformance,although may unstable for the system.

This program do not provided GUI interface because this tools only load the MSR driver when apply, amend or read,
the MSR driver will load and unloaded immediately for more security and lowest resource usage,
after you test well, you can use our tools build up 
the launchd for automative apply on startup and maintance the setting transparently, please read below for detail. 

This program support macOS 10.12 or above, however need to switch off the SIP for unsigned kext under Recovery mode:

Push `Cmd`+`R` when boot to Recovery mode, select Terminal at toolbar and enter: 
    
    csrutil enable --without kext
    
After reboot, ensure the kext and the command tool files on some directory.


You can view your current voltage offset,CPU freqency,power and temperture setting by following command:

    ./voltageshift info
    
You can continous monitor the CPU freqency,power and temperture by using:

    ./voltageshift mon
    
Six type of voltage offset you can change, however we only suggest undervoltage of CPU and GPU.

    ./voltageshift offset <CPU> <GPU> <CPUCache> <SystemAgency> <Analogy I/O> <Digital I/O>
    
for example reduced CPU -50mv and GPU -50mv

    ./voltageshift offset -50 -50

If setting too low the system will freezing, please switch OFF fully and turn on computer for turn back to 0mv.

After you test well and comfort the setting, you can apply the launchd: (require sudo root)

    sudo ./voltageshift buildlaunchd  <CPU> <GPU> <CPUCache> <SystemAgency> <Analogy I/O> <Digital I/O> <Update Mins>

The last <Mins> is the update interval of the tool check and changed, the Default value is 160min,
 deepsleep (suspend to Disk) will reset of the voltage setting, as sleep (suspend to memory) will not change the sleep value, it will scheduled check the setting in peroid, and amend if need.

     0 for only apply the setting when bootup.

    
for example:

    sudo ./voltageshift buildlaunchd  -50 -50 0 0 0 0 18000

set system auto apply CPU -50mv and GPU -50mv every boot and every 3 hour.


You can remove the launchd by following command:

     ./voltageshift removelaunchd
     
     
We also suggest run removelaunchd and them buildlaunchd if you need change the launchd setting. 


Additional
--------

   Use '--damage offset ...' if you want setting lower that 250mv or Overvoltage (>0v).
   
   Manual change the launchd (com.sicreative.VoltageShift.plist under /Library/LaunchDaemons)
   by added new ProgramArguments '--damage' between 
   '/Library/Application Support/VoltageShift/voltageshift' and 'offsetdaemons'
   
   
   
   
   For read the MSR 
   
      ./voltageshift read <HEX_MSR>
      
   For set the MSR
   
     ./voltageshift write <HEX_MSR> <HEX_VALUE>
 
   


    






