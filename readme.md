# melange-edn

EDN reader and writer for OCaml, js_of_ocaml, and Melange.

`melange-edn` parses EDN strings into a typed OCaml value model, writes values
back to EDN, and converts between EDN values and JSON values across native,
js_of_ocaml, and Melange targets.

## Packages

- `melange-edn-core`: shared EDN value model, parser, and writer.
- `melange-edn-native`: native OCaml package with Yojson conversion.
- `melange-edn-jsoo`: js_of_ocaml package with JavaScript JSON conversion.
- `melange-edn-melange`: Melange package with `Js.Json.t` conversion.
- `melange-edn-ppx`: compile-time EDN literals for native OCaml,
  js_of_ocaml, and Melange.

Each platform package depends on `melange-edn-core` and exposes the core EDN
API plus the platform-specific JSON bridge from its main module, so installing
one bridge package does not pull in the other bridge dependencies.

## Features

- Parse one EDN form with `of_edn_string`.
- Parse multiple EDN forms with `of_edn_string_all`.
- Write EDN with `to_edn_string`.
- Convert JSON values with `of_json`, `of_json_string`, `to_json`, and
  `to_json_string` in the package's main module.
- Supports EDN atoms, collections, comments, discard forms, tagged values,
  namespaced maps, symbolic floating-point values, octal escapes, ratios, regex
  literals, common reader macros, and `#uuid` / `#inst` default tags.
- Embed one validated EDN form at compile time with `[%edn ...]` or
  `{%edn|...|}`.

## Compile-time literals

Install `melange-edn-ppx` together with the package for the target backend. For
example:

```sh
opam install melange-edn-native melange-edn-ppx
```

Enable the PPX in the consuming Dune stanza:

```lisp
(preprocess
 (pps melange-edn-ppx))
```

The quoted extension syntax is convenient for multiline native OCaml code:

```ocaml
let config : Melange_edn.any =
  {%edn|
    {:name "Ada"
     :tags ["ocaml" nil]
     :ok true}
  |}

let text =
  Melange_edn_native.to_edn_string config
```

The regular extension syntax is equivalent and works in Melange source:

```ocaml
let config : Melange_edn.any =
  [%edn {|{:name "Ada" :runtime "melange" :ok true}|}]

let text =
  Melange_edn_melange.to_edn_string config
```

Each literal must be a compile-time string literal containing exactly one EDN
form. The extension returns `Melange_edn.any`. EDN parsing and validation happen
while the PPX runs during compilation, so malformed input is a compilation
error and the generated application does not call `Melange_edn.of_edn_string`.
Evaluating the expanded expression still performs the normal runtime value
construction and allocation required by the public `Melange_edn` construction
API; only runtime EDN parsing is eliminated.

### Antiquotation

Prefix a simple local OCaml value identifier with `?` to insert a typed EDN
value into a compile-time literal. The variable must have a concrete
`'a Melange_edn.t` type; the PPX wraps it with `Melange_edn.any` in the
generated expression.

```ocaml
let name = Melange_edn.string "Ada"
let age = Melange_edn.int 42L
let active = Melange_edn.bool true

let person : Melange_edn.any =
  [%edn {|{:name ?name :age ?age :active ?active}|}]
```

Antiquotation works at the top level and anywhere an EDN value can occur,
including collection keys and values, nested collections, and tagged literal
values. Only simple local value identifiers such as `?name`, `?user_name`,
`?value2`, and `?value'` are accepted.

The leading `?` is explicit syntax rather than part of ordinary EDN symbol
behavior:

```text
name    -> literal EDN symbol "name"
?name   -> OCaml variable name, wrapped with Melange_edn.any
??name  -> literal EDN symbol "?name"
???name -> literal EDN symbol "??name"
```

Ordinary OCaml values are not converted automatically. For example, use
`Melange_edn.string "Ada"` instead of the OCaml string `"Ada"`. A value already
wrapped as `Melange_edn.any` is also not accepted by `?name`; pass the original
typed `'a Melange_edn.t` value instead.

Antiquotation is a PPX-only feature. The runtime `Melange_edn.of_edn_string`
and `Melange_edn.of_edn_string_all` functions continue to parse `?name` as an
ordinary EDN symbol.

## Usage

```ocaml
open Melange_edn_native

let edn =
  of_edn_string {|{:name "Ada" :tags ["ocaml" nil] :ok true}|}

let edn_text =
  to_edn_string edn

let json_text =
  to_json_string edn

let from_json =
  of_json_string {|{"name":"Ada","tags":["ocaml",null],"ok":true}|}
```

Use the backend packages when working with JavaScript JSON values:

```ocaml
open Melange_edn_melange

let melange_json =
  to_json (of_edn_string {|{:name "Ada"}|})
```

```ocaml
open Melange_edn_jsoo

let jsoo_json =
  to_json (of_edn_string {|{:name "Ada"}|})
```

Construct values with the typed creation functions:

```ocaml
open Melange_edn_native

let value =
  any
    (map
       [
         (any (keyword "name"), any (string "Ada"));
         (any (keyword "ok"), any (bool true));
       ])

let text =
  to_edn_string value
```

## Development

Run the test suite:

```sh
dune runtest
```

Measure compile-time expansion of a generated 10,000-element EDN vector:

```sh
sh benchmark/benchmark_ppx.sh
```

## License

MIT
