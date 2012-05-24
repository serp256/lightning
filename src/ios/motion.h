extern BOOL accEnabled;
extern CFTimeInterval accLastUpTime;
extern NSTimeInterval accUpInterval;

BOOL ml_acmtrStart(value interval, value cb);
void acmtrGetData(CFTimeInterval now);
void ml_acmtrStop();