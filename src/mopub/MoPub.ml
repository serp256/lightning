


type load_result = [= `success | `failed of string ];

module Banner = struct

  type t;
  external create: string -> (t -> unit) -> unit = "ml_createMoPubBanner";
  external load: t -> (load_result -> unit) -> unit = "ml_loadMoPubBanner";
  external show: t -> unit = "ml_showMoPubBanner";
  external hide: t -> unit = "ml_hideMoPubBanner";
  (* еще нужен какой-то класс для выставления его геометрии - позиции *)
  external destroy: t -> unit = "ml_destroyMoPubBanner";
end;

module Interstitial = struct
  type t;
  external create: string -> (t -> unit) -> unit = "ml_createMoPubInterstitial";
  external load: t -> (load_result -> unit) -> unit = "ml_loadMoPubInterstitial";
  external show: t -> (unit -> unit) -> unit = "ml_showMoPubInterstitial";
  external destroy: t -> unit = "ml_destroyMoPubInterstitial";
end;
