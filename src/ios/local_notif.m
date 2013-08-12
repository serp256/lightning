#import <UIKit/UILocalNotification.h>
#import <UIKit/UIApplication.h>
#import <caml/mlvalues.h>
#import <caml/memory.h>

#define ID_KEY [NSString stringWithCString:"id" encoding:NSASCIIStringEncoding]

value ml_lnSchedule(value nid, value fireDate, value alertBody) {
    UILocalNotification *notif = [[UILocalNotification alloc] init];

    if (notif == nil) {
        return Val_false;
    }

    NSLog(@"pizda lala: %s", String_val(nid));

    notif.fireDate = [NSDate dateWithTimeIntervalSince1970:Double_val(fireDate)];
    notif.alertBody = [NSString stringWithCString:String_val(alertBody) encoding:NSUTF8StringEncoding];
    notif.userInfo = [NSDictionary dictionaryWithObject:[NSString stringWithCString:String_val(nid) encoding:NSASCIIStringEncoding] forKey:ID_KEY];

    [[UIApplication sharedApplication] scheduleLocalNotification:notif];
    [notif release];

    return Val_true;
}

value ml_lnCancel(value nid) {
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
		return Val_unit;
}

int nidToIndex(value nid) {
    NSString *nsNid = [NSString stringWithCString:String_val(nid) encoding:NSASCIIStringEncoding];

    return [[UIApplication sharedApplication].scheduledLocalNotifications indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop) {
        UILocalNotification *notif = (UILocalNotification*) obj;
        NSString *val = [notif.userInfo objectForKey:ID_KEY];
        *stop = (val != nil) && ([val compare:nsNid] == NSOrderedSame);
        return *stop;
    }];    
}

value ml_lnExists(value nid) {
    return Val_bool(nidToIndex(nid) != NSNotFound);
}

value ml_notifFireDate(value nid) {
    int idx = nidToIndex(nid);

    if (idx == NSNotFound) {
        return Val_int(0);
    }

    UILocalNotification *notif = (UILocalNotification*) [[UIApplication sharedApplication].scheduledLocalNotifications objectAtIndex:idx];

    value tuple = caml_alloc_tuple(1);
    Store_field(tuple, 0, caml_copy_double([notif.fireDate timeIntervalSince1970]));

    return tuple;
}
