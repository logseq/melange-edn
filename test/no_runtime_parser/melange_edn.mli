type any
type 'a t

val any : 'a t -> any
val nil : unit t
val bool : bool -> bool t
val string : string -> string t
val char : Uchar.t -> Uchar.t t
val symbol : string -> string t
val keyword : string -> string t
val int : int64 -> int64 t
val bigint : string -> string t
val float : float -> float t
val decimal : string -> string t
val ratio : string -> string t
val regex : string -> string t
val list : any list -> any list t
val vector : any list -> any list t
val map : (any * any) list -> (any * any) list t
val set : any list -> any list t
val tagged : string -> any -> (string * any) t
val saw_symbol : string -> bool
