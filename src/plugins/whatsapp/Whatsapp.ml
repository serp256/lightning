IFPLATFORM(android ios)
external installed: unit -> bool = "ml_whatsapp_installed";
external text: string -> bool = "ml_whatsapp_text";
external picture: string -> bool = "ml_whatsapp_picture";
ELSE
value installed () = False;
value text txt = False;
value picture pic = False;
ENDPLATFORM;
