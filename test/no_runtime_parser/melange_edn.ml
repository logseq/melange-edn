type any = Any
type 'a t = Value

let any _ = Any
let nil = Value
let bool _ = Value
let string _ = Value
let char _ = Value
let seen_symbols = ref []

let symbol value =
  seen_symbols := value :: !seen_symbols;
  Value

let keyword _ = Value
let int _ = Value
let bigint _ = Value
let float _ = Value
let decimal _ = Value
let ratio _ = Value
let regex _ = Value
let list _ = Value
let vector _ = Value
let map _ = Value
let set _ = Value
let tagged _ _ = Value
let saw_symbol value = List.exists (String.equal value) !seen_symbols
