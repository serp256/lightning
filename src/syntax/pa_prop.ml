


open Camlp4;
open Camlp4.PreCast;
open Syntax;


let map_prop = 
  object
    inherit Ast.map as super;
    method! expr e =
      match super#expr e with
      [ <:expr@_loc< $lid:obj$ # $lid:meth$ >> when String.length meth > 5 && String.sub meth 0 5 = "prop'" -> 
          let p = String.sub meth 5 ((String.length meth) - 5) in
          <:expr< ( fun () -> $lid:obj$#$lid:p$ , $lid:obj$#$lid:"set" ^ (String.capitalize p)$ ) >>
      | e -> e
      ];

  end
in

AstFilters.register_str_item_filter map_prop#str_item;
