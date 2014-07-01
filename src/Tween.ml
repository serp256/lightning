open LightCommon;


module Transitions = struct

  type t = float -> float;

  type kind = 
    [= `linear 
    | `easeIn | `easeOut | `easeInOut | `easeOutIn 
    | `easeInBack | `easeOutBack | `easeInOutBack | `easeOutInBack 
    | `easeInElastic | `easeOutElastic | `easeInOutElastic | `easeOutInElastic
    | `easeInBounce | `easeOutBounce | `easeInOutBounce | `easeOutInBounce
    | `transitionFun of t
    ];

  value linear ratio = ratio;
  value easeIn ratio = ratio *. ratio *. ratio;
  value easeOut ratio = 
    let invRatio = ratio -. 1. in
    invRatio *. invRatio *. invRatio +. 1.;

  value easeInOut ratio = 
    if ratio < 0.5
    then 0.5 *. easeIn (ratio *. 2.)
    else 0.5 *. easeOut ((ratio -. 0.5) *. 2.) +. 0.5;

  value easeOutIn ratio = 
    if ratio < 0.5
    then 0.5 *. (easeOut (ratio *. 2.))
    else 0.5 *. (easeIn ((ratio -. 0.5) *. 2.)) +. 0.5;

(*   value s = 1.70158; *)

  value easeInBack ratio = (ratio *. ratio) *. (2.70158 *. ratio -. 1.70158);

  value easeOutBack ratio =
    let invRatio = ratio -. 1.0 in
    (invRatio *. invRatio) *. (2.70158 *. invRatio +. 1.70158) +. 1.0;

  value easeInOutBack ratio =
    if ratio < 0.5
    then 0.5 *. (easeInBack (ratio *. 2.0))
    else 0.5 *. (easeOutBack (ratio -. 0.5) *. 2.0) +. 0.5;

  value easeOutInBack ratio =
    if ratio < 0.5
    then 0.5 *. (easeOutBack (ratio*.2.0))
    else 0.5 *. (easeInBack (ratio-.0.5)*.2.0) +. 0.5;

  value easeInElastic ratio =
    if ratio = 0.0 || ratio = 1.0 
    then ratio
    else
(*         float p = 0.3f; *)
(*         float s = p / 4.0f; *)
        let invRatio = ratio -. 1.0 in
        ~-.((2.0 ** (10. *. invRatio)) *. sin ((invRatio -. 0.075) *. two_pi /. 0.3));

  value easeOutElastic ratio = 
    if ratio = 0. || ratio = 1.0
    then ratio
    else
      (2.0 ** (~-.10. *. ratio)) *. sin ( (ratio -. 0.075) *. two_pi /. 0.3) +. 1.;


  value easeInOutElastic ratio = 
    if ratio < 0.5
    then 0.5 *. (easeInElastic (ratio *. 2.0))
    else 0.5 *. (easeOutElastic ((ratio -. 0.5) *. 2.0)) +. 0.5;

  value easeOutInElastic ratio = 
    if ratio < 0.5
    then 0.5 *. (easeOutElastic (ratio *. 2.0))
    else 0.5 *. (easeInElastic ((ratio -. 0.5) *. 2.0)) +. 0.5;


  value easeOutBounce ratio =
(*     float s = 7.5625f; *)
(*     float p = 2.75f; *)
(*     float l; *)
    if ratio < 0.363636363636
    then 7.5625 *. (ratio *. ratio)
    else
        if ratio < 0.727272727273 
        then
          let ratio = ratio -. 0.545454545455 in
          7.5625 *. (ratio *. ratio) +. 0.75
        else
          if ratio <  0.909090909091
          then
            let ratio = ratio -. 0.818181818182 in
            7.5625 *. (ratio *. ratio) +. 0.9375
          else
            let ratio = ratio -. 0.954545454545 in
            7.5625 *. (ratio *. ratio) +. 0.984375
  ;

  value easeInBounce ratio = 1.0 -. (easeOutBounce (1.0 -. ratio));

  value easeInOutBounce ratio =
    if ratio < 0.5
    then 0.5 *. (easeInBounce (ratio *. 2.0))
    else 0.5 *. (easeOutBounce ((ratio -. 0.5) *. 2.0)) +. 0.5;

  value easeOutInBounce ratio =
    if ratio < 0.5
    then 0.5 *. (easeOutBounce (ratio *. 2.0))
    else 0.5 *. (easeInBounce ((ratio -. 0.5) *. 2.0)) +. 0.5;

  value get : kind -> t = fun 
    [ `linear -> linear
    | `easeIn -> easeIn
    | `easeOut -> easeOut
    | `easeInOut -> easeInOut
    | `easeOutIn -> easeOutIn
    | `easeInBack -> easeInBack
    | `easeOutBack -> easeOutBack
    | `easeInOutBack -> easeInOutBack
    | `easeOutInBack -> easeOutInBack
    | `easeInElastic -> easeInElastic
    | `easeOutElastic -> easeOutElastic
    | `easeInOutElastic -> easeInOutElastic
    | `easeOutInElastic -> easeOutInElastic
    | `easeInBounce -> easeInBounce
    | `easeOutBounce -> easeOutBounce
    | `easeInOutBounce -> easeInOutBounce
    | `easeOutInBounce -> easeOutInBounce
    | `transitionFun f -> f
    ];

end;


type action = 
  {
    startValue: mutable float;
    endValue:   mutable float;
    getValue: unit -> float;
    setValue: float -> unit;
  };

type loop = [= `LoopNone | `LoopRepeat | `LoopReverse ];
type prop = ((unit -> float) * (float -> unit));

class c ?(delay=0.) ?(repeat=(-1)) ?(transition=`linear) ?(loop=`LoopNone) time = 
  object(self)

    value mutable actions = [];
    value mutable currentTime = 0.;
    value totalTime = time;
    value loop: loop = loop; 
    value transition = Transitions.get transition;
    value mutable invertTransition = False;
    value mutable onComplete = None;
    value mutable start = True;
    value mutable delay = delay;
    value mutable repeat=repeat;

    method animate (getValue,setValue) endValue = actions := [ {startValue = 0.; endValue; getValue ; setValue}  :: actions ];
    method setOnComplete f = onComplete := Some f;

    method reset () = 
    (
      debug "assign currentTime 5";
      currentTime := 0.;
      invertTransition := False;
    );

    method process dt = 
(*       let () = Printf.eprintf "tween process %F\n%!" dt in *)
      let isDelay =
        (
          debug "assign currentTime 1 %f %f %f" delay currentTime dt;
          currentTime := currentTime +. dt;
          match delay > currentTime with
          [ True -> True
          | _ -> 
              (
                debug "assign currentTime 2";
                currentTime := min totalTime (currentTime -. delay);
                delay := 0.;
                False 
              )
          ]
        )
      in
      match isDelay with
      [ True -> True
      | _ ->  
          (
            let () = debug "currentTime %f totalTime %f" currentTime totalTime in
            let ratio = currentTime /. totalTime in
              (
                List.iter begin fun action ->
                  (
                    match start with
                    [ True -> action.startValue := action.getValue ()
                    | _ -> ()
                    ];
                    let delta = action.endValue -. action.startValue in
                    let transitionValue = transition ratio in
                    let () = debug "ratio: %f, transitionValue: %f" ratio transitionValue in
                    (*
                      match invertTransition with
                      [ True -> 1. -. (transition (1. -. ratio))
                      | False -> transition ratio
                      ]
                    in
                    *)
                    action.setValue (action.startValue +. delta *. transitionValue)
                  )
                end actions;
                start := False;
                if ratio >= 1.  
                then
                  match loop with
                  [ `LoopRepeat -> 
                    (
                      List.iter (fun action -> action.setValue (action.getValue ())) actions;
                      debug "assign currentTime 3";
                      currentTime := 0.;
                      match repeat with
                      [ 0 -> 
                          (
                            match onComplete with
                            [ Some f -> f ()
                            | None -> ()
                            ];
                            False
                          )
                      | r when r > 0 -> 
                          (
                            repeat := repeat - 1;
                            True
                          )
                      | _ -> True
                      ]
                    )
                  | `LoopReverse -> 
                    (
                      List.iter begin fun action ->
                        (
                          action.setValue action.endValue;
                          let endv = action.endValue in
                            (
                              action.endValue := action.startValue;
                              action.startValue := endv;
                            );
                            (*
                          invertTransition := not invertTransition;
                            *)
                        )
                      end actions;
                      debug "assign currentTime 4";
                      currentTime := 0.;
                      match repeat with
                      [ 0 ->
                          (
                            match onComplete with
                            [ Some f -> f ()
                            | None -> ()
                            ];
                            False
                          )
                      | r when r > 0 -> 
                          (
                            repeat := repeat - 1;
                            True
                          )
                      | _ -> True
                      ]
                    )
                  | _ -> 
                    (
                      match onComplete with
                      [ Some f -> f ()
                      | None -> ()
                      ];
                      False (* it's completed *)
                    )
                  ]
                else True
              )
          )
      ];

  end;


value create = new c;
