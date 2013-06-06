#import "caml/mlvalues.h"
#import "AppFlood.h"

void ml_appfloodStartSession(value v_appKey, value v_secKey) {
	static int started = 0;

	if (started) return;

	NSString* m_appKey = [NSString stringWithCString:String_val(v_appKey) encoding:NSASCIIStringEncoding];
	NSString* m_secKey = [NSString stringWithCString:String_val(v_secKey) encoding:NSASCIIStringEncoding];

	[AppFlood initializeWithId:m_appKey key:m_secKey adType:APPFLOOD_AD_NONE];
	started = 1;
}