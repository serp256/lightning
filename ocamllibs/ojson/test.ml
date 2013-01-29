
let () = 
  let json = Read.from_file "test.json" in
  Write.to_file "/tmp/test.json" json;
