
#import <GameKit/GameKit.h>
#import <caml/mlvalues.h>
#import <caml/memory.h>
#import <caml/alloc.h>
#import <caml/callback.h>
#import <caml/threads.h>

#import "LightViewController.h"

#include "texture_common.h"

value ml_gamecenter_init(value param) {
	BOOL localPlayerClassAvailable = (NSClassFromString(@"GKLocalPlayer")) != nil;
	// The device must be running iOS 4.1 or later.
	if (!localPlayerClassAvailable) return Val_false;
	NSString *reqSysVer = @"4.1";
	NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
	if ([currSysVer compare:reqSysVer options:NSNumericSearch] == NSOrderedAscending) return Val_false;
	GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
	[localPlayer authenticateWithCompletionHandler:^(NSError *error) {
		NSLog(@"GameCenter Initialized");
		NSCAssert([NSThread isMainThread],@"GameCenter Init call not in main thread");
		//caml_leave_blocking_section();
		value res = Val_false;
		if (localPlayer.isAuthenticated) res = Val_true;
		caml_callback(*caml_named_value("game_center_initialized"),res);
		//caml_enter_blocking_section();
	 }];
	return Val_true;
}

value ml_gamecenter_playerID(value unit) {
	CAMLparam0();
	CAMLlocal1(pid);
	GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
	PRINT_DEBUG("gamcenters: palyerID");
	value res;
	if (localPlayer.isAuthenticated) {
		NSString *playerID = localPlayer.playerID;
		pid = caml_copy_string([playerID cStringUsingEncoding:NSASCIIStringEncoding]);
		PRINT_DEBUG("playerID: %s",String_val(pid));
		res = caml_alloc_small(1,0);
		Field(res,0) = pid;
	} else res = Val_none;
	CAMLreturn(res);
}

value ml_gamecenter_report_leaderboard(value category, value score) {
	GKScore *scoreReporter = [[[GKScore alloc] initWithCategory: [NSString stringWithCString:String_val(category) encoding:NSASCIIStringEncoding]] autorelease];
	scoreReporter.value = Int64_val(score);
	[scoreReporter reportScoreWithCompletionHandler:^(NSError *error) {
		printf("report leaderboard failed\n");
		if (error != nil && error.code == GKErrorCommunicationsFailure) {
			//caml_leave_blocking_section();
			value category,score;
			Begin_roots2(category,score);
			category = caml_copy_string([scoreReporter.category cStringUsingEncoding:NSASCIIStringEncoding]);
			score = caml_copy_int64(scoreReporter.value);
			caml_callback2(*caml_named_value("report_leader_board_failed"),category,score);
			End_roots();
			//caml_enter_blocking_section();
		}
	}];
	return Val_unit;
}


value ml_gamecenter_report_achievement(value identifier, value percentComplete) {
	GKAchievement *achievement = [[[GKAchievement alloc] initWithIdentifier: [NSString stringWithCString:String_val(identifier) encoding:NSASCIIStringEncoding]] autorelease];
	if (achievement) {
		achievement.percentComplete = Double_val(percentComplete);
		[achievement reportAchievementWithCompletionHandler:^(NSError *error)
		{
			if (error != nil && error.code == GKErrorCommunicationsFailure)
			{
				// Retain the achievement object and try again later (not shown).
				//caml_leave_blocking_section();
				value identifier,percentComplete;
				Begin_roots2(identifier,percentComplete);
				identifier = caml_copy_string([achievement.identifier cStringUsingEncoding:NSASCIIStringEncoding]);
				percentComplete = caml_copy_double(achievement.percentComplete);
				caml_callback2(*caml_named_value("report_achievement_failed"),identifier,percentComplete);
				End_roots();
				//caml_enter_blocking_section();
			}
		}];
	}
	return Val_unit;
}

/*
 * возвращаем список строк - идентификаторов друзей
 */
value ml_gamecenter_get_friends_identifiers(value callback) {

  CAMLparam1(callback);

  static value cb = 0;

  GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
  
  cb = callback;

  if (!localPlayer.authenticated) {
    caml_callback(callback, Val_none);
  } else {
  
  caml_register_global_root(&cb);

  [localPlayer loadFriendsWithCompletionHandler:^(NSArray *friends, NSError *error) 
    {
			NSCAssert([NSThread isMainThread],@"GameCenter Get ids call not in main thread");
      //caml_leave_blocking_section();
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
      //caml_enter_blocking_section();
    }
  ];
	}
  
  CAMLreturn(Val_unit);
}

/*
 *
 */
int loadImageFile(UIImage *image, textureInfo *tInfo);


value ml_gamecenter_current_player(value p) {
	CAMLparam0();
	CAMLlocal1(player);
	PRINT_DEBUG("current player");
  GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
	value res;
  if (!localPlayer.authenticated) res = Val_none;
	else {
		player = caml_alloc_tuple(3);
		Store_field(player,0,caml_copy_string([[localPlayer playerID] cStringUsingEncoding:NSUTF8StringEncoding]));
		Store_field(player,1,caml_copy_string([[localPlayer displayName] cStringUsingEncoding:NSUTF8StringEncoding]));
		Store_field(player,2,Val_none);
		res = caml_alloc_small(1,0);
		Field(res,0) = player;
	};
	CAMLreturn(res);
}

value ml_gamecenter_load_users_info(value uids, value callback) {
  CAMLparam2(uids, callback);
  CAMLlocal2(lst, item);
  
	PRINT_DEBUG("load users info");
  lst = uids;
  
  NSMutableArray * identifiers = [NSMutableArray arrayWithCapacity: 1];
  
  while (Is_block(lst)) {
    item = Field(lst,0);
    lst  = Field(lst,1);
    [identifiers addObject:[NSString stringWithCString:String_val(item) encoding:NSASCIIStringEncoding]];
  }
  
  if ([identifiers count] == 0) {
    caml_callback(callback, Val_int(0));
  } else {
  
  value *cb = malloc(sizeof(value));
  *cb = callback;
  caml_register_generational_global_root(cb);
  
  [GKPlayer loadPlayersForIdentifiers:identifiers withCompletionHandler:^(NSArray *players, NSError *error) {

      NSLog(@"loadPlayersForIdentifiers complete handler call");

      if (players != nil)  {
      
        NSMutableArray * loadedPhotos = [NSMutableArray arrayWithCapacity: [players count]];
        NSLock * photosToLoadLock = [[NSLock alloc] init];
        __block int photosToLoad = [players count];
  
        NSLog(@"photosToLoad: %d", photosToLoad);

        void (^retBlock)(void) = ^(void){
            NSLog(@"RETURN GC DATA TO ML");
            //caml_leave_blocking_section();  
            value result = 0, rec = 0, textureID = 0, mlTex = 0;
            Begin_roots4(result,rec,textureID,mlTex);
            result = Val_unit;
						value img,lst_elt;
                    
            for (NSArray * pair in loadedPhotos) {
              rec = caml_alloc_tuple(3);
              GKPlayer * pl = (GKPlayer *)[pair objectAtIndex: 0];
              UIImage  * photo = nil;
              
              if ([pair count] > 1) {
                photo = (UIImage *)[pair objectAtIndex: 1];
              }
              
							if (pl.playerID == nil) continue;
              Store_field(rec,0,caml_copy_string([pl.playerID  cStringUsingEncoding:NSASCIIStringEncoding])); //
              
							if (pl.alias == nil) {
								Store_field(rec,1,caml_copy_string("Unknown Name")); //
							} else {
								Store_field(rec,1,caml_copy_string([pl.alias  cStringUsingEncoding:NSUTF8StringEncoding])); //
							}
              if (photo == nil) {
								Store_field(rec,2,Val_none);// Phono None
              } else {
                textureInfo tInfo;
                loadImageFile(photo, &tInfo);
                textureID = createGLTexture(1,&tInfo,Val_int(1));
                free(tInfo.imgData);
                ML_TEXTURE_INFO(mlTex,textureID,(&tInfo));
              
								img = caml_alloc_small(1,0);
								Field(img,0) = mlTex;

                Store_field(rec,2,img);
              }

              lst_elt = caml_alloc_small(2,0);
              Field(lst_elt, 0) = rec;
              Field(lst_elt, 1) = result;
              result = lst_elt;
              
            }
            
            
            caml_callback(*cb, result);
            End_roots();
            caml_remove_generational_global_root(cb);
            free(cb);
            //caml_enter_blocking_section();
        };
        
        if ([GKPlayer instancesRespondToSelector: @selector(loadPhotoForSize:withCompletionHandler:)]) { // фотки поддерживаются только с ios 5.0
          NSLog(@"instancesRespondToSelector");
          for (GKPlayer * p in players) {
            [p loadPhotoForSize: GKPhotoSizeNormal withCompletionHandler: ^(UIImage *photo, NSError *error) {
                BOOL last = NO;
                [photosToLoadLock lock];
                photosToLoad--;
                last = photosToLoad == 0;

                NSLog(@"_alias: %@", p.alias);
                NSLog(@"_photo: %@", photo);  

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
					caml_callback(*cb,Val_unit);
					caml_remove_generational_global_root(cb);
          free(cb);
				});
      }
   }];
	}
          
  CAMLreturn(Val_unit);
}


value ml_gamecenter_show_leaderboard(value p) {
	[[LightViewController sharedInstance] showLeaderboard];
	return Val_unit;
}

value ml_gamecenter_show_achievements(value p) {
	[[LightViewController sharedInstance] showAchievements];
	return Val_unit;
}
