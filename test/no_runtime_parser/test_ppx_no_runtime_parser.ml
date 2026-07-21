let value : Melange_edn.any =
  {%edn|
    [nil true "text" \u2603 symbol :keyword
     42 123456789012345678901234567890N 1.5 1.20M 3/4 ##NaN ##Inf ##-Inf
     (list) [vector] {:map true} #{set} #"regex" #app/tagged {:ok true}]
  |}

let () = ignore value
