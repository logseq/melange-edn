open Ppxlib
module Builder = Ast_builder.Default

let qualified_identifier ~loc module_name name =
  Builder.pexp_ident ~loc
    (Builder.Located.mk ~loc
       (Longident.Ldot (Longident.Lident module_name, name)))

let call ~loc name arguments =
  Builder.pexp_apply ~loc
    (qualified_identifier ~loc "Melange_edn" name)
    (List.map (fun argument -> (Nolabel, argument)) arguments)

let wrap ~loc expression = call ~loc "any" [ expression ]

let is_identifier_start = function 'a' .. 'z' | '_' -> true | _ -> false

let is_identifier_char = function
  | 'a' .. 'z' | 'A' .. 'Z' | '0' .. '9' | '_' | '\'' -> true
  | _ -> false

let is_simple_value_identifier value =
  let length = String.length value in
  length > 0
  && not (String.equal value "_")
  && is_identifier_start value.[0]
  && not (Keyword.is_keyword value)
  &&
  let rec loop index =
    index = length || (is_identifier_char value.[index] && loop (index + 1))
  in
  loop 1

let identifier_expression ~loc name =
  Builder.pexp_ident ~loc
    (Builder.Located.mk ~loc (Longident.Lident name))

let array_expression ~loc element_expression values =
  let result =
    ref
      (Builder.pexp_construct ~loc
         (Builder.Located.mk ~loc (Longident.Lident "[]"))
         None)
  in
  for index = Array.length values - 1 downto 0 do
    result :=
      Builder.pexp_construct ~loc
        (Builder.Located.mk ~loc (Longident.Lident "::"))
        (Some
           (Builder.pexp_tuple ~loc
              [ element_expression values.(index); !result ]))
  done;
  !result

let float_expression ~loc value =
  match classify_float value with
  | FP_nan -> qualified_identifier ~loc "Float" "nan"
  | FP_infinite when value > 0. -> qualified_identifier ~loc "Float" "infinity"
  | FP_infinite -> qualified_identifier ~loc "Float" "neg_infinity"
  | FP_normal | FP_subnormal | FP_zero ->
      Builder.efloat ~loc (Printf.sprintf "%.17g" value)

let symbol_expression ~loc value =
  call ~loc "symbol" [ Builder.estring ~loc value ]

let rec expression_of_any ~loc ~error_loc (Melange_edn.Any value) =
  match value with
  | Symbol value
    when String.length value > 1 && value.[0] = '?' && value.[1] = '?' ->
      wrap ~loc
        (symbol_expression ~loc (String.sub value 1 (String.length value - 1)))
  | Symbol value when String.length value > 0 && value.[0] = '?' ->
      let name = String.sub value 1 (String.length value - 1) in
      if not (is_simple_value_identifier name) then
        Location.raise_errorf ~loc:error_loc
          "melange-edn-ppx: invalid antiquotation identifier: %s" value;
      wrap ~loc (identifier_expression ~loc name)
  | _ -> wrap ~loc (expression_of_value ~loc ~error_loc value)

and expression_of_value : type value.
    loc:Location.t -> error_loc:Location.t -> value Melange_edn.t -> expression =
 fun ~loc ~error_loc value ->
  match value with
  | Nil -> qualified_identifier ~loc "Melange_edn" "nil"
  | Bool value -> call ~loc "bool" [ Builder.ebool ~loc value ]
  | String value -> call ~loc "string" [ Builder.estring ~loc value ]
  | Char value ->
      call ~loc "char"
        [
          Builder.pexp_apply ~loc
            (qualified_identifier ~loc "Uchar" "of_int")
            [ (Nolabel, Builder.eint ~loc (Uchar.to_int value)) ];
        ]
  | Symbol value -> symbol_expression ~loc value
  | Keyword value ->
      call ~loc "keyword"
        [ Builder.estring ~loc (Melange_edn.keyword_to_string value) ]
  | Int value -> call ~loc "int" [ Builder.eint64 ~loc value ]
  | Bigint value -> call ~loc "bigint" [ Builder.estring ~loc value ]
  | Float value -> call ~loc "float" [ float_expression ~loc value ]
  | Decimal value -> call ~loc "decimal" [ Builder.estring ~loc value ]
  | Ratio value -> call ~loc "ratio" [ Builder.estring ~loc value ]
  | Regex value -> call ~loc "regex" [ Builder.estring ~loc value ]
  | List values ->
      call ~loc "list"
        [ array_expression ~loc (expression_of_any ~loc ~error_loc) values ]
  | Vector values ->
      call ~loc "vector"
        [ array_expression ~loc (expression_of_any ~loc ~error_loc) values ]
  | Map entries ->
      let entry_expression (key, value) =
        Builder.pexp_tuple ~loc
          [
            expression_of_any ~loc ~error_loc key;
            expression_of_any ~loc ~error_loc value;
          ]
      in
      call ~loc "map" [ array_expression ~loc entry_expression entries ]
  | Set values ->
      call ~loc "set"
        [ array_expression ~loc (expression_of_any ~loc ~error_loc) values ]
  | Tagged (tag, value) ->
      call ~loc "tagged"
        [ Builder.estring ~loc tag; expression_of_any ~loc ~error_loc value ]

let parse_one ~loc source =
  match Melange_edn.of_edn_string_all source with
  | [ value ] -> value
  | [] ->
      Location.raise_errorf ~loc
        "melange-edn-ppx: EDN literal must contain exactly one form; found none"
  | values ->
      Location.raise_errorf ~loc
        "melange-edn-ppx: EDN literal must contain exactly one form; found %d"
        (List.length values)
  | exception Melange_edn.Parse_error message ->
      Location.raise_errorf ~loc "melange-edn-ppx: %s" message

let expand ~ctxt payload =
  let extension_loc = Expansion_context.Extension.extension_point_loc ctxt in
  match payload with
  | PStr
      [
        {
          pstr_desc =
            Pstr_eval
              ( ({ pexp_desc = Pexp_constant (Pconst_string (source, _, _)); _ }
                 as literal),
                [] );
          _;
        };
      ] ->
      expression_of_any ~loc:literal.pexp_loc ~error_loc:extension_loc
        (parse_one ~loc:literal.pexp_loc source)
  | _ ->
      Location.raise_errorf ~loc:extension_loc
        "melange-edn-ppx: extension payload must be a string literal"

let extension =
  Extension.V3.declare "edn" Extension.Context.expression Ast_pattern.__ expand

let () =
  Driver.register_transformation "melange-edn-ppx"
    ~rules:[ Context_free.Rule.extension extension ]
