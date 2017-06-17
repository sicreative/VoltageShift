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
     
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
change the owner to root:wheel for the kext <br />
      sudo chown -R root:wheel build/Release/VoltageShift.kext
<<<<<<< HEAD
=======
change the owner to root:wheel for the kext 
=======
change the owner to root:wheel for the kext <br />
>>>>>>> f388995... Update README.md
=======
change the owner to root:wheel for the kext <br />
>>>>>>> f388995... Update README.md
      sudo chown -R root:wheel build/Release/V.kext
>>>>>>> b29bd67... Create README.md
=======
change the owner to root:wheel for the kext 
      sudo chown -R root:wheel build/Release/V.kext
>>>>>>> b29bd67... Create README.md
=======
>>>>>>> b2833a8... Update README.md
    
Build the command line tool:

     xcodebuild  -target voltageshift
     
   

Usage
--------
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
This program is a command tools that support Haswell and Broadwell  Mac Device for undervoltage.

This use 'Intel Overclock Mailbox' for control the voltage offset, 
Your system may locked of the OC Mailbox and not avilable for undervoltage.

Undervoltage can reduced heat and sustain Turbo boost longer, provide longer battery preformance,although may unstable for the system.

This program do not provided GUI interface because this tools only load the MSR driver when apply, amend or read,
the MSR driver will load and unloaded immediately for more security and lowest resource usage,
after you test well, you can use our tools build up 
the launchd for automative apply on startup and maintance the setting transparently, please read below for detail. 

This program support macOS 10.12 or above, however need to switch off the SIP for unsigned kext under Recovery mode:

=======
=======
>>>>>>> b29bd67... Create README.md
This program is a command tools that support Haswell and Bradwell (may support Skylake) Mac Device for undervoltage.
=======
This program is a command tools that support Haswell and Bradwell  Mac Device for undervoltage.
>>>>>>> 5f00ae4... Update README.md

This use 'Intel Overclock Mailbox' for control the voltage offset, 
Your system may locked of the OC Mailbox and not avilable for undervoltage.

Undervoltage can reduced heat and sustain Turbo boost longer, provide longer battery preformance,although may unstable for the system.

This program do not provided GUI interface because this tools only load the MSR driver when apply, amend or read,
the MSR driver will load and unloaded immediately for more security and lowest resource usage,
after you test well, you can use our tools build up 
the launchd for automative apply on startup and maintance the setting transparently, please read below for detail. 

<<<<<<< HEAD
This program support macOS 10.12 or above, however need to switch off the SIP kext under Recovery mode:
<<<<<<< HEAD
>>>>>>> b29bd67... Create README.md
=======
>>>>>>> b29bd67... Create README.md
=======
This program support macOS 10.12 or above, however need to switch off the SIP for unsigned kext under Recovery mode:

>>>>>>> 5d64146... Update README.md
Push `Cmd`+`R` when boot to Recovery mode, select Terminal at toolbar and enter: 
    
    csrutil enable --without kext
    
After reboot, ensure the kext and the command tool files on some directory.


<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
=======
Info

>>>>>>> b29bd67... Create README.md
=======
Info

>>>>>>> b29bd67... Create README.md
=======
>>>>>>> 5d64146... Update README.md
You can view your current voltage offset,CPU freqency,power and temperture setting by following command:

    ./voltageshift info
    
You can continous monitor the CPU freqency,power and temperture by using:

    ./voltageshift mon
    
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
Six type of voltage offset you can change, however we only suggest undervoltage of CPU and GPU.
=======
Six type voltage offset you can change, however we only suggest undervoltage of CPU and GPU tempeture.
>>>>>>> b29bd67... Create README.md
=======
Six type voltage offset you can change, however we only suggest undervoltage of CPU and GPU tempeture.
>>>>>>> b29bd67... Create README.md
=======
Six type of voltage offset you can change, however we only suggest undervoltage of CPU and GPU.
>>>>>>> 5f00ae4... Update README.md

    ./voltageshift offset <CPU> <GPU> <CPUCache> <SystemAgency> <Analogy I/O> <Digital I/O>
    
for example reduced CPU -50mv and GPU -50mv

    ./voltageshift offset -50 -50

If setting too low the system will freezing, please switch OFF fully and turn on computer for turn back to 0mv.

After you test well and comfort the setting, you can apply the launchd: (require sudo root)

    sudo ./voltageshift buildlaunchd  <CPU> <GPU> <CPUCache> <SystemAgency> <Analogy I/O> <Digital I/O> <CheckSecond>

The last <CheckSecond> is the interval of the tool check and ameded, the Default value is 150min,
as the offset values will reset after fully switch off or hibernate (suspend to Disk), 
by default the Macbook will delay 'Suspend to Disk' after three hours from 'Suspend to RAM' when using Battery, 
2.5 hours is enough the tool amended the value after wake from Suspend to disk, you can override this value.     
    
for example:

<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
    sudo ./voltageshift buildlaunchd  -50 -50 0 0 0 0 18000

set system auto apply CPU -50mv and GPU -50mv every boot and every 3 hour.
=======
    sudo ./voltageshift buildlaunchd  -50 -50 0 0 0 0 

set system auto apply CPU -50mv and GPU -50mv every boot and every 2.5hour.
>>>>>>> b29bd67... Create README.md
=======
    sudo ./voltageshift buildlaunchd  -50 -50 0 0 0 0 

set system auto apply CPU -50mv and GPU -50mv every boot and every 2.5hour.
>>>>>>> b29bd67... Create README.md
=======
    sudo ./voltageshift buildlaunchd  -50 -50 0 0 0 0 18000

set system auto apply CPU -50mv and GPU -50mv every boot and every 3 hour.
>>>>>>> 351108b... Update README.md


You can remove the launchd by following command:

     ./voltageshift removelaunchd
     
     
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
We also suggest run removelaunchd and them buildlaunchd if you need change the launchd setting. 
=======

>>>>>>> b29bd67... Create README.md
=======

>>>>>>> b29bd67... Create README.md
=======
We also suggest run removelaunchd and them buildlaunchd if you need change the launchd setting. 
>>>>>>> 8e4429c... Update README.md


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
 
   
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
=======
=======
>>>>>>> b29bd67... Create README.md
   
     
     
     


<<<<<<< HEAD
>>>>>>> b29bd67... Create README.md
=======
>>>>>>> b29bd67... Create README.md
=======
>>>>>>> 5d64146... Update README.md


    






