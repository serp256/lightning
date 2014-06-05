
#ifndef MLWRAPPER_H_
#define MLWRAPPER_H_

#include <caml/mlvalues.h>
#ifndef ANDROID
#include <caml/threads.h>
#endif

#include "texture_common.h"
#include <zlib.h>

void mlrender_clearTexture();

typedef struct {
	float width;
	float height;
	value stage;
	int needCancelAllTouches;
} mlstage;

mlstage *mlstage_create(float width,float height);
int mlstage_getFrameRate(mlstage *stage);
void mlstage_resize(mlstage *stage,float width,float height);
void mlstage_destroy(mlstage *stage);
void mlstage_advanceTime(mlstage *stage,double timePassed);
uint8_t mlstage_render(mlstage *stage);
void mlstage_preRender(mlstage *stage);
void mlstage_background();
void mlstage_foreground();
void mlstage_processTouches(mlstage *stage, value touches);
void mlstage_cancelAllTouches(mlstage *stage);

typedef enum
{
    SPTouchPhaseBegan,      /// The finger just touched the screen.    
    SPTouchPhaseMoved,      /// The finger moves around.    
    SPTouchPhaseStationary, /// The finger has not moved since the last frame.    
    SPTouchPhaseEnded,      /// The finger was lifted from the screen.    
    SPTouchPhaseCancelled   /// The touch was aborted by the system (e.g. because of an AlertBox popping up)
} SPTouchPhase;

//value mltouch_create(double timestamp,float globalX,float globalY,float previousGlobalX,float previousGlobalY,int tapCount, SPTouchPhase phase);
//
void set_referrer_ml(value type,value id);
void ml_memoryWarning();

int (*loadCompressedTexture)(gzFile gzf, textureInfo *tInfo);
char* compressedExt;

#define REG_CALLBACK(src, dst) { dst = src; caml_register_generational_global_root(&dst); }
#define REG_OPT_CALLBACK(src, dst) if (Is_block(src)) { dst = Field(src, 0); caml_register_generational_global_root(&dst); } else { dst = 0; }
#define RUN_CALLBACK(cb, arga) if (cb) { caml_callback(cb, arga); }
#define RUN_CALLBACK2(cb, arga, argb) if (cb) { caml_callback(cb, arga, argb); }
#define RUN_CALLBACK3(cb, arga, argb, argc) if (cb) { caml_callback(cb, arga, argb, argc); }
#define FREE_CALLBACK(callback) if (callback) { caml_remove_generational_global_root(&callback); }

#endif
