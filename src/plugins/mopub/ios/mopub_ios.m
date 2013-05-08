
#import "MPInterstitialAdController.h"

#define OBJECT(v) ((id)Data_custom_val(v))

static void interstitial_finalize(value inters) {
	PRINT_DEBUG("finzalied interstition %d",*BANNER(inters));
	id b = *OBJECT(inters);
	if (!b) return;
	JNIEnv *env;
	(*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);
	jclass jLightMoPub = lightMoPub_class(env);
	jmethodID m = jDestroyInterstitialMethod(env,jLightMoPub);
	(*env)->CallStaticVoidMethod(env,jLightMoPub,m,b);
	(*env)->DeleteGlobalRef(env,b);
}

static struct custom_operations interstitial_ops = {
  "pointer to java MoPubInterstitial object",
  interstitial_finalize,
 	custom_compare_default,
  custom_hash_default,
  custom_serialize_default,
  custom_deserialize_default
};

void ml_createMoPubInterstitial(value banner_id,value callback) {
	NSString *unitId = [NSString stringWithCString:String_val(url) encoding:NSASCIIStringEncoding];
	MPInterstitialAdController *inters =[MPInterstitialAdController interstitialAdControllerForAdUnitId:unitId];
}
