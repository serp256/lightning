(* Decoding -------------------------------------------------- *)
exception Hex_of_char;
value hex_of_char =
  let code_a = (Char.code 'a') - 10
  and code_A = (Char.code 'A') - 10
  in
    fun
    [ ('0' .. '9' as c) -> (Char.code c) - (Char.code '0')
    | ('a' .. 'f' as c) -> (Char.code c) - code_a
    | ('A' .. 'F' as c) -> (Char.code c) - code_A
    | _ -> raise Hex_of_char ];
(* Overwrite the part of the range [s.[i0 .. up-1]] with the decoded
   string.  Returns [i] such that [s.[i0 .. i]] is the decoded
   string.  Invalid '%XX' are left unchanged.  *)
value rec decode_range_loop plus i0 i up s =
  if i0 >= up
  then i
  else
    match String.unsafe_get s i0 with
    [ '+' ->
        (String.unsafe_set s i plus;
         decode_range_loop plus (succ i0) (succ i) up s)
    | '%' when (i0 + 2) < up ->
        let i1 = succ i0 in
        let i2 = succ i1 in
        let i0_next =
          try
            let v =
              ((hex_of_char (String.unsafe_get s i1)) lsl 4) +
                (hex_of_char (String.unsafe_get s i2))
            in (String.unsafe_set s i (Char.chr v); succ i2)
          with [ Hex_of_char -> (String.unsafe_set s i '%'; i1) ]
        in decode_range_loop plus i0_next (succ i) up s
    | c ->
        (String.unsafe_set s i c;
         decode_range_loop plus (succ i0) (succ i) up s) ];
(* We do not strip heading and trailing spaces of key-value data
   because it does not conform the specs.  However certain browsers
   do it, so the user should not rely on them.  See e.g.
   https://bugzilla.mozilla.org/show_bug.cgi?id=114997#c6 *)
value decode ?(plus = True) ?(pos = 0) ?len s =
  let real_len =
    match len with [ None -> (String.length s) - pos | Some l -> l ] in
  let s = String.sub s pos real_len in
  let up = decode_range_loop (if plus then ' ' else '+') 0 0 real_len s
  in if up <> real_len then String.sub s 0 up else s;
(* Query parsing -------------------------------------------------- *)
(* It is ASSUMED that the range is valid i.e., [0 <= low] and [up <=
   String.length s].  *)
value decode_range s low up =
  if low >= up
  then ""
  else
    let len = up - low in
    let s = String.sub s low len in
    let up = decode_range_loop ' ' 0 0 len s
    in if up <> len then String.sub s 0 up else s;
(* Split the query string [qs] into a list of pairs (key,value).
   [i0] is the initial index of the key or value, [i] the current
   index and [up-1] the last index to scan. *)
value rec get_key qs i0 i up =
  if i >= up
  then [ ((decode_range qs i0 up), "") ]
  else
    match String.unsafe_get qs i with
    [ '=' -> get_val qs (i + 1) (i + 1) up (decode_range qs i0 i)
    | '&' -> (* key but no val *)
        [ ((decode_range qs i0 i), "") :: get_key qs (i + 1) (i + 1) up ]
    | _ -> get_key qs i0 (i + 1) up ]
and get_val qs i0 i up key =
  if i >= up
  then [ (key, (decode_range qs i0 up)) ]
  else
    match String.unsafe_get qs i with
    [ '&' ->
        [ (key, (decode_range qs i0 i)) :: get_key qs (i + 1) (i + 1) up ]
    | _ -> get_val qs i0 (i + 1) up key ];
value dest_url_encoded_parameters qs =
  if qs = "" then [] else get_key qs 0 0 (String.length qs);
(* Encoding -------------------------------------------------- *)
value hex =
  [| '0'; '1'; '2'; '3'; '4'; '5'; '6'; '7'; '8'; '9'; 'A'; 'B'; 'C'; 'D';
    'E'; 'F'
  |];
value char_of_hex i = Array.get (*unsafe_*) hex i;
value encode_wrt is_special s0 =
  let len = String.length s0 in
  let encoded_length = ref len
  in
    (for i = 0 to len - 1 do
       if is_special (String.unsafe_get s0 i)
       then encoded_length.val := encoded_length.val + 2
       else ()
     done;
     let s = String.create encoded_length.val;
     let rec do_enc i0 i = (* copy the encoded string in s *)
       if i0 < len
       then
         let s0i0 = String.unsafe_get s0 i0
         in
           (* It is important to check first that [s0i0] is special in
   case [' '] is considered as such a character. *)
           if is_special s0i0
           then
             let c = Char.code s0i0 in
             let i1 = succ i in
             let i2 = succ i1
             in
               (String.unsafe_set s i '%';
                String.unsafe_set s i1 (char_of_hex (c lsr 4));
                String.unsafe_set s i2 (char_of_hex (c land 0x0F));
                do_enc (succ i0) (succ i2))
           else
             if s0i0 = ' '
             then (String.unsafe_set s i '+'; do_enc (succ i0) (succ i))
             else (String.unsafe_set s i s0i0; do_enc (succ i0) (succ i))
       else ();
     do_enc 0 0;
     s);
(* Unreserved characters consist of all alphanumeric chars and the
   following limited set of punctuation marks and symbols: '-' | '_' |
   '.' | '!' | '~' | '*' | '\'' | '(' | ')'.  According to RFC 2396,
   they should not be escaped unless the context requires it. *)
value special_rfc2396 =
  fun
  [ ';' | '/' | '?' | ':' | '@' | '&' | '=' | '+' | '$' | ',' |
      (* Reserved *) '\000' .. '\031' | '\127' .. '\255' |
      (* Control chars and non-ASCII *) '<' | '>' | '#' | '%' | '"' |
      (* delimiters *) '{' | '}' | '|' | '\\' | '^' | '[' | ']' | '`' ->
      (* unwise *) True
  | _ -> False ];
(* ' ' must also be encoded but its encoding '+' takes a single char. *)
value encode ?(plus = False) s =
  let is_special =
    if plus
    then special_rfc2396
    else fun c -> (special_rfc2396 c) || (c = ' ')
  in encode_wrt is_special s;
value mk_url_encoded_parameters params =
  String.concat "&"
    (List.map (fun (name, val) -> (encode name) ^ ("=" ^ (encode val)))
       params);

