(*
 * sdlcaml - Objective Caml interface for the SDL library
 * Copyright (C) 1999, Jean-Christophe FILLIATRE, (C) 2006 Elliott Oti
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License version 2, as published by the Free Software Foundation.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *
 * See the GNU Library General Public License version 2 for more details
 * (enclosed in the file LGPL).
 *)
(*
 * Modifications by Elliott Oti (May 2006)
 * Module Audio added
 * Module Window added	
 * Functions added to Module Video and Event
 * Non-SDL functions added to Module Draw: scale, scale_to, read_tga, load_tga, make_mipmaps,make_sfont and sfont_print
 *)
exception SDL_failure of string;
type byte_array =
  Bigarray.Array1.t int Bigarray.int8_unsigned_elt Bigarray.c_layout;
(* Initialization. *)
type init_flag =
  [ TIMER
  | AUDIO
  | VIDEO
(*   | CDROM *)
  | JOYSTICK
  | NOPARACHUTE
  | EVENTTHREAD
  | EVERYTHING ];
(* Don't catch fatal signals *)
(* Not supported on all OS's *)
external init : list init_flag -> unit = "sdlstub_init";
value init init_flag = 
(
  Callback.register_exception "SDL_failure" (SDL_failure "");
  init init_flag;
);

external quit : unit -> unit = "sdlstub_quit";
external get_error : unit -> string = "sdlstub_get_error";
(******************************* Video. ************************************)
module Video =
  struct
    type video_flag =
      [ SWSURFACE
      | HWSURFACE
      | ANYFORMAT
      | HWPALETTE
      | DOUBLEBUF
      | FULLSCREEN
      | HWACCEL
      | SRCCOLORKEY
      | RLEACCEL
      | SRCALPHA
      | SRCCLIPPING
      | OPENGL
      | RESIZABLE
      | NOFRAME ];
    (* Surface is in system memory *)
    (* Surface is in video memory *)
    (* Allow any video pixel format *)
    (* Surface has exclusive palette *)
    (* Set up double-buffered video mode *)
    (* Surface is a full screen display *)
    (* Blit uses hardware acceleration *)
    (* Blit uses a source color key *)
    (* Colorkey blit is RLE accelerated *)
    (* Blit uses source alpha blending *)
    (* Blit uses source clipping *)
    (* Surface supports OpenGL *)
    (* Surface is resizable *)
    (* Creates a window with no title frame and no border *)
    type surface;
    external free_surface : surface -> unit = "sdlstub_free_surface";
    external surface_pixels : surface -> byte_array = "sdlstub_surface_pixels";
    external surface_width : surface -> int = "sdlstub_surface_width";
    external surface_height : surface -> int = "sdlstub_surface_height";
(*     external surface_flags : surface -> list video_flag = "sdlstub_surface_flags"; *)
    external surface_bpp : surface -> int = "sdlstub_surface_bpp";
    external surface_rmask : surface -> int = "sdlstub_surface_rmask";
    external surface_gmask : surface -> int = "sdlstub_surface_gmask";
    external surface_bmask : surface -> int = "sdlstub_surface_bmask";
    external surface_amask : surface -> int = "sdlstub_surface_amask";
    external must_lock : surface -> bool = "sdlstub_must_lock";
    external lock_surface : surface -> unit = "sdlstub_lock_surface";
    external unlock_surface : surface -> unit = "sdlstub_unlock_surface";
(*     external video_mode_ok : int -> int -> int -> list video_flag -> bool = "sdlstub_video_mode_ok"; *)
(*     external set_video_mode : int -> int -> int -> list video_flag -> surface = "sdlstub_set_video_mode"; *)
    external create_rgb_surface : list video_flag -> int -> int -> int -> surface = "sdlstub_create_rgb_surface";
    external load_bmp : string -> surface = "sdlstub_load_bmp";
    external save_bmp : surface -> string -> unit = "sdlstub_save_bmp";
    external set_color_key : surface -> list video_flag -> int32 -> unit = "sdlstub_set_color_key";
(*     external set_alpha : surface -> list video_flag -> int -> unit = "sdlstub_set_alpha"; *)
    external set_alpha_mod: surface -> int -> unit = "sdlstub_set_surface_alpha_mod";
    type blendMode = 
      [ BLENDMODE_NONE (**< No blending *)
      | BLENDMODE_MASK (**< dst = A ? src : dst (alpha is mask) *)
      | BLENDMODE_BLEND (**< dst = (src * A) + (dst * (1-A)) *)
      | BLENDMODE_ADD (**< dst = (src * A) + dst *)
      | BLENDMODE_MOD (**< dst = src * dst *)
      ];
      
    external set_blend_mode: surface -> blendMode -> unit = "sdlstub_set_surface_blend_mode";
    external set_clipping : surface -> int -> int -> int -> int -> unit = "sdlstub_set_clipping";
    value disable_clipping s = set_clipping s 0 0 0 0;
(*     external display_format : surface -> surface = "sdlstub_display_format"; *)
    external get_rgb : surface -> int32 -> (int * int * int) =
      "sdlstub_get_rgb";
    external get_rgba : surface -> int32 -> (int * int * int * int) =
      "sdlstub_get_rgba";
    external map_rgb : surface -> int -> int -> int -> int32 = "sdlstub_map_rgb";
    external map_rgba : surface -> int -> int -> int -> int -> int32 = "sdlstub_map_rgba";
    type rect =
      { rect_x : mutable int; rect_y : mutable int; rect_w : mutable int;
        rect_h : mutable int
      };
    external fill_surface : surface -> int32 -> unit = "sdlstub_fill_surface";
    external fill_rect : surface -> rect -> int32 -> unit = "sdlstub_fill_rect";
(*     external update_surface : surface -> unit = "sdlstub_update_surface"; *)
(*     external update_rect : surface -> int -> int -> int -> int -> unit = "sdlstub_update_rect"; *)
(*     external update_rects : surface -> array rect -> unit = "sdlstub_update_rects"; *)
(*     external flip : surface -> unit = "sdlstub_flip"; *)
    external blit_surface :
      surface -> option rect -> surface -> option rect -> unit =
      "sdlstub_blit_surface";
    type color = { red : int; green : int; blue : int };
(*     external set_colors : surface -> array color -> int -> int -> bool = "sdlstub_set_colors"; *)
    external show_cursor : bool -> unit = "sdlstub_show_cursor";
(*     external warp_mouse : int -> int -> unit = "sdlstub_warp_mouse"; *)
    external string_of_pixels : surface -> string =
      "sdlstub_string_of_pixels";
  end;
(******************************* End Video. ************************************)
(****************************** Window management ******************************)
module Window =
  struct
(*     external set_caption : string -> string -> unit = "sdlstub_set_caption"; *)
(*     external get_caption : unit -> (string * string) = "sdlstub_get_caption"; *)
(*     external set_icon : Video.surface -> unit = "sdlstub_set_icon"; *)
(*     external iconify_window : unit -> unit = "sdlstub_iconify_window"; *)
(*     external toggle_fullscreen : Video.surface -> unit = "sdlstub_toggle_fullscreen"; *)
(*     external set_grab_input : bool -> unit = "sdlstub_set_grab_input"; *)
(*     external get_grab_input : unit -> bool = "sdlstub_get_grab_input"; *)
    type t;
    type pos = [ PosUndefined | PosCentered | Pos of int ];
    type flag = [ FULLSCREEN | SHOWN | RESIZABLE | MINIMIZED | OPENGL | BORDERLESS | MAXIMIZED | INPUT_GRABBED ];
    external create: ~title:string -> ~x:pos -> ~y:pos -> ~w:int -> ~h:int -> list flag -> t = "sdlstub_create_window_byte" "sdlstub_create_window" ;
    external destroy: t -> unit = "sdlstub_destroy_window";
  end;
(****************************** End Window management ******************************)
(**************************** Open GL support **************************************)
module SDLGL =
  struct
    type gl_attr =
      [ RED_SIZE
      | GREEN_SIZE
      | BLUE_SIZE
      | ALPHA_SIZE
      | DOUBLEBUFFER
      | BUFFER_SIZE
      | DEPTH_SIZE
      | STENCIL_SIZE
      | ACCUM_RED_SIZE
      | ACCUM_GREEN_SIZE
      | ACCUM_BLUE_SIZE
      | ACCUM_ALPHA_SIZE 
      | CONTEXT_MAJOR_VERSION
      | CONTEXT_MINOR_VERSION
      ];
(*     external swap_buffers : unit -> unit = "sdlstub_GL_swap_buffers"; *)
(*     external load_bmp : string -> Video.surface = "sdlstub_GL_load_bmp"; *)
    external set_attribute : gl_attr -> int -> unit = "sdlstub_gl_set_attribute";
    external get_attribute : gl_attr -> int = "sdlstub_gl_get_attribute";
    type context;
    external create_context: Window.t -> context = "sdlstub_gl_create_context";
(*     external make_current: Window.t -> context -> unit = "sdlstub_gl_make_current"; *)
    external delete_context: context -> unit = "sdlstub_gl_delete_context";
    external swap_window: Window.t -> unit = "sdlstub_gl_swap_window";
    external set_swap_interval: int -> unit = "sdlstub_gl_set_swap_interval";
  end;
(**************************** End Open GL support **************************************)
(***************************** Events. *************************************************)
module Event =
  struct
    type que_dis_ena = [ QUERY | DISABLE | ENABLE ];
    type off_on = [ OFF | ON ];
    type pointer;
(*     type app_state = [ APPMOUSEFOCUS | APPINPUTFOCUS | APPACTIVE ]; *)
(*     external get_app_state : unit -> list app_state = "sdlstub_get_app_state"; *)
    (* SDLKey enum *)
    type key =
      [ K_UNKNOWN
      | K_FIRST
      | K_BACKSPACE
      | K_TAB
      | K_CLEAR
      | K_RETURN
      | K_PAUSE
      | K_ESCAPE
      | K_SPACE
      | K_EXCLAIM
      | K_QUOTEDBL
      | K_HASH
      | K_DOLLAR
      | K_AMPERSAND
      | K_QUOTE
      | K_LEFTPAREN
      | K_RIGHTPAREN
      | K_ASTERISK
      | K_PLUS
      | K_COMMA
      | K_MINUS
      | K_PERIOD
      | K_SLASH
      | K_0
      | K_1
      | K_2
      | K_3
      | K_4
      | K_5
      | K_6
      | K_7
      | K_8
      | K_9
      | K_COLON
      | K_SEMICOLON
      | K_LESS
      | K_EQUALS
      | K_GREATER
      | K_QUESTION
      | K_AT
      | K_LEFTBRACKET
      | K_BACKSLASH
      | K_RIGHTBRACKET
      | K_CARET
      | K_UNDERSCORE
      | K_BACKQUOTE
      | K_A
      | K_B
      | K_C
      | K_D
      | K_E
      | K_F
      | K_G
      | K_H
      | K_I
      | K_J
      | K_K
      | K_L
      | K_M
      | K_N
      | K_O
      | K_P
      | K_Q
      | K_R
      | K_S
      | K_T
      | K_U
      | K_V
      | K_W
      | K_X
      | K_Y
      | K_Z
      | K_DELETE
      | K_WORLD_0
      | K_WORLD_1
      | K_WORLD_2
      | K_WORLD_3
      | K_WORLD_4
      | K_WORLD_5
      | K_WORLD_6
      | K_WORLD_7
      | K_WORLD_8
      | K_WORLD_9
      | K_WORLD_10
      | K_WORLD_11
      | K_WORLD_12
      | K_WORLD_13
      | K_WORLD_14
      | K_WORLD_15
      | K_WORLD_16
      | K_WORLD_17
      | K_WORLD_18
      | K_WORLD_19
      | K_WORLD_20
      | K_WORLD_21
      | K_WORLD_22
      | K_WORLD_23
      | K_WORLD_24
      | K_WORLD_25
      | K_WORLD_26
      | K_WORLD_27
      | K_WORLD_28
      | K_WORLD_29
      | K_WORLD_30
      | K_WORLD_31
      | K_WORLD_32
      | K_WORLD_33
      | K_WORLD_34
      | K_WORLD_35
      | K_WORLD_36
      | K_WORLD_37
      | K_WORLD_38
      | K_WORLD_39
      | K_WORLD_40
      | K_WORLD_41
      | K_WORLD_42
      | K_WORLD_43
      | K_WORLD_44
      | K_WORLD_45
      | K_WORLD_46
      | K_WORLD_47
      | K_WORLD_48
      | K_WORLD_49
      | K_WORLD_50
      | K_WORLD_51
      | K_WORLD_52
      | K_WORLD_53
      | K_WORLD_54
      | K_WORLD_55
      | K_WORLD_56
      | K_WORLD_57
      | K_WORLD_58
      | K_WORLD_59
      | K_WORLD_60
      | K_WORLD_61
      | K_WORLD_62
      | K_WORLD_63
      | K_WORLD_64
      | K_WORLD_65
      | K_WORLD_66
      | K_WORLD_67
      | K_WORLD_68
      | K_WORLD_69
      | K_WORLD_70
      | K_WORLD_71
      | K_WORLD_72
      | K_WORLD_73
      | K_WORLD_74
      | K_WORLD_75
      | K_WORLD_76
      | K_WORLD_77
      | K_WORLD_78
      | K_WORLD_79
      | K_WORLD_80
      | K_WORLD_81
      | K_WORLD_82
      | K_WORLD_83
      | K_WORLD_84
      | K_WORLD_85
      | K_WORLD_86
      | K_WORLD_87
      | K_WORLD_88
      | K_WORLD_89
      | K_WORLD_90
      | K_WORLD_91
      | K_WORLD_92
      | K_WORLD_93
      | K_WORLD_94
      | K_WORLD_95
      | K_KP0
      | K_KP1
      | K_KP2
      | K_KP3
      | K_KP4
      | K_KP5
      | K_KP6
      | K_KP7
      | K_KP8
      | K_KP9
      | K_KP_PERIOD
      | K_KP_DIVIDE
      | K_KP_MULTIPLY
      | K_KP_MINUS
      | K_KP_PLUS
      | K_KP_ENTER
      | K_KP_EQUALS
      | K_UP
      | K_DOWN
      | K_RIGHT
      | K_LEFT
      | K_INSERT
      | K_HOME
      | K_END
      | K_PAGEUP
      | K_PAGEDOWN
      | K_F1
      | K_F2
      | K_F3
      | K_F4
      | K_F5
      | K_F6
      | K_F7
      | K_F8
      | K_F9
      | K_F10
      | K_F11
      | K_F12
      | K_F13
      | K_F14
      | K_F15
      | K_NUMLOCK
      | K_CAPSLOCK
      | K_SCROLLLOCK
      | K_RSHIFT
      | K_LSHIFT
      | K_RCTRL
      | K_LCTRL
      | K_RALT
      | K_LALT
      | K_RMETA
      | K_LMETA
      | K_LSUPER
      | K_RSUPER
      | K_MODE
      | K_COMPOSE
      | K_HELP
      | K_PRINT
      | K_SYSREQ
      | K_BREAK
      | K_MENU
      | K_POWER
      | K_EURO ];
    (* SDLMod enum *)
    type key_mod =
      [ KMOD_NONE
      | KMOD_LSHIFT
      | KMOD_RSHIFT
      | KMOD_LCTRL
      | KMOD_RCTRL
      | KMOD_LALT
      | KMOD_RALT
      | KMOD_LMETA
      | KMOD_RMETA
      | KMOD_NUM
      | KMOD_CAPS
      | KMOD_MODE
      | KMOD_RESERVED ];
(*     external enable_unicode : que_dis_ena -> off_on = *)
      "sdlstub_enable_unicode";
    value default_repeat_delay = 500
    and default_repeat_interval = 30;
(*     external enable_key_repeat : int -> int -> unit = "sdlstub_enable_key_repeat"; *)
    external get_mod_state : unit -> list key_mod = "sdlstub_get_mod_state";
    external set_mod_state : list key_mod -> unit = "sdlstub_set_mod_state";
    external get_key_name : key -> string = "sdlstub_get_key_name";
    type press_release = [ RELEASED | PRESSED ];
(*     type lost_gained = [ LOST | GAINED ]; *)
(*     type active_event = { focus : lost_gained; state : app_state }; *)
    type keyboard_event =
      { keystate : press_release; scancode : int; sym : key;
        modifiers : list key_mod; unicode : int
      };
    type mouse_button = [ LEFT | MIDDLE | RIGHT | WHEELUP | WHEELDOWN ];
    type mouse_motion_event =
      { mousestate : press_release; mx : int; my : int; mxrel : int;
        myrel : int
      };
    type mouse_button_event =
      { mousebutton : mouse_button; buttonstate : press_release; bx : int;
        by : int
      };
    type joy_axis_event = { which_axis : int; axis : int; jvalue : int };
    type joy_ball_event =
      { which_ball : int; ball : int; jxrel : int; jyrel : int
      };
    type joy_hat_event = { which_hat : int; hat : int; hvalue : int };
    type joy_button_event =
      { which_button : int; joybutton : int; jstate : press_release
      };
    type resize_event = { w : int; h : int };
    type user_event = { code : int; data1 : pointer; data2 : pointer };
    type window_event_id = 
      [ WINDOWEVENT_SHOWN          (*< Window has been shown *)
      | WINDOWEVENT_HIDDEN         (**< Window has been hidden *)
      | WINDOWEVENT_EXPOSED        (**< Window has been exposed and should be redrawn *)
      | WINDOWEVENT_MOVED          (**< Window has been moved to data1, data2 *)
      | WINDOWEVENT_RESIZED        (**< Window size changed to data1xdata2 *)
      | WINDOWEVENT_MINIMIZED      (**< Window has been minimized *)
      | WINDOWEVENT_MAXIMIZED      (**< Window has been maximized *)
      | WINDOWEVENT_RESTORED       (**< Window has been restored to normal size and position *)
      | WINDOWEVENT_ENTER          (**< Window has gained mouse focus *)
      | WINDOWEVENT_LEAVE          (**< Window has lost mouse focus *)
      | WINDOWEVENT_FOCUS_GAINED   (**< Window has gained keyboard focus *)
      | WINDOWEVENT_FOCUS_LOST     (**< Window has lost keyboard focus *)
      | WINDOWEVENT_CLOSE           (*< The window manager requests that *)
      ];

    type window_event = {wevent: window_event_id; wdata1: int; wdata2: int};
    type sys_wm_event;
    type event =
      [ NoEvent
(*       | Active of active_event *)
      | Window of window_event
      | Key of keyboard_event
      | Motion of mouse_motion_event
      | Button of mouse_button_event
      | Jaxis of joy_axis_event
      | Jball of joy_ball_event
      | Jhat of joy_hat_event
      | Jbutton of joy_button_event
      | Resize of resize_event
      | Expose
      | Quit
      | User of user_event
      | Syswm of sys_wm_event ];
    (* Event functions *)
    external pump_events : unit -> unit = "sdlstub_pump_events";
    external poll_event : unit -> event = "sdlstub_poll_event";
    external wait_event : unit -> event = "sdlstub_wait_event";
  end;
(***************************** End Events. *************************************************)
(***************************** Timer. ******************************************************)
module Timer =
  struct
    external get_ticks : unit -> int = "sdlstub_get_ticks";
    external delay : int -> unit = "sdlstub_delay";
  end;
(***************************** End Timer. ******************************************************)
(****************************** Audio ****************************)
(* low-level audio. *)
module Audio =
  struct
    type sample_type =
      [ U8 | S8 | U16 | S16 | U16LSB | S16LSB | U16MSB | S16MSB ];
    type audio_status = [ STOPPED | PAUSED | PLAYING | UNKNOWN ];
    type channel_type = [ MONO | STEREO ];
    type audio_spec =
      { frequency : int; format : sample_type; channels : channel_type;
        silence : int; samples : int; size : int
      };
    value rec int_of_sampletype t =
      match t with
      [ U8 -> 0x0008
      | (* Unsigned 8-bit samples *) S8 -> 0x8008
      | (* Signed 8-bit samples *) U16LSB -> 0x0010
      | (* Unsigned 16-bit samples *) S16LSB -> 0x8010
      | (* Signed 16-bit samples *) U16MSB -> 0x1010
      | (* As above, but big-endian byte order *) S16MSB -> 0x9010
      | (* As above, but big-endian byte order *) U16 ->
          int_of_sampletype U16LSB
      | S16 -> int_of_sampletype S16LSB ];
    value sampletype_of_int i =
      match i with
      [ 0x0008 -> U8
      | 0x8008 -> S8
      | 0x0010 -> U16LSB
      | 0x8010 -> S16LSB
      | 0x1010 -> U16MSB
      | 0x9010 -> S16MSB
      | _ -> raise (SDL_failure "Unknown sample format") ];
    value int_of_channel t = match t with [ MONO -> 1 | STEREO -> 2 ];
    value channel_of_int i =
      match i with
      [ 1 -> MONO
      | 2 -> STEREO
      | _ -> raise (SDL_failure "Unknown channel format") ];
    value mix_maxvolume = 128;
    external proto_open_audio :
      int -> int -> int -> int -> (int * int * int * int * int * int) =
      "sdlstub_open_audio";
    value open_audio a callback =
      (Callback.register "ml_setaudiocallback" callback;
       let (fr, fo, ch, si, sa, sz) =
         proto_open_audio a.frequency (int_of_sampletype a.format)
           (int_of_channel a.channels) a.samples;
       {
         frequency = fr;
         format = sampletype_of_int fo;
         channels = channel_of_int ch;
         silence = si;
         samples = sa;
         size = sz;
       });
    external close_audio : unit -> unit = "sdlstub_close_audio";
    external lock_audio : unit -> unit = "sdlstub_lock_audio";
    external unlock_audio : unit -> unit = "sdlstub_unlock_audio";
    external pause_audio : bool -> unit = "sdlstub_pause_audio";
    external proto_get_audio_status : unit -> int =
      "sdlstub_get_audio_status";
    external proto_load_wav :
      string -> (int * int * int * int * int * int * byte_array) =
      "sdlstub_load_wav";
    value get_audio_status () =
      let r = proto_get_audio_status ()
      in
        if r = 0
        then STOPPED
        else if r = 1 then PAUSED else if r = 2 then PLAYING else UNKNOWN;
    value load_wav file =
      let (fr, fo, ch, si, sa, sz, buf) = proto_load_wav file
      in
        ({
           frequency = fr;
           format = sampletype_of_int fo;
           channels = channel_of_int ch;
           silence = si;
           samples = sa;
           size = sz;
         }, buf);
    external free_wav : byte_array -> unit = "sdlstub_free_wav";
    external mix_audio : byte_array -> byte_array -> int -> unit =
      "sdlstub_mix_audio";
    external proto_convert_audio :
      int -> int -> int -> int -> int -> int -> byte_array -> byte_array = "sdlstub_convert_audio_byte" "sdlstub_convert_audio";
    value convert_audio f_fmt f_ch f_fr fmt ch fr ain =
      proto_convert_audio (int_of_sampletype f_fmt) (int_of_channel f_ch)
        f_fr (int_of_sampletype fmt) (int_of_channel ch) fr ain;
    external proto_fx_pan :
      float -> float -> byte_array -> byte_array -> unit = "fxstub_pan";
    value fx_pan pan volume sample =
      (lock_audio ();
       let len = Bigarray.Array1.dim sample;
       let newsample =
         Bigarray.Array1.create Bigarray.int8_unsigned Bigarray.c_layout len;
       proto_fx_pan pan volume sample newsample;
       unlock_audio ();
       newsample);
    external proto_fx_shift : float -> byte_array -> byte_array -> int =
      "fxstub_shift";
    value fx_shift pitch sample =
      (lock_audio ();
       let p =
         if pitch < 0.1 then 0.1 else if pitch > 10.0 then 10.0 else pitch;
       let len = float_of_int (Bigarray.Array1.dim sample);
       let newsample =
         Bigarray.Array1.create Bigarray.int8_unsigned Bigarray.c_layout
           (int_of_float (len /. p));
       let _ = proto_fx_shift p sample newsample;
       unlock_audio ();
       newsample);
  end;
(****************************** End Audio ****************************)
(**********************************  Extra SDL-related but non-SDL core routines *******************************)
(**************************** Draw ************************** *)
module Draw =
  struct
    exception TGA_failure of string;
    exception Sfont_failure of string;
    type filter =
      [ BOX of int
      | TRIANGLE of int
      | BELL of int
      | BSPLINE of int
      | HERMITE of int
      | MITCHELL of int
      | LANCZOS3 of int ];
    value box = BOX 1;
    value triangle = TRIANGLE 2;
    value bell = BELL 3;
    value bspline = BSPLINE 4;
    value hermite = HERMITE 5;
    value mitchell = MITCHELL 6;
    value lanczos3 = LANCZOS3 7;
    type sfont =
      { font_list : list (int * Video.rect); font_surf : Video.surface;
        font_space : int; font_letters : int; font_line : int
      };
    external put_pixel : Video.surface -> int -> int -> int32 -> unit =
      "sdldraw_put_pixel";
    external get_pixel : Video.surface -> int -> int -> int32 =
      "sdldraw_get_pixel";
    type tga_orientation = [ From_upper_left | From_lower_left ];
    value input_int16 ic =
      let lo = input_byte ic in let hi = input_byte ic in (hi lsl 8) lor lo;
    (*	Targa TGA image file reader, based on the specs at http://astronomy.swin.edu.au/~pbourke/dataformats/tga/
		Takes as parameter the file name and returns a tuple containing the image width, height, bytes-per-pixel
		and a string containing the image data in BGR(A) format.
		Reads 15, 16, 24 and 32 bit-per-pixel raw and RLE-compressed images.
		Throws TGA_exception when anything goes wrong. *)
    value read_tga file =
      try
        let ic = open_in_bin file in (* Read in TGA header *)
        let idlength = input_byte ic in
        let (* colourmaptype *) _ = input_byte ic in
        let datatypecode = input_byte ic in
        let (* colourmaporigin *) _ = input_int16 ic in
        let (* colourmaplength *) _ = input_int16 ic in
        let (* colourmapdepth  *) _ = input_byte ic in
        let (* x_origin *) _ = input_int16 ic in
        let (* y_origin *) _ = input_int16 ic in
        let width = input_int16 ic in
        let height = input_int16 ic in
        let bitsperpixel = input_byte ic in
        let imagedescriptor = input_byte ic in
        let rec consume_id cnt =
          if cnt > 0
          then let _ = input_byte ic in consume_id (cnt - 1)
          else ()
        in
          (consume_id idlength;
           let (* Read in TGA data *) bpp = bitsperpixel / 8;
           let len = (width * height) * bpp;
           let data = String.make len ' ';
           let rec decode_run byte pos =
             let rtype = (byte land 0x80) lsr 7
             and rlen = (byte land 0x7F) + 1 in
             let newpos = pos + (rlen * bpp)
             in
               (if rtype = 0
                then (* RAW unencoded pixels *)
                  really_input ic data pos (rlen * bpp)
                else (* Run length encoded pixels *)
                  let b = input_byte ic
                  and g = input_byte ic
                  and r = if bpp > 2 then input_byte ic else (-1)
                  and a = if bpp > 3 then input_byte ic else (-1)
                  in
                    for i = 0 to rlen - 1 do
                      String.set data ((pos + (bpp * i)) + 0) (char_of_int b);
                      String.set data ((pos + (bpp * i)) + 1) (char_of_int g);
                      if bpp > 2
                      then
                        String.set data ((pos + (bpp * i)) + 2)
                          (char_of_int r)
                      else ();
                      if bpp > 3
                      then
                        String.set data ((pos + (bpp * i)) + 3)
                          (char_of_int a)
                      else ()
                    done;
                if newpos < (String.length data)
                then decode_run (input_byte ic) newpos
                else ());
           if datatypecode = 2
           then really_input ic data 0 len
           else
             if datatypecode = 10
             then decode_run (input_byte ic) 0
             else raise (TGA_failure "Cannot decode this TGA file type");
           close_in ic;
           let orientation =
             if (imagedescriptor land 0x20) = 0
             then From_lower_left
             else From_upper_left;
           (width, height, bitsperpixel, data, orientation))
      with [ _ -> raise (TGA_failure "Unable to load TGA file") ];
    (* Returns an RGBA tuple representing the pixel in string s at position (x,y), with texturemap width w and depth bitsperpixel
	   FIXME: Only checked for 24 and 32 bpp; 15 and 16 bpp untested *)
    value get_tga_pixel s x y w bitsperpixel =
      let bpp = bitsperpixel / 8 in
      let b = int_of_char (String.get s (0 + (((y * w) + x) * bpp)))
      and g = int_of_char (String.get s (1 + (((y * w) + x) * bpp)))
      and r =
        if bitsperpixel > 16
        then int_of_char (String.get s (2 + (((y * w) + x) * bpp)))
        else 0
      and a =
        if bitsperpixel > 24
        then int_of_char (String.get s (3 + (((y * w) + x) * bpp)))
        else 1
      in
        if bitsperpixel > 16
        then (r, g, b, a)
        else
          if bitsperpixel = 15
          then
            (((r lsl 1) land 0xF8), ((r lsl 5) + ((g land 0xE0) lsr 2)),
             (g lsl 3), ((r land 0x80) lsr 7))
          else
            ((r land 0xF8), ((r lsl 5) + ((g land 0xE0) lsr 2)),
             ((g land 0x1F) lsl 3), 0);
    (* Load a TGA file and return the loaded surface. This is the only exported function. *)
    value load_tga file =
      let (w, h, bitsperpixel, s, orientation) = read_tga file in
      let surf =
        Video.create_rgb_surface [ Video.SWSURFACE ] w h bitsperpixel
      in
        (for y = 0 to h - 1 do
           let ysurf =
             match orientation with
             [ From_upper_left -> y
             | From_lower_left -> (h - 1) - y ];
           for x = 0 to w - 1 do
             let (r, g, b, a) = get_tga_pixel s x y w bitsperpixel;
             put_pixel surf x ysurf (Video.map_rgba surf r g b a)
           done
         done;
         surf);
    (* SFont texturemapped fonts based on the specifications at http://www.linux-games.com/sfont/
	A font consists of a 32bpp RGBA surface with ASCII characters from 33 to 127. The first line in
	the texturemap serves as a character delineator using the colour pink (255 0 255 255) to indicate
	the space between each character rectangle. *)
    (* Returns type sfont from a surface texturemap.*)
    value make_sfont surf =
      let ascii_start = 33 and pink = Video.map_rgba surf 255 0 255 255
      and w = Video.surface_width surf
      and h = (Video.surface_height surf) - 1 in
      let rec make_sfont_list lastpink ch x x1 x2 =
        if x >= w
        then []
        else
          let pixel = get_pixel surf x 0 in
          let ispink = pixel = pink
          in
            match (lastpink, ispink) with
            [ (True, True) -> make_sfont_list ispink ch (x + 1) x1 x2
            | (True, False) -> make_sfont_list ispink ch (x + 1) x x2
            | (False, True) ->
                [ (ch,
                   {
                     Video.rect_x = x1;
                     Video.rect_y = 1;
                     Video.rect_w = x - x1;
                     Video.rect_h = h;
                   }) ::
                  make_sfont_list ispink (ch + 1) (x + 1) x x ]
            | (False, False) -> make_sfont_list ispink ch (x + 1) x1 x2 ] in
      let l = make_sfont_list True ascii_start 0 0 0 in
      let letter_L = List.assoc (int_of_char 'L') l
      and letter_spc = List.assoc (int_of_char '!') l in
      let fs = letter_L.Video.rect_w
      and fl = letter_spc.Video.rect_w
      in
        {
          font_list = l;
          font_surf = surf;
          font_space = fs;
          font_letters = fl;
          font_line = h;
        };
    (* 	Prints string s at location [x,y] with font "font" on surface dest  *)
    value sfont_print s x y font dest =
      let offx = ref x and offy = ref y in
      let spr c =
        match c with
        [ ' ' -> offx.val := offx.val + font.font_space
        | '\n' -> (offy.val := offy.val + font.font_line; offx.val := x)
        | _ ->
            let r = List.assoc (int_of_char c) font.font_list
            in
              (Video.blit_surface font.font_surf (Some r) dest
                 (Some
                    {
                      Video.rect_x = offx.val;
                      Video.rect_y = offy.val;
                      Video.rect_w = Video.surface_width font.font_surf;
                      Video.rect_h = Video.surface_height font.font_surf;
                    });
               offx.val := (offx.val + r.Video.rect_w) + font.font_letters) ]
      in String.iter spr s;
    (******************* Bitmap scaling **********************)
    value print_array a =
      let dim = Array.length a.(0)
      in
        for i = 0 to dim - 1 do
          for j = 0 to dim - 1 do Printf.printf "%f\t" a.(i).(j) done;
          Printf.printf "\n"
        done;
    value normalize a =
      let total = ref 0.0 in
      let dim = Array.length a.(0)
      in
        (for i = 0 to dim - 1 do
           for j = 0 to dim - 1 do total.val := total.val +. a.(i).(j) done
         done;
         for i = 0 to dim - 1 do
           for j = 0 to dim - 1 do a.(i).(j) := a.(i).(j) /. total.val done
         done;
         a);
    value dist x y dim =
      let x2 = (float_of_int x) -. ((float_of_int dim) /. 2.0)
      and y2 = (float_of_int y) -. ((float_of_int dim) /. 2.0)
      in sqrt ((x2 *. x2) +. (y2 *. y2));
    value box_filter dim = normalize (Array.make_matrix dim dim 1.0);
    value tent_filter dim =
      let t = dist dim dim dim in
      let f x = (t -. (abs_float x)) /. t in
      let a = Array.make_matrix (dim + 1) (dim + 1) 0.0
      in
        (for i = 0 to dim do
           for j = 0 to dim do a.(i).(j) := f (dist i j dim) done
         done;
         normalize a);
    value lanczos3_filter dim =
      let f x =
        if (abs_float x) > 3.0
        then 0.0
        else
          let pi = 4.0 *. (atan 1.0) in
          let pix' = pi *. x in
          let pix = if (abs_float pix') > 0.1 then pix' else 0.1 in
          let pix3 = pix /. 3.0 in ((sin pix) /. pix) *. ((sin pix3) /. pix3) in
      let a = Array.make_matrix (dim + 1) (dim + 1) 0.0 in
      let dim2 = dist dim dim dim
      in
        (for i = 0 to dim do
           for j = 0 to dim do
             a.(i).(j) := f (((dist i j dim) *. 3.0) /. dim2)
           done
         done;
         normalize a);
    value create_filter filter dim =
      if filter = box
      then box_filter dim
      else
        if filter = triangle
        then tent_filter dim
        else lanczos3_filter (dim + 4);
    value round f = int_of_float (f +. 0.5);
    value pixel_round f =
      let c = round f in if c > 255 then 255 else if c < 0 then 0 else c;
    value convolute kernel s x y =
      let r = ref 0.0 and g = ref 0.0 and b = ref 0.0 and a = ref 0.0 in
      let h = Video.surface_height s and w = Video.surface_width s in
      let len = Array.length kernel.(0) in
      let halflen = len / 2
      in
        (for i = ((x + halflen) - len) + 1 to x + halflen do
           for j = ((y + halflen) - len) + 1 to y + halflen do
             let k = i - (((x + halflen) - len) + 1);
             let l = j - (((y + halflen) - len) + 1);
             let x' = if i >= 0 then if i < w then i else w - 1 else 0;
             let y' = if j >= 0 then if j < h then j else h - 1 else 0;
             let p = get_pixel s x' y';
             let (r', g', b', a') = Video.get_rgba s p;
             r.val := r.val +. ((float_of_int r') *. kernel.(k).(l));
             g.val := g.val +. ((float_of_int g') *. kernel.(k).(l));
             b.val := b.val +. ((float_of_int b') *. kernel.(k).(l));
             a.val := a.val +. ((float_of_int a') *. kernel.(k).(l))
           done
         done;
         Video.map_rgba s (pixel_round r.val) (pixel_round g.val)
           (pixel_round b.val) (pixel_round a.val));
    value scale_to s w h filter =
      let t =
        Video.create_rgb_surface [ Video.SWSURFACE ] w h
          (Video.surface_bpp s) in
      let w' = Video.surface_width s and h' = Video.surface_height s in
      let fw = (float_of_int w') /. (float_of_int w)
      and fh = (float_of_int h') /. (float_of_int h) in
      let dim = if fw > 1.0 then fw else 1.0 /. fw in
      let filter' = create_filter filter (round dim)
      in
        (for i = 0 to (Video.surface_width t) - 1 do
           for j = 0 to (Video.surface_height t) - 1 do
             let si = (float_of_int i) *. fw
             and sj = (float_of_int j) *. fh;
             let p = convolute filter' s (int_of_float si) (int_of_float sj);
             put_pixel t i j p
           done
         done;
         t);
    value scale s f filter =
      let w' = Video.surface_width s
      and h' = Video.surface_height s
      in
        scale_to s (int_of_float ((float_of_int w') *. f))
          (int_of_float ((float_of_int h') *. f)) filter;
    (* Takes in an  Sdl.surface and a filter (type Sdl.Draw.t_filter) as argument, and returns an array of rectangular 
	   bitmaps with the sides' dimension a power of two. The largest bitmap is at offset 0, the
	   smallest at n - 1. If the original bitmap is square and the length of the sides are a power of two
	   then it will be placed unchanged into offset 0, else the bitmap will be resized to the closest
	   suitable size and that wil be used as the base *)
    value make_mipmaps s filter =
      let p2 n =
        let rec p2' n i = if n <= 1 then i else p2' (n / 2) (i + 1)
        in p2' n 0 in
      let rec int_exp m e =
        if e < 0 then 0 else if e = 0 then 1 else m * (int_exp m (e - 1)) in
      let closest_power_of_2 n =
        let i = p2 n in
        let min = int_exp 2 i
        and max = int_exp 2 (i + 1)
        in if (n - min) < (max - n) then min else max in
      let w = Video.surface_width s and h = Video.surface_height s in
      let dimx' = w and dimy' = h in
      let dimx = closest_power_of_2 dimx'
      and dimy = closest_power_of_2 dimy' in
      let dim = if dimx > dimy then dimx else dimy in
      let s2 =
        if (w = dimx) && (h = dimy) then s else scale_to s dimx dimy filter in
      let num = (p2 dim) + 1 in
      let mipmaps = Array.make num s2
      in
        (for i = 1 to num - 1 do
           let dimx'' = dimx / (int_exp 2 i)
           and dimy'' = dimy / (int_exp 2 i);
           mipmaps.(i) := scale_to s dimx'' dimy'' filter
         done;
         mipmaps);
  end;

