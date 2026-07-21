let check source actual =
  Test_support.assert_string source
    (Melange_edn.to_edn_string (Melange_edn.of_edn_string source))
    (Melange_edn.to_edn_string actual)

let compile_time_config : Melange_edn.any =
  {%edn|
    {:name "Ada"
     :tags ["ocaml" nil]
     :ok true}
  |}

let () =
  check {|{:name "Ada" :tags ["ocaml" nil] :ok true}|} compile_time_config;
  check "nil" [%edn {|nil|}];
  check "[true false]" {%edn|[true false]|};
  check {|"line\nquote:\" slash:\\ snowman:\u2603"|}
    {%edn|"line\nquote:\" slash:\\ snowman:\u2603"|};
  check {|[\space \u2603 \o101]|} {%edn|[\space \u2603 \o101]|};
  check {|[app/name :app/name /]|} {%edn|[app/name :app/name /]|};
  check
    {|[42 -9223372036854775808 052 0x2a 2r101010 123456789012345678901234567890N 6.02e23 1.20M 4/2]|}
    {%edn|[42 -9223372036854775808 052 0x2a 2r101010 123456789012345678901234567890N 6.02e23 1.20M 4/2]|};
  check {|[##NaN ##Inf ##-Inf]|} {%edn|[##NaN ##Inf ##-Inf]|};
  check {|(one nil 3)|} {%edn|(one nil 3)|};
  check {|[one nil 3]|} {%edn|[one nil 3]|};
  check {|[() [] {} #{}]|} {%edn|[() [] {} #{}]|};
  check {|{:name "Ada" :ok true}|} {%edn|{:name "Ada" :ok true}|};
  check {|#{:a 1 "two"}|} {%edn|#{:a 1 "two"}|};
  check {|#"(?i)a\\sb"|} {%edn|#"(?i)a\\sb"|};
  check {|#my/app {:ok true}|} {%edn|#my/app {:ok true}|};
  check
    {|{:person {:name "Ada" :active true} :values [nil 42 3/4] :tags #{ocaml melange} :pattern #"a+" :custom #app/id "42"}|}
    {%edn|{:person {:name "Ada" :active true} :values [nil 42 3/4] :tags #{ocaml melange} :pattern #"a+" :custom #app/id "42"}|};
  check
    {|[1 #_discarded 2 ; ignored until the newline
       3]|}
    {%edn|[1 #_discarded 2 ; ignored until the newline
           3]|};
  check {|#:person{:name "Ada" :age 42 :_/id 7}|}
    {%edn|#:person{:name "Ada" :age 42 :_/id 7}|};
  check {|['foo @bar #'baz ^:private {:ok true} #(f %)]|}
    {%edn|['foo @bar #'baz ^:private {:ok true} #(f %)]|};
  check {|#uuid "550E8400-E29B-41D4-A716-446655440000"|}
    {%edn|#uuid "550E8400-E29B-41D4-A716-446655440000"|}
