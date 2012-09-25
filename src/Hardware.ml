
IFDEF IOS THEN
external platform: unit -> string = "ml_platform";
external hwmodel: unit -> string = "ml_hwmodel";
external cpu_frequency: unit -> int = "ml_cpuFrequency";
external total_memory: unit -> int = "ml_totalMemory";
external user_memory: unit -> int = "ml_userMemory";
ELSE IFDEF ANDROID THEN
external platform: unit -> string = "ml_platform";
external hwmodel: unit -> string = "ml_hwmodel";
external total_memory: unit -> int = "ml_totalMemory";
ELSE
value platform () = "PLATFORM";
value hwmodel () = "HWMODEL";
value cpu_frequency () = 0;
ENDIF;
value cpu_frequency () = 0;
value internal_user_memory = ref 0;
value user_memory () = !internal_user_memory;
value total_memory () = 0;
ENDIF;
