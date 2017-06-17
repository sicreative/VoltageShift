#include <mach/mach_types.h>
#include <mach/machine.h>
#include <pexpert/pexpert.h>
#include <string.h>
#include <IOKit/IOLib.h>
#include <IOKit/IOService.h>
#include <IOKit/IOUserClient.h>
#include <IOKit/IOBufferMemoryDescriptor.h>



// Added System wdmsr lib.
#include <libkern/libkern.h>
#include <i386/proc_reg.h>

#define BUFSIZE 	512 	//bytes
#define MAXENTRIES	500
#define MAXUSERS 	5

#define kMethodObjectUserClient ((IOService*) 0 )

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

class AnVMSRUserClient;

class VoltageShiftAnVMSR : public IOService
{
    OSDeclareDefaultStructors(VoltageShiftAnVMSR)
public:
    virtual bool  init(OSDictionary *dictionary = 0);
	virtual void free(void);
	virtual bool start(IOService *provider);
	virtual void stop(IOService *provider);
    virtual uint64_t a_rdmsr(uint32_t msr);
    virtual void a_wrmsr(uint32_t msr, uint64_t value);
    virtual IOReturn runAction(UInt32 action, UInt32 *outSize, void **outData, void *extraArg);

    virtual IOReturn newUserClient(task_t owningTask, void * securityID, UInt32 type, IOUserClient ** handler);
    virtual void setErr(bool set);
    virtual void closeChild(AnVMSRUserClient *ptr);

	size_t mPrefPanelMemoryBufSize;
    uint32_t mPrefPanelMemoryBuf[2];
    UInt16 mClientCount;
    bool mErrFlag;
    AnVMSRUserClient *mClientPtr[MAXUSERS+1];
};

class AnVMSRUserClient : public IOUserClient
{
	OSDeclareDefaultStructors(AnVMSRUserClient);
    
private:
	VoltageShiftAnVMSR *mDevice;

public:
	void messageHandler(UInt32 type, const char *format, ...) __attribute__ ((format (printf, 3, 4)));

    static const AnVMSRUserClient *withTask(task_t owningTask);

	virtual void free();
	virtual bool start(IOService *provider);
	virtual void stop(IOService *provider);

	virtual bool initWithTask(task_t owningTask, void *securityID, UInt32 type, OSDictionary *properties);
	virtual IOReturn clientClose();
	virtual IOReturn clientDied();
    virtual bool set_Q_Size(UInt32 capacity);
    
	virtual bool willTerminate(IOService *provider, IOOptionBits options);
	virtual bool didTerminate(IOService *provider, IOOptionBits options, bool *defer);
	virtual bool terminate(IOOptionBits options = 0);
    
	virtual IOExternalMethod *getTargetAndMethodForIndex(IOService **targetP, UInt32 index);
    
	virtual IOReturn clientMemoryForType(UInt32 type, IOOptionBits *options, IOMemoryDescriptor **memory);
    
    virtual IOReturn actionMethodRDMSR(UInt32 *dataIn, UInt32 *dataOut, IOByteCount inputSize, IOByteCount *outputSize);
    virtual IOReturn actionMethodWRMSR(UInt32 *dataIn, UInt32 *dataOut, IOByteCount inputSize, IOByteCount *outputSize);

    task_t fTask;
   // Remove IODataQueue because of security issue recommend by Apple
    int Q_Err;
};
