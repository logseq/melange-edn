type any
type t

val any : t -> any
val nil : t
val bool : bool -> t
val string : string -> t
val char : Uchar.t -> t
val symbol : string -> t
val keyword : string -> t
val int : int64 -> t
val bigint : string -> t
val float : float -> t
val decimal : string -> t
val ratio : string -> t
val regex : string -> t
val list : any list -> t
val vector : any list -> t
val map : (any * any) list -> t
val set : any list -> t
val tagged : string -> any -> t
