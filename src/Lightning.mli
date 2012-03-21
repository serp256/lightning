
value deviceIdentifier: unit -> option string;

value init: (float -> float -> #Stage.c) -> unit;
value openURL : string -> unit;
value sendEmail : string -> ~subject:string -> ?body:string -> unit -> unit;
