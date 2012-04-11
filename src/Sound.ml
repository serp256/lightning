
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

type avsound = string;

type sound = [ ALSound of alsound | AVSound of avsound ];

external albuffer_create: string -> alsound = "ml_albuffer_create";
external al_setMasterVolume: float -> unit = "ml_al_setMasterVolume";

value setMasterVolume = al_setMasterVolume;

value load path = 
  match ExtString.String.ends_with path ".caf" with
  [ True    -> ALSound (albuffer_create path)
  | False   -> AVSound path
  ];

type alsource = int32;
external alsource_create: albuffer -> alsource = "ml_alsource_create";
external alsource_play: alsource -> unit = "ml_alsource_play";
external alsource_setVolume: alsource -> float -> unit = "ml_alsource_setVolume";
external alsource_getVolume: alsource -> float = "ml_alsource_getVolume";
external alsource_setLoop: alsource -> bool -> unit = "ml_alsource_setLoop";
external alsource_stop: alsource -> unit = "ml_alsource_stop";
external alsource_pause: alsource -> unit = "ml_alsource_pause";
external alsource_delete: alsource -> unit = "ml_alsource_delete";
external alsource_state: alsource -> sound_state = "ml_alsource_state" "noalloc";


(* ALSound *)
class channel snd = 
  let sourceID = alsource_create snd.albuffer in
  object(self)
    initializer Gc.finalise (fun _ -> alsource_delete sourceID) self;
    value sound = snd;
    value mutable loop = False;
    value mutable startMoment = 0.;
    value mutable pauseMoment = 0.;
    value mutable timer_id = None;
    method play () = 
    (
      debug "play sound";
      alsource_play sourceID;
      timer_id := Some (Timers.start sound.duration self#finished);
    );

    method private finished () = 
      let () = debug "sound finished" in
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
      let () = debug "stop sound" in
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
    method setLoop v = 
    (
      loop := v;
      alsource_setLoop sourceID v;
    );
    method state = alsource_state sourceID;
  end;


type avplayer = int;

external avsound_create_player : avsound -> avplayer = "ml_avsound_create_player";
external avsound_release : avplayer -> unit = "ml_avsound_release";
external avsound_play : avplayer -> unit = "ml_avsound_play";
external avsound_pause : avplayer -> unit = "ml_avsound_pause";
external avsound_stop : avplayer -> unit = "ml_avsound_stop";
external avsound_set_volume : avplayer -> float -> unit = "ml_avsound_set_volume";
external avsound_get_volume : avplayer -> float = "ml_avsound_get_volume";
external avsound_set_loop : avplayer -> bool -> unit = "ml_avsound_set_loop";
external avsound_is_playing : avplayer -> bool = "ml_avsound_is_playing";

(* AVSound *)
class av_channel snd = 
  object(self)
  
    value avplayer = avsound_create_player snd; (* create and call prepare *)
    value mutable paused = False;
        
    initializer (
      Gc.finalise (fun _ -> avsound_release avplayer) self;
    );

    method play () = (
      debug "play avsound";
      paused := False;
      avsound_play avplayer;  
    );

    method private isPlaying () = avsound_is_playing avplayer;
    
    method pause () = (
      debug "pause avsound";
      paused := True;
      avsound_pause avplayer;
    );
    
    method stop () = (
      debug "stop avsound";
      paused := False;
      avsound_stop avplayer;
    );
    
    method setVolume (v:float) = (
      debug "setVolume avsound";
      avsound_set_volume avplayer v;
    );
    
    method volume = (
      debug "volume avsound";
      avsound_get_volume avplayer;
    );
    
    method setLoop loop  = (
      debug "set loop avsound";
      avsound_set_loop avplayer loop;
    );
    
    method state = match (paused, self#isPlaying ()) with
    [ (_, True)         -> SoundPlaying
    | (True, False)     -> SoundPaused
    | (False, False)    -> SoundStoped
    ];
    
  end;



value createChannel snd = 
  match snd with 
  [ ALSound als -> new channel als
  | AVSound avs -> new av_channel avs 
  ];


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
    method setVolume (v:float) = ();
    method volume = 1.;
    method setLoop (b:bool) = ();
    method state = SoundInitial;
  end;


value createChannel snd = new channel snd;

ENDIF;
