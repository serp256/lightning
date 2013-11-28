open LightCommon;

external glow_make: RenderTexture.framebuffer -> Filters.glow -> unit = "ml_glow_make";
external glow2_make: RenderTexture.framebuffer -> Filters.glow -> unit = "ml_glow2_make";
(* external shadow_make: RenderTexture.framebuffer -> Filters.shadow -> unit = "ml_shadow_make"; *)