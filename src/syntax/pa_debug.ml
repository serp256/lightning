

module Id = struct
  value name    = "Pa Debug";
  value version = "1.0";
end;

value debug = ref True;

module MakeFilter (AstFilters : Camlp4.Sig.AstFilters) = struct
  open AstFilters;
  open Ast;

  let log_replacer = (*Ast.map_expr begin fun e -> *)
    object
      inherit Ast.map as super;
      method! expr e = 
        let rec deep_check = fun
          [ <:expr<Debug.$lid:f$>> when f = "e" || f = "w" || f = "d" || f = "fail" -> `True f
          |  Ast.ExApp (_loc,e,_) -> deep_check e
          | _ -> `False
          ]
        in
        let _loc = Ast.loc_of_expr e in
        match deep_check e with
        [ `True x ->
            if (not !debug) && (x = "d" )
            then <:expr<()>>
            else
              (Ast.map_expr begin fun 
                [ <:expr<Debug.$lid:_$>> as e-> 
                    <:expr<$e$ $str:Loc.file_name _loc$ $`int:Loc.start_line _loc$>>
                | x -> x
                ]
              end)#expr e
        | `False -> super#expr e
        ];
    end 
  in
  AstFilters.register_str_item_filter log_replacer#str_item;

end;


let module M = Camlp4.Register.AstFilter Id MakeFilter in ();




module MakeParser (Syntax : Camlp4.Sig.Camlp4Syntax) = struct
  open Camlp4.Sig;
  include Syntax;

  value rec conv_expr = fun
    [ Ast.ExApp _loc e p -> Ast.ExApp _loc (conv_expr e) p
    | Ast.ExStr _loc s -> <:expr<Debug.d $str:s$>>
    | e -> e
    ];

  value enabled_labels: Hashtbl.t string bool = Hashtbl.create 0;
  value enable_label l = Hashtbl.add enabled_labels l True;
  value disable_label l = Hashtbl.remove enabled_labels l; 

  value check l =
    try
      Hashtbl.find enabled_labels l
    with 
    [ Not_found -> False ];


  EXTEND Gram 


    sig_item:
      [
        [ "DEBUG"; l = OPT [ ":" ; l = a_LIDENT -> l ] ; items = sig_items ; els = OPT [ "ELSE" ; items = sig_items -> items ] ; "END" -> 
          let els = match els with [ Some e -> e | None -> <:sig_item<>> ] in
          if !debug 
          then
            let label = match l with [ Some l -> l | None -> "default" ] in
            match check label with
            [ True -> items
            | False -> els
            ]
          else <:sig_item<>>
        ]
      ];

    str_item: 
      [ 
        [ "DEBUG"; l = OPT [ ":" ; l = a_LIDENT -> l ] ; items = str_items ; els = OPT [ "ELSE" ; items = str_items -> items ] ; "END" -> 
          let els = 
            match els with
            [ None -> <:str_item< >>
            | Some items -> items
            ]
          in
          if !debug 
          then
            let label = match l with [ Some l -> l | None -> "default" ] in
            match check label with
            [ True -> items
            | False -> els
            ]
          else els
        ] 
      ];

    expr: 
      [ 
        [ "debug" ; l = OPT [ ":" ; l = a_LIDENT -> l ]; expr = SELF ; els = OPT [ "else" ; e = expr -> e ] -> 
          let els_expr = fun
            [ None -> <:expr<()>>
            | Some e -> e
            ]
          in
          if !debug 
          then 
            let expr = conv_expr expr in
            let (label,expr) = 
              match l with 
              [ Some label -> (label, (Ast.map_expr (fun [ <:expr<Debug.d>> -> <:expr<Debug.d ~l:$str:label$>> | e -> e ]))#expr expr) 
              | None -> ("default",expr) 
              ] 
            in
            match check label with
            [ True -> expr
            | False -> els_expr els
            ]
          else els_expr els
        ]
      ];

    match_case0:
      [
        [ "debug" ; l = OPT [ ":" ; l = a_LIDENT -> l ] ; mc = SELF ->
          if !debug 
          then
            let label = match l with [ Some l -> l | None -> "default" ] in
            match check label with
            [ True -> mc
            | False -> <:match_case< >>
            ]
          else <:match_case< >>
        ]
      ];

  END;


  Camlp4.Options.add "-disable-all-debugs" (Arg.Set debug) "Disable all debug actions and logs";
  Camlp4.Options.add "-enable-debug" (Arg.String enable_label) "Enable debug label";
  Camlp4.Options.add "-disable-debug" (Arg.String disable_label) "Disable debug label";

end;

module M = Camlp4.Register.OCamlSyntaxExtension Id MakeParser;
