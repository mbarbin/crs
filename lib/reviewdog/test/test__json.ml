(****************************************************************************)
(*  ocaml-reviewdog - A reviewdog diagnostics json serializer for OCaml     *)
(*  SPDX-FileCopyrightText: 2025 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                            *)
(****************************************************************************)

let round t =
  match
    t
    |> Reviewdog.Diagnostic_result.yojson_of_t
    |> Yojson.Safe.to_basic
    |> Reviewdog_rdf.decode_json_diagnostic_result
    |> Reviewdog_rdf.encode_json_diagnostic_result
    |> Yojson.Basic.pretty_to_string ~std:true
    |> Yojson.Safe.from_string
    |> Reviewdog.Diagnostic_result.t_of_yojson
  with
  | t -> t
  | exception Ppx_yojson_conv_lib.Yojson_conv.Of_yojson_error (exn, json) ->
    (let json = Yojson.Safe.to_string json in
     raise_s [%sexp "Of_yojson_error", { exn : Exn.t; json : string }])
    [@coverage off]
;;

let%expect_test "roundtrip" =
  quickcheck_m
    [%here]
    (module Reviewdog_with_quickcheck.Diagnostic_result)
    ~f:(fun t1 ->
      let n1 = t1 |> round in
      let n2 = n1 |> round in
      require_equal [%here] (module Reviewdog_with_quickcheck.Diagnostic_result) n1 n2);
  [%expect {||}];
  ()
;;
