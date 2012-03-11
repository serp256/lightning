
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
external alsource_play: alsource -> unit = "ml_alsource_play";
external alsource_setVolume: alsource -> float -> unit = "ml_alsource_setVolume";
external alsource_getVolume: alsource -> float = "ml_alsource_getVolume";
external alsource_setLoop: alsource -> bool -> unit = "ml_alsource_setLoop";
external alsource_stop: alsource -> unit = "ml_alsource_stop";
external alsource_pause: alsource -> unit = "ml_alsource_pause";

external alsource_state: alsource -> sound_state = "ml_alsource_state" "noalloc";

class channel snd = 
  object(self)
    value sourceID = alsource_create snd.albuffer;
    value sound = snd;
    value mutable loop = False;
    value mutable startMoment = 0.;
    value mutable pauseMoment = 0.;
    value mutable timer_id = None;
    method play () = 
    (
      alsource_play sourceID;
      timer_id := Some (Timers.start sound.duration self#finished);
    );

    method private finished () = 
      if loop then timer_id := Some (Timers.start sound.duration self#finished) else timer_id := None;

    method pause () = 
      match timer_id with
      [ Some tid ->
        (
          Timers.stop tid;
          alsource_pause sourceID;
          timer_id := None;
        )
      | None -> ()
      ];

    method stop () = 
      match timer_id with
      [ Some tid ->
        (
          Timers.stop tid;
          alsource_stop sourceID;
          timer_id := None;
        )
      | None -> ()
      ];
    method setVolume v = alsource_setVolume sourceID v;
    method volume = alsource_getVolume sourceID;
    method setLoop v = alsource_setLoop sourceID v;
    method state = alsource_state sourceID;
  end;

value createChannel snd = new channel snd;

ELSE
(* Sdl version here *)

value init ?category () = ();
value setMasterVolume (_p:float) = ();
type sound = int;
value load (path:string) = 0;
class channel snd = 
  object
    method play () = ();
    method pause () = ();
    method stop () = ();
    method setVolume _ = ();
    method volume = 1.;
    method setLoop _ = ();
    method state = SoundInitial;
  end;


value createChannel snd = new channel snd;

ENDIF;
