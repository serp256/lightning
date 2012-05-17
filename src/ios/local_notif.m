#import <UIKit/UILocalNotification.h>
#import <UIKit/UIApplication.h>
#import <caml/mlvalues.h>
#import <caml/memory.h>

#define ID_KEY [NSString stringWithCString:"id" encoding:NSASCIIStringEncoding]

value ml_lnSchedule(value alertAction, value badgeNum, value nid, value fireDate, value alertBody) {
    UILocalNotification *notif = [[UILocalNotification alloc] init];

    if (notif == nil) {
        return Val_false;
    }

    notif.fireDate = [NSDate dateWithTimeIntervalSince1970:Double_val(fireDate)];
    notif.alertBody = [NSString stringWithCString:String_val(alertBody) encoding:NSUTF8StringEncoding];
    notif.userInfo = [NSDictionary dictionaryWithObject:[NSString stringWithCString:String_val(nid) encoding:NSASCIIStringEncoding] forKey:ID_KEY];

    if (!Is_long(alertAction)) {
        notif.alertAction = [NSString stringWithCString:String_val(Field(alertAction, 0)) encoding:NSUTF8StringEncoding];
    }

    if (!Is_long(badgeNum)) {
        notif.applicationIconBadgeNumber = Int_val(Field(badgeNum, 0));
    }

    [[UIApplication sharedApplication] scheduleLocalNotification:notif];
    [notif release];

    return Val_true;
}

void ml_lnCancel(value nid) {
    NSString *nsNid = [NSString stringWithCString:String_val(nid) encoding:NSASCIIStringEncoding];
    UIApplication *app = [UIApplication sharedApplication];

    [app.scheduledLocalNotifications indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop) {
        UILocalNotification *notif = (UILocalNotification*) obj;
        NSString *val = [notif.userInfo objectForKey:ID_KEY];

        if (val != nil) {
            NSComparisonResult compRes = [val compare:nsNid];

            if (compRes == NSOrderedSame) {
                [app cancelLocalNotification:obj];
                *stop = YES;
            }
        }

        return *stop;
    }];
}

value ml_lnExists(value nid) {
    NSString *nsNid = [NSString stringWithCString:String_val(nid) encoding:NSASCIIStringEncoding];
    int idx = [[UIApplication sharedApplication].scheduledLocalNotifications indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop) {
        UILocalNotification *notif = (UILocalNotification*) obj;
        NSString *val = [notif.userInfo objectForKey:ID_KEY];
        *stop = (val != nil) && ([val compare:nsNid] == NSOrderedSame);
        return *stop;
    }];

    return Val_bool(idx != NSNotFound);
}