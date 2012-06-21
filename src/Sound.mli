value ev_SOUND_COMPLETE : Ev.id;

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
type sound;

value init: unit -> unit;
value setMasterVolume: float -> unit;
value load: string -> sound;

class type virtual channel  =
  object
    inherit EventDispatcher.simple [ channel ];
    method play: unit -> unit;
    method pause: unit -> unit;
    method stop: unit -> unit;
    method setVolume: float -> unit;
    method volume: float;
    method setLoop: bool -> unit;
    method state: sound_state;
  end;

value createChannel: sound -> channel;