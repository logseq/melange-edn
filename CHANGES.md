# Unreleased

- Add the `melange-edn-ppx` package for compile-time EDN literals in native
  OCaml, js_of_ocaml, and Melange code.
- Validate exactly one EDN form during compilation and expand it into calls to
  the public `Melange_edn` construction API without runtime EDN parsing.
- Reduce PPX allocation and stack usage when expanding large flat collections.

# 0.5.0

- Add native Yojson, js_of_ocaml, and Melange JSON bridge libraries.
- Expand EDN reader compatibility with numeric literals, reader macros, namespaced maps, tagged literals, and symbolic floats.
- Reject overflowing integer literals with `Parse_error`.
- Preserve `Yojson.Safe.Intlit` values as EDN bigints.

# 0.2.0

- Make EDN value constructors private and add public creation functions.
- Reject invalid keyword forms during parsing and value creation.

# 0.1.0

Initial release.

- Add EDN reader and writer for Melange.
- Add JSON conversion helpers.
- Add opam package metadata for `melange-edn`.
