#import <CoreMotion/CMMotionManager.h>
#import <QuartzCore/CABase.h>
#import <caml/alloc.h>
#import <caml/callback.h>
#import <caml/mlvalues.h>
#import <caml/memory.h>

CFTimeInterval accLastUpTime;
NSTimeInterval accUpInterval;
BOOL accEnabled = NO;
static CMMotionManager* mmInstance;

CMMotionManager* getMmInstance() {
	if (mmInstance == nil) {
		mmInstance = [[CMMotionManager alloc] init];
	}

	return mmInstance;
}

static value accCb = 0;

void ml_acmtrStart(value cb, value interval) {
	accUpInterval = Double_val(interval);

	if (accCb == 0) {
		accCb = cb;
		caml_register_generational_global_root(&accCb);
	} else {
		caml_modify_generational_global_root(&accCb, cb);
	}

	CMMotionManager *mm = getMmInstance();

	if (!mm.accelerometerAvailable) {
		return;
	}

	if (!mm.accelerometerActive) {
		accEnabled = YES;
		[mm startAccelerometerUpdates];
	}
}

void acmtrGetData (CFTimeInterval now) {
	accLastUpTime = now;
	CMAccelerometerData* data = getMmInstance().accelerometerData;

	if (data == nil) {
		return;
	}
	
	CMAcceleration acc = data.acceleration;
	value acmtrData = caml_alloc(3 * Double_wosize, Double_array_tag);
	Store_double_field(acmtrData, 0, acc.x);
	Store_double_field(acmtrData, 1, acc.y);
	Store_double_field(acmtrData, 2, acc.z);

	caml_callback(accCb, acmtrData);
}

void ml_acmtrStop() {
	if (accCb != 0) {
		caml_remove_generational_global_root(&accCb);
		accCb = 0;		
	}

	[getMmInstance() stopAccelerometerUpdates];
	[mmInstance release];
	mmInstance = nil;
	accEnabled = NO;
}