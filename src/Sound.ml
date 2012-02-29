
exception Audio_error of string;

type category = 
  [ AmbientSound
  | SoloAmbientSound
  | MediaPlayback
  | RecordAudio
  | PlayAndRecord
  | AudioProcessing
  ];

type sound_state = [ SoundInitial | SoundPlaying | SoundPaused | SoundStoped ];


class type channel =
  object
    method play: unit -> unit;
    method stop: unit -> unit;
    method pause: unit -> unit;
    method setLoop: bool -> unit;
    method setVolume: float -> unit;
    method state: sound_state;
    method volume: float;
  end;

IFDEF IOS THEN

Callback.register_exception "Audio_error" (Audio_error "");

external init': category -> unit -> unit = "ml_sound_init";

value init ?(category=SoloAmbientSound) () = init' category ();

type albuffer;
type alsound =
  {
    albuffer: albuffer;
    duration: float;
  };
external albuffer_create: string -> alsound = "ml_albuffer_create";

external al_setMasterVolume: float -> unit = "ml_al_setMasterVolume";

value setMasterVolume = al_setMasterVolume;

value load path = 
  let res = albuffer_create path in
  (
    debug "sound %s - duration %f" path res.duration;
    res;
  );

type alsource;
external alsource_create: albuffer -> alsource = "ml_alsource_create";
external alsource_play: alsource -> unit = "ml_alsource_play" "noalloc";
external alsource_setVolume: alsource -> float -> unit = "ml_alsource_setVolume" "noalloc";
external alsource_getVolume: alsource -> float = "ml_alsource_getVolume";
external alsource_setLoop: alsource -> bool -> unit = "ml_alsource_setLoop" "noalloc";
external alsource_stop: alsource -> unit = "ml_alsource_stop" "noalloc";
external alsource_pause: alsource -> unit = "ml_alsource_pause" "noalloc";

external alsource_state: alsource -> sound_state = "ml_alsource_state" "noalloc";


value createChannel snd : channel =
  object
    value sound = snd;
    value mutable loop = False;
    value mutable startMoment = 0.;
    value mutable pauseMoment = 0.;
    value sourceID = alsource_create snd.albuffer;
    method play () = alsource_play sourceID;
    method pause () = alsource_pause sourceID;
    method stop () = alsource_stop sourceID;
    method setVolume v = alsource_setVolume sourceID v;
    method volume = alsource_getVolume sourceID;
    method setLoop v = alsource_setLoop sourceID v;
    method state = alsource_state sourceID;
  end;

ELSE
(* Sdl version here *)


value init ?category () = ();
value setMasterVolume (_p:float) = ();
type sound = int;
value load (path:string) = 0;
value createChannel (snd:sound) : channel = 
  object
    method play () = ();
    method pause () = ();
    method stop () = ();
    method setVolume _ = ();
    method volume = 1.;
    method setLoop _ = ();
    method state = SoundInitial;
  end;

ENDIF;
