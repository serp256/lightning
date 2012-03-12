
#import <GameKit/GameKit.h>
#import <caml/mlvalues.h>
#import <caml/memory.h>
#import <caml/alloc.h>
#import <caml/callback.h>
#import <caml/threads.h>

#import "LightViewController.h"

#include "texture_common.h"

value ml_game_center_init(value param) {
	BOOL localPlayerClassAvailable = (NSClassFromString(@"GKLocalPlayer")) != nil;
	// The device must be running iOS 4.1 or later.
	if (!localPlayerClassAvailable) return Val_int(0);
	NSString *reqSysVer = @"4.1";
	NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
	if ([currSysVer compare:reqSysVer options:NSNumericSearch] == NSOrderedAscending) return Val_int(0);
	GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
	[localPlayer authenticateWithCompletionHandler:^(NSError *error) {
		NSLog(@"Initialized");
		caml_leave_blocking_section();
		value res = Val_false;
		if (localPlayer.isAuthenticated) res = Val_true;

		caml_callback(*caml_named_value("game_center_initialized"),res);
		caml_enter_blocking_section();
	 }];
	return Val_int(1);
}

value ml_playerID(value unit) {
	NSString *playerID = [GKLocalPlayer localPlayer].playerID;
	value result = caml_copy_string([playerID cStringUsingEncoding:NSASCIIStringEncoding]);
	return result;
}

void ml_report_leaderboard(value category, value score) {
	GKScore *scoreReporter = [[[GKScore alloc] initWithCategory: [NSString stringWithCString:String_val(category) encoding:NSASCIIStringEncoding]] autorelease];
	scoreReporter.value = Int64_val(score);
	[scoreReporter reportScoreWithCompletionHandler:^(NSError *error) {
		printf("report leaderboard failed\n");
		if (error != nil && error.code == GKErrorCommunicationsFailure) {
			caml_leave_blocking_section();
			value category,score;
			Begin_roots2(category,score);
			category = caml_copy_string([scoreReporter.category cStringUsingEncoding:NSASCIIStringEncoding]);
			score = caml_copy_int64(scoreReporter.value);
			caml_callback2(*caml_named_value("report_leader_board_failed"),category,score);
			End_roots();
			caml_enter_blocking_section();
		}
	}];
}



void ml_report_achivement(value identifier, value percentComplete) {
	GKAchievement *achievement = [[[GKAchievement alloc] initWithIdentifier: [NSString stringWithCString:String_val(identifier) encoding:NSASCIIStringEncoding]] autorelease];
	if (achievement) {
		achievement.percentComplete = Double_val(percentComplete);
		[achievement reportAchievementWithCompletionHandler:^(NSError *error)
		{
			if (error != nil && error.code == GKErrorCommunicationsFailure)
			{
				// Retain the achievement object and try again later (not shown).
				caml_leave_blocking_section();
				value identifier,percentComplete;
				Begin_roots2(identifier,percentComplete);
				identifier = caml_copy_string([achievement.identifier cStringUsingEncoding:NSASCIIStringEncoding]);
				percentComplete = caml_copy_double(achievement.percentComplete);
				caml_callback2(*caml_named_value("report_achivement_failed"),identifier,percentComplete);
				End_roots();
				caml_enter_blocking_section();
			}
		}];
	}
}

/*
 * возвращаем список строк - идентификаторов друзей
 */
void ml_get_friends_identifiers(value callback) {
  static value cb = 0;

  CAMLparam1(callback);
  GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
  
  cb = callback;

  if (!localPlayer.authenticated) {
    caml_callback(callback, Val_int(0));
    CAMLreturn0;
  }
  
  caml_register_global_root(&cb);

  [localPlayer loadFriendsWithCompletionHandler:^(NSArray *friends, NSError *error) 
    {
			NSCAssert([NSThread isMainThread],@"GameCenter call not in main thread");
      caml_leave_blocking_section();
      if (error != nil || [friends count] == 0) {
        caml_callback(cb, Val_int(0));
      } else {
        value mlfriends, lst_el;
        Begin_roots1(mlfriends);
        mlfriends = Val_int(0);
        
        for (NSString * friendID in friends) {
          value fid = caml_copy_string([friendID cStringUsingEncoding:NSASCIIStringEncoding]);
          lst_el = caml_alloc_small(2,0);
          Field(lst_el,0) = fid;
          Field(lst_el,1) = mlfriends;
          mlfriends = lst_el;          
        }
        caml_callback(cb, mlfriends);
        End_roots();
      }
      caml_remove_global_root(&cb);
      caml_enter_blocking_section();
    }
  ];
  
  CAMLreturn0;
}

/*
 *
 */
int loadImageFile(UIImage *image, textureInfo *tInfo);

void ml_load_users_info(value uids, value callback) {
  CAMLparam2(uids, callback);
  static value cb = 0; 
  cb = callback;

  CAMLlocal2(lst, item);
  lst = uids;
  
  NSMutableArray * identifiers = [NSMutableArray arrayWithCapacity: 1];
  
  while (Is_block(lst)) {
    item = Field(lst,0);
    lst  = Field(lst,1);
    [identifiers addObject:[NSString stringWithCString:String_val(item) encoding:NSASCIIStringEncoding]];
  }
  
  if ([identifiers count] == 0) {
    caml_callback(callback, Val_int(0));
    CAMLreturn0;
  }
  
  caml_register_global_root(&cb);
  
  [GKPlayer loadPlayersForIdentifiers:identifiers withCompletionHandler:^(NSArray *players, NSError *error) {

      if (players != nil)  {
      
        NSMutableArray * loadedPhotos = [NSMutableArray arrayWithCapacity: [players count]];
        NSLock * photosToLoadLock = [[NSLock alloc] init];
        __block int photosToLoad = [players count];
  
  
        void (^retBlock)(void) = ^(void){
            caml_leave_blocking_section();  
            value infos, lst_elt, info, img,mlTex;
            Begin_roots4(infos,info,img,mlTex);
            infos = Val_int(0);
						value alias;
                    
            for (NSArray * pair in loadedPhotos) {
              info = caml_alloc_tuple(2);
              GKPlayer * pl = (GKPlayer *)[pair objectAtIndex: 0];
              UIImage  * photo = nil;
              
              if ([pair count] > 1) {
                photo = (UIImage *)[pair objectAtIndex: 1];
              }
              
              Store_field(info,0,caml_copy_string([pl.playerID  cStringUsingEncoding:NSASCIIStringEncoding])); //
              Store_field(info,1,caml_alloc_tuple(2));
              
							alias = caml_copy_string([pl.alias  cStringUsingEncoding:NSASCIIStringEncoding]); //
              Field(Field(info,1), 0) = alias;
              
              if (photo == nil) {
                Field(Field(info,1), 1) = Val_int(0); // photo None
              } else {
                textureInfo tInfo;
                uint textureID;
                loadImageFile(photo, &tInfo);
                textureID = createGLTexture(0,&tInfo);
                free(tInfo.imgData);
                ML_TEXTURE_INFO(mlTex,textureID,(&tInfo));
                
								img = caml_alloc_small(1,0);
								Field(img,0) = mlTex;
								Field(Field(info,1),1) = img;
              }
                      
              lst_elt = caml_alloc_small(2,0);
              Field(lst_elt, 0) = info;
              Field(lst_elt, 1) = infos;
              infos = lst_elt;
            }
            caml_callback(cb, infos);
            End_roots();
            caml_remove_global_root(&cb);
            caml_enter_blocking_section();
        };
        
        if ([GKPlayer instancesRespondToSelector: @selector(loadPhotoForSize:withCompletionHandler:)]) { // фотки поддерживаются только с ios 5.0
          for (GKPlayer * p in players) {
            [p loadPhotoForSize: GKPhotoSizeNormal withCompletionHandler: ^(UIImage *photo, NSError *error) {
                BOOL last = NO;
                [photosToLoadLock lock];
                photosToLoad--;
                last = photosToLoad == 0;

                if (photo != nil) {
                  [loadedPhotos addObject: [NSArray arrayWithObjects: p, photo, nil]];
                } else {
                  [loadedPhotos addObject: [NSArray arrayWithObjects: p, nil]];
                }
                [photosToLoadLock unlock];
                
                if (last) {
                  dispatch_async(dispatch_get_main_queue(), retBlock);
                }
            }];
          }
        }  else {
          for (GKPlayer * p in players) {
            [loadedPhotos addObject: [NSArray arrayWithObjects: p, nil]];
          }
          dispatch_async(dispatch_get_main_queue(), retBlock);
        }  
        
      } else {
				dispatch_async(dispatch_get_main_queue(),^(void) {
					caml_callback(cb,Val_unit);
					caml_remove_global_root(&cb);
				});
      }
   }];
          
  CAMLreturn0;
}


void ml_show_leaderboard(value p) {
	[[LightViewController sharedInstance] showLeaderboard];
}

void ml_show_achivements(value p) {
	[[LightViewController sharedInstance] showAchievements];
}







