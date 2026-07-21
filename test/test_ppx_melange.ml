let check source actual =
  Test_support.assert_string source
    (Melange_edn.to_edn_string (Melange_edn.of_edn_string source))
    (Melange_edn.to_edn_string actual)

let name = Melange_edn.string "Ada"
let item = Melange_edn.int 42L

let () =
  check {|[-9223372036854775808 \u2603 ##NaN ##Inf ##-Inf]|}
    {%edn|[-9223372036854775808 \u2603 ##NaN ##Inf ##-Inf]|};
  check {|{:runtime "melange" :nested [nil #app/value 42]}|}
    {%edn|{:runtime "melange" :nested [nil #app/value 42]}|};
  check {|{:name "Ada" :items [42] :escaped ?name}|}
    [%edn {|{:name ?name :items [?item] :escaped ??name}|}]
