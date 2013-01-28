
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
void mlstage_render(mlstage *stage);
void mlstage_preRender();
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
void ml_memoryWarning();

int (*loadCompressedTexture)(gzFile* gzf, textureInfo *tInfo);
char* compressedExt;

#endif
