
open Ocamlbuild_plugin
open Ocamlbuild_pack

module Cfg = Myocamlbuild_config

let gtoolchain = ref None;;

let native_only = ref false;;

Options.add ("-toolchain",Arg.String (fun s -> gtoolchain := Some s),"use toolchain");;
Options.add ("-native-only",Arg.Set native_only,"native only compilation")

let native_only_rules () = (* native only compilation *)
  print_endline "native only compilation";
  clear_rules ();
  rule "ocaml: mli -> cmi"
    ~tags:["ocaml"]
    ~prod:"%.cmi"
    ~deps:["%.mli"; "%.mli.depends"]
    (Ocaml_compiler.byte_compile_ocaml_interf "%.mli" "%.cmi");
  rule "ocaml: ml & cmi -> cmx & o"
    ~tags:["ocaml"; "native"]
    ~prods:["%.cmx"; "%.o"]
    ~deps:["%.mli"; "%.ml"; "%.ml.depends"; "%.cmi"]
    (Ocaml_compiler.native_compile_ocaml_implem "%.ml");
  rule "ocaml: ml -> cmx & o & cmi"
    ~tags:["ocaml";"native"]
    ~prods:["%.cmx"; "%.o"; "%.cmi"]
    ~deps:["%.ml"; "%.ml.depends"]
    (Ocaml_compiler.native_compile_ocaml_implem "%.ml");
  rule "ocaml: cmx* & o* -> native"
    ~tags:["ocaml"; "native"; "program"]
    ~prod:"%.native"
    ~deps:["%.cmx"; "%.o"]
    (Ocaml_compiler.native_link "%.cmx" "%.native");
  rule "ocaml: mllib & cmo* -> cma"
    ~tags:["ocaml"; "byte"; "library"]
    ~prod:"%.cma"
    ~dep:"%.mllib"
    (Ocaml_compiler.byte_library_link_mllib "%.mllib" "%.cma");
  rule "ocaml: ml -> cmo & cmi"
    ~tags:["ocaml"]
    ~prods:["%.cmo"; "%.cmi"]
    ~deps:["%.ml"; "%.ml.depends"]
    (Ocaml_compiler.byte_compile_ocaml_implem "%.ml" "%.cmo");
  rule "ocaml dependencies ml"
    ~prod:"%.ml.depends"
    ~dep:"%.ml"
    (Ocaml_tools.ocamldep_command "%.ml" "%.ml.depends");
  rule "ocaml dependencies mli"
    ~prod:"%.mli.depends"
    ~dep:"%.mli"
    (Ocaml_tools.ocamldep_command "%.mli" "%.mli.depends");
  rule "ocaml C stubs: c -> o"
    ~prod:"%.o"
    ~dep:"%.c"
    begin fun env _build ->
      let c = env "%.c" in
      let o = env "%.o" in
      let comp = !Options.ocamlopt in
      let cc = Cmd(S[comp; T(tags_of_pathname c++"c"++"compile"); A"-c"; Px c]) in
      if Pathname.dirname o = Pathname.current_dir_name then cc
      else Seq[cc; mv (Pathname.basename o) o]
    end
;;



let lightning_dispatch = 
  function
    | After_options -> 
        (match !gtoolchain with
        | Some t -> 
            print_endline ("toolchain: " ^ t);
            Options.ocamlopt := S[V "OCAMLFIND"; A"-toolchain"; A t ; A"ocamlopt"];
            Options.ocamlc := S[V "OCAMLFIND"; A"-toolchain"; A t ; A"ocamlc"];
            Options.ocamldep := S[V "OCAMLFIND"; A"-toolchain"; A t ; A"ocamldep"];
            Options.ocamlmklib := S[V "OCAMLFIND"; A"-toolchain"; A t ; A"ocamlmklib"];
        | None -> ())
    | After_rules ->
        (match !native_only with
        | true -> native_only_rules ()
        | false -> ());
        (match !gtoolchain with
        | Some "ios" -> 
            rule "ocaml obj-c stubs: m -> o"
            ~prod:"%.o"
            ~dep:"%.m"
            begin fun env _build ->
              let c = env "%.m" in
              let o = env "%.o" in
              let comp = !Options.ocamlopt in
              let cc = Cmd(S[comp; T(tags_of_pathname c++"c"++"compile"); A"-c"; Px c]) in
              if Pathname.dirname o = Pathname.current_dir_name then cc
              else Seq[cc; mv (Pathname.basename o) o]
            end;
            dep [ ("file:" ^ ios_path ^ "/AppDelegate.m") ] [ (ios_path ^ "/AppDelegate.h")];
            dep [ ("file:" ^ main ^ ".native"); "ocaml"; "link" ] [ (ios_path ^ "/AppDelegate.o"); (ios_path ^ "/main.o")]
        | Some "android" -> 
            (*
            let andconfig = (try List.assoc "android" Cfg.toolchains with | Not_found -> []) in
            let andndkpath = List.assoc "ndk-path" andconfig in
            let andplatform = List.assoc "platform" andconfig in
            flag ["ocaml"; "native"; "link"; "file:Farm.so" ] (S[(A"-ccopt"); (A("-L " ^ andndkpath ^ "/platforms/" ^ andplatform ^ "/arch-arm/usr/lib/"))]);
            *)
            rule "ocaml: cmx* & o* -> so" 
              ~tags:["ocaml"; "native"; "program"]
              ~prod:"%.so"
              ~deps:["%.cmx"; "%.o"]
              (Ocaml_compiler.native_link "%.cmx" "%.so");
            tag_file (main ^ ".so") ["output_obj"];
        | _ -> ()
        );
        (* pa_log conf *)
        List.iter begin fun (path,labels) ->
          let opts =
            List.map begin fun l ->
              let lab = String.sub l 1 ((String.length l) - 1) in
              let flag = begin
                match l.[0] with
                | '-' -> "-disable-debug"
                | '+' -> "-enable-debug"
                | _ -> failwith (Printf.sprintf "incorrect log_compile label %s" l)
            end
              in
              S[A"-ppopt";A flag; A "-ppopt"; A lab]
              end labels
              in
              match path with
              | "root" -> flag [ "ocaml"; "compile"; "package(redspell.syntax.debug)" ] (S opts)
              | file -> flag [ "ocaml"; "compile"; "package(redspell.syntax.debug)"; "file:"^ path ] (S opts)
            end Cfg.log_compile;

            flag ["ocaml";"compile";"package(redspell.syntax.debug)";"disable-all-debugs"] (S[A"-ppopt"; A"-disable-all-debugs"]);
            pflag ["ocaml";"compile"] "warn" (fun x -> S[A"-w";A x]);
            pflag ["ocaml";"compile"] "warn-error" (fun x -> S[A"-warn-error";A x]);
            pflag_and_dep ["ocaml";"ocamldep"] "ppopt" (fun opt -> S[A"-ppopt";A opt]);
            pflag_and_dep ["ocaml";"compile"] "ppopt" (fun opt -> S[A"-ppopt";A opt]);
        | _ -> ()
;;


