
type json animations = (string*animation) assoc
and animation = (string*frames) assoc
and frames = int array


type json obj_info = (string*oinfo) assoc
and oinfo = {sizex: int; sizey: int; ?hps: hp list option; ?lib: string option}
and hp = {p: (int*int); d: string}

type json frames_dir = {paths: string array}

let init_obj_info file =
  let conf = obj_info_of_json (Json_io.load_json ~allow_comments:true file) in
  conf

let animations_to_json obj dir =
  let json = json_of_animations obj in
  Json_io.save_json (dir ^ "animations.js") json

let init_animations file =
  let conf = animations_of_json (Json_io.load_json ~allow_comments:true file) in
  conf

let init_frames_dir file =
  let conf = frames_dir_of_json (Json_io.load_json ~allow_comments:true file) in
  conf
