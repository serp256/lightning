#import "GameAnalytics.h" 
NSArray* readArrayFromValue (value v) {

    if (v != Val_int(0)) {        
        NSLog(@"read");
        NSArray* nsarr;
        value head = Field(v, 0);

        while (Is_block(head)) {
            NSString* nsstr= [NSString stringWithCString:(String_val(Field(head, 0))) encoding:NSASCIIStringEncoding];

            NSLog(@"v %@", nsstr);

                if (!nsarr) nsarr = [[NSMutableArray alloc] init];
                [nsarr addObject:nsstr];                

            head = Field(head, 1);
        }
				return nsarr;
    }
		return nil;
}
value ml_ga_init (value vkey, value vsecret, value vversion, value vcurrencies, value vitemtypes, value vdimensions) {
	CAMLparam5(vversion, vcurrencies);
	CAMLxparam2(vitemtypes, vdiensions);

	NSString* nsversion = Is_block(vversion) ? [NSString stringWithCString:String_val(Field(vversion, 0)) encoding:NSASCIIStringEncoding] :
																							[NSString stringWithFormat:@"%@ %@", @"ios", [LightViewController version]];
	[GameAnalytics configureBuild:nsversion];
	
	NSArray* nscurrencies = readArrayFromValue (vcurrencies);
	if (nscurrencies) {
		[GameAnalytics configureAvailableResourceCurrencies:nscurrencies];
	}
	/*
	[GameAnalytics configureAvailableResourceItemTypes:@[@"boost", @"lives"]];
	// Set available custom dimensions
  [GameAnalytics configureAvailableCustomDimensions01:@[@"ninja", @"samurai"]];
  [GameAnalytics configureAvailableCustomDimensions02:@[@"whale", @"dolphin"]];
  [GameAnalytics configureAvailableCustomDimensions03:@[@"horde", @"alliance"]];
	*/

	NSString* nskey = [NSString stringWithCString:String_val(vkey) encoding:NSUTF8StringEncoding];
	NSString* nssecret = [NSString stringWithCString:String_val(vsecret) encoding:NSUTF8StringEncoding];
	[GameAnalytics initializeWithGameKey:nskey  gameSecret:nssecret];


	CAMLreturn(Val_unit);
}
value ml_ga_init_byte (value* argv, int argn) {
	return ml_ga_init(argv[0], argv[1], argv[2], argv[3], argv[4], argv[5], argv[6]);
}
