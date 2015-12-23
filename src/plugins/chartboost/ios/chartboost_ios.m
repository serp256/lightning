#import "caml/mlvalues.h"

void ml_chartBoostStartSession(value v_appId, value v_appSig) {
	static int started = 0;
	if (started) return;
	/*
	Chartboost* cb = [Chartboost sharedChartboost];
    cb.appId = [NSString stringWithCString:String_val(v_appId) encoding:NSASCIIStringEncoding];
    cb.appSignature = [NSString stringWithCString:String_val(v_appSig) encoding:NSASCIIStringEncoding];
    [cb startSession];
		*/

	started = 1;
}
