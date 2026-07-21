let check source actual =
  Test_support.assert_string source
    (Melange_edn.to_edn_string (Melange_edn.of_edn_string source))
    (Melange_edn.to_edn_string actual)

let name = Melange_edn.string "Ada"
let active = Melange_edn.bool true

let () =
  check {|[-9223372036854775808 \u2603 ##NaN ##Inf ##-Inf]|}
    {%edn|[-9223372036854775808 \u2603 ##NaN ##Inf ##-Inf]|};
  check {|{:runtime "js_of_ocaml" :nested [nil #app/value 42]}|}
    {%edn|{:runtime "js_of_ocaml" :nested [nil #app/value 42]}|};
  check {|{:name "Ada" :active true :escaped ?name}|}
    [%edn {|{:name ?name :active ?active :escaped ??name}|}]
