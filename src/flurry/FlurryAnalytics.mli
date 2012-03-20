type gender = [ Male | Female ];

(* 
   Report about session started 
   IN: your app key
*)

value startSession : string -> unit;

value logEvent: ?timed:bool ->  ?params:option (list (string*string)) ->  string -> unit;

(*
  Use endTimedEvent to end timed event before app exits, otherwise timed events automatically end when app
  exits. When ending the timed event, a new event parameters NSDictionary object can be used to update event
  parameters. To keep event parameters the same, pass in None for the event parameters NSDictionary object.
  IN: event name, optional list of key-value pairs
*)  
value endTimedEvent: ?params:option (list (string*string)) -> string ->  unit;



(*
  Use this to log the user's assigned ID or username in your system after identifying the user.
*)  
value setUserID: string -> unit;

(*
  Use this to log the user's age after identifying the user. Valid inputs are 0 or greater.
*)  
value setAge: int -> unit;

(*
  Use this to log the user's gender after identifying the user. Valid inputs are m (male) or f (female)
*)  
value setGender: gender -> unit;


(*
Tracking Location 

CLLocationManager *locationManager = [[CLLocationManager alloc] init];
[locationManager startUpdatingLocation];
CLLocation *location = locationManager.location;

[FlurryAnalytics setLatitude:location.coordinate.latitude longitude:location.coordinate.longitude horizontalAccuracy:location.horizontalAccuracy verticalAccuracy:location.verticalAccuracy];
This allows you to set the current GPS location of the user. Flurry will keep only the last location information.
If your app does not use location services in a meaningful way, using CLLocationManager can result in Apple
rejecting the app submission.


Controlling Data Reporting
[FlurryAnalytics setSessionReportsOnCloseEnabled:(BOOL)sendSessionReportsOnClose];
This option is on by default. When enabled, Flurry will attempt to send session data when the app is exited as
well as it normally does when the app is started. This will improve the speed at which your application analytics
are updated but can prolong the app termination process due to network latency. This option mostly applies for
devices running < iOS 3.2 that do not enable multi-tasking.



[FlurryAnalytics setSessionReportsOnPauseEnabled:(BOOL)sendSessionReportsOnPause];
This option is off by default. When enabled, Flurry will attempt to send session data when the app is paused as
well as it normally does when the app is started. This will improve the speed at which your application analytics
are updated but can prolong the app pause process due to network latency.

[FlurryAnalytics setSecureTransportEnabled:(BOOL)secureTransport];
This option is off by default. When enabled, Flurry will send session data over SSL when the app is paused as
well as it normally does when the app is started. This has the potential to prolong the app pause process due to
added network latency from secure handshaking and encryption.
*)

