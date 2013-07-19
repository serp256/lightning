IFPLATFORM(android)
external text: string -> bool = "ml_whatsapp_text";
external picture: string -> bool = "ml_whatsapp_picture";
ELSE
value text txt = False;
value picture pic = False;
ENDPLATFORM;