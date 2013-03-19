module Id = struct
  value name    = "Pa Platform";
  value version = "1.0";
end;


value platform = 
  IFDEF PC
  THEN "pc"
  ELSE
    IFDEF IOS
    THEN "ios"
    ELSE
      IFDEF ANDROID
      THEN "android"
      ELSE "unknown"
      ENDIF
    ENDIF
  ENDIF;


module MakeParser (Syntax : Camlp4.Sig.Camlp4Syntax) = struct
  open Camlp4.Sig;
  include Syntax;

  EXTEND Gram 
    GLOBAL: sig_item str_item expr match_case0;

    sig_item:
      [
        [ "IFPLATFORM" ; "(" ; platforms = LIST1 a_LIDENT ; ")" ; items = sig_items ; els = OPT els_platform_sig ; "ENDPLATFORM" -> 
            let els = 
              match els with
              [ None -> <:sig_item< >>
              | Some els -> els 
              ]
            in
            if List.mem platform platforms
            then items
            else els
        ] 
      ];

    els_platform_sig: 
      [
        [ "ELSPLATFORM"; "(" ; platforms = LIST1 a_LIDENT; ")" ; items = sig_items ; els = OPT els_platform_sig ->
          let els =
            match els with
            [ None -> <:sig_item< >>
            | Some els -> els
            ]
          in
          if List.mem platform platforms then items else els
        | "ELSE" ; items = sig_items -> items
        ] 
      ];

    str_item: 
      [ 
        [ "IFPLATFORM" ; "(" ; platforms = LIST1 a_LIDENT ; ")" ; items = str_items ; els = OPT els_platform ; "ENDPLATFORM" -> 
            let els = 
              match els with
              [ None -> <:str_item< >>
              | Some els -> els 
              ]
            in
            if List.mem platform platforms
            then items
            else els
        ] 
      ];

    els_platform: 
      [
        [ "ELSPLATFORM"; "(" ; platforms = LIST1 a_LIDENT; ")" ; items = str_items ; els = OPT els_platform ->
          let els =
            match els with
            [ None -> <:str_item< >>
            | Some els -> els
            ]
          in
          if List.mem platform platforms then items else els
        | "ELSE" ; items = str_items -> items
        ] 
      ];


    expr: 
      [ 
        [ "ifplatform" ; "(" ; platforms = LIST1 a_LIDENT; ")" ; expr = SELF; els = OPT els_platform_expr ->
          let els = match els with [ None -> <:expr<()>> | Some els -> els ] in
          if List.mem platform platforms then expr else els
        ]
      ];

    els_platform_expr:
      [ ["elsplatform" ; "(" ; platforms = LIST1 a_LIDENT ; ")" ; expr = expr ; els = OPT SELF ->
          let els = match els with [ None -> <:expr<()>> | Some els -> els ] in
          if List.mem platform platforms then expr else els
        | "else" ; e = expr -> e
        ]
      ];

  END;

end;

module M = Camlp4.Register.OCamlSyntaxExtension Id MakeParser;
