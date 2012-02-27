
#import "mlwrapper.h"

#define STR_CAML2OBJC(mlstr) [NSString stringWithCString:String_val(mlstr) encoding:NSASCIIStringEncoding]

void process_touches(UIView* view, NSSet* touches, UIEvent *event,  mlstage *mlstage);
