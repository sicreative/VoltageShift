# VoltageShift 
Undervoltage Tools for MacOS (Haswell and Broadwell)<br />
All source code protected by      The GNU General Public License V 3.0   <br />
MSR Kext Driver modified from 
[AnVMSR](http://www.insanelymac.com/forum/topic/291833-anvmsr-v10-tool-and-driver-to-read-from-or-write-to-cpu-msr-registers/)
by  Andy Vandijck Copyright (C) 2013 AnV Software

    NOTICE: THIS TOOL IS FOR ADVANCED USERS AND MAY DAMAGE YOUR COMPUTER PERMANENTLY.
    

This App is not support Apple Silicon.

You can download this software´s binary from:
[VoltageShift](voltageshift_1.24.zip)

Building
--------
[Xcode](https://developer.apple.com/xcode/) is required.

```bash
# Build the kernel extension (kext)
xcodebuild  -target VoltageShift
# Change owner
sudo chown -R root:wheel build/Release/VoltageShift.kext
# Build command line tool
xcodebuild  -target voltageshift
```

Usage
--------

This program is a command tool that supports Haswell and above CPUs for undervoltage and TDP setting.
Apple locked the OC capability for newer devices or firmware, if the info show "OC_Locked" mean not able to undervolt, however, you can still disable Turbo and set Power Limit to reduce heat.

It uses the 'Intel Overclock Mailbox' for controling the voltage offset, 

Undervoltage can reduce heat and sustain Turbo boost longer, provide longer battery performance, although if done too much(mV) it may cause an unstable system.

This program supports macOS 10.12 or above, however you need to switch off the SIP for unsigned kext in Recovery mode:

Push `Cmd`+`R` when booting to Recovery mode, select Terminal at toolbar and enter: 
    
    csrutil enable --without kext
    
After reboot, ensure the kext and the command tool files are in the same directory.


For Big Sur, a diaglog will showed when first launched, tick Grey button redirect to System Preferences>Security & Privacy and allow the kext loaded, reboot take the effective.


You can view your current voltage offset,CPU freqency,power and temperture settings with the following command:

    ./voltageshift info
    
You can continue to monitor the CPU frequency, power and temperture by using:

    ./voltageshift mon
    
Six types of voltage offsets are dispenible to change, however we only suggest undervolting the CPU and GPU only.

    ./voltageshift offset <CPU> <GPU> <CPUCache> <SystemAgent> <Analogy I/O> <Digital I/O>
    
for example reduced CPU -50mv and GPU -30mv

    ./voltageshift offset -50 -30

If you set too low the system will freeze, please turn OFF completely and turn ON computer to reset back the undervolt to 0mV.

After you test throughfuly the settings and are comfortable with System stability, you can apply the launchd: (require sudo root)

    sudo ./voltageshift buildlaunchd <CPU> <GPU> <CPUCache> <SA> <AI/O> <DI/O> <turbo> <pl1> <pl2>  <UpdateMins (0 only apply at bootup)> 

The <Update Mins> is the update interval of the tool to check and change, the Default value is 160min, Hibernate (suspend to Disk) will reset the voltage setting, as sleep (suspend to memory) will not change the sleep value, it will scheduled check the setting in peroid, and amend if need. *0 is for applying the setting at bootup only.*

for example:

    sudo ./voltageshift buildlaunchd  -50 -50 0 0 0 0 0 1 50 80 160

set system auto apply CPU -50mv and GPU -50mv, close Turbo, and set PL1 to 50, PL2 to 80, run every boot and every 160min .

    sudo ./voltageshift buildlaunchd  0 0 0 0 0 0 0 -1

switch off turbo only, run every boot and every 160min .

    sudo ./voltageshift buildlaunchd  -20 0 -20 0 0 0 0 -1 -1 -1 0

set system auto apply CPU -20mv and cache -20mv, run only boot .

You can remove the launchd with the following command:

     ./voltageshift removelaunchd
     


ChangeLog
---------

Versions 1.24:
1. Support Big Sur and Universial building on Xcode12 (load on Apple Silicon will simply exit )


Version 1.22:
1. Change read of timer from system api instead of MSR for improve of compatibility. 

Version 1.21:
1. Updated to support auto set Turbo / Power when startup  
2. Default close "offset" for read temp. sensor. (As some system may have issue) [Charlyo]

Version 1.2:
1. Updated to support up to 8 core CPU
2. Updated setting of turbo boost
3. Updated setting of power limited 
4. Additional power limited and turbo boost status showed on -info 
5. Detect Apple BIOS overclock lock (OC_Locked)


Additional
--------

   Use '--damage offset ...' if you want settings lower than 250mv or Overvoltage (>0v).
   
   Manually change the launchd (com.sicreative.VoltageShift.plist under /Library/LaunchDaemons)
   by adding new ProgramArguments '--damage' between 
   '/Library/Application Support/VoltageShift/voltageshift' and 'offsetdaemons'
   
   
   
   
   To read the MSR 
   
      ./voltageshift read <HEX_MSR>
      
   To set the MSR
   
     ./voltageshift write <HEX_MSR> <HEX_VALUE>
     
To set the Power Limted of PL1 (Long Term) and PL2 (Short Term)  
    
    ./voltageshift power <PL1> <PL2>
     
To set Turbo Enabled (0-no turbo 1-turbo):

    ./voltageshift turbo <0/1>

 
   


    






