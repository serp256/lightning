
module EmptyHashed =
struct
  type t = < >;
  value equal = (=);
  value hash = Hashtbl.hash;
end;

include (Weak.Make EmptyHashed);
