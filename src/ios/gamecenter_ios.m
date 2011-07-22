
#import <GameKit/GameKit.h>
#import <caml/mlvalues.h>
#import <caml/memory.h>
#import <caml/alloc.h>
#import <caml/callback.h>
#import <caml/threads.h>

#import "LightViewController.h"


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


void ml_report_leaderboard(value category, value score) {
	GKScore *scoreReporter = [[[GKScore alloc] initWithCategory: [NSString stringWithCString:String_val(category) encoding:NSASCIIStringEncoding]] autorelease];
	scoreReporter.value = Int64_val(score);
	[scoreReporter reportScoreWithCompletionHandler:^(NSError *error) {
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

void ml_show_leaderboard(value p) {
	[[LightViewController sharedInstance] showLeaderboard];
}

void ml_show_achivements(value p) {
	[[LightViewController sharedInstance] showAchievements];
}

