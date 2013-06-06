#import "caml/mlvalues.h"
#import "Flurry.h"

void ml_flurryStartSession(value v_appId) {
	static int started = 0;
	if (started) return;

	NSString* m_appId = [NSString stringWithCString:String_val(v_appId) encoding:NSASCIIStringEncoding];
	[Flurry startSession:m_appId];
	started = 1;
}