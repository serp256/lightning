
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

value init: ?category:category -> unit -> unit;

value setMasterVolume: float -> unit;

type sound;

value load: string -> sound;

class type channel  =
  object
    method play: unit -> unit;
    method pause: unit -> unit;
    method stop: unit -> unit;
    method setVolume: float -> unit;
    method volume: float;
    method setLoop: bool -> unit;
    method state: sound_state;
  end;


value createChannel: sound -> channel;

