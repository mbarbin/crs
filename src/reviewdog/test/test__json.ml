(****************************************************************************)
(*  ocaml-reviewdog - A reviewdog diagnostics json serializer for OCaml     *)
(*  SPDX-FileCopyrightText: 2025 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                            *)
(****************************************************************************)

let round t =
  let json = Reviewdog.Diagnostic_result.to_yojson t in
  match
    json
    |> Yojson.Safe.to_basic
    |> Reviewdog_rdf.decode_json_diagnostic_result
    |> Reviewdog_rdf.encode_json_diagnostic_result
    |> Yojson.Basic.pretty_to_string ~std:true
    |> Yojson.Safe.from_string
    |> Reviewdog.Diagnostic_result.of_yojson
  with
  | Ok t -> t
  | Error msg ->
    (let json = Yojson.Safe.to_string json in
     Code_error.raise
       "Of_yojson_error"
       [ "msg", msg |> Dyn.string; "json", json |> Dyn.string ])
    [@coverage off]
;;

let%expect_test "roundtrip" =
  Base_quickcheck.Test.run_exn
    (module Reviewdog_with_quickcheck.Diagnostic_result)
    ~f:(fun t1 ->
      let n1 = t1 |> round in
      let n2 = n1 |> round in
      if not (Reviewdog_with_quickcheck.Diagnostic_result.equal n1 n2)
      then (
        (let n1 =
           Sexp.to_string_hum (n1 |> Reviewdog_with_quickcheck.Diagnostic_result.sexp_of_t)
         in
         let n2 =
           Sexp.to_string_hum (n2 |> Reviewdog_with_quickcheck.Diagnostic_result.sexp_of_t)
         in
         print_endline n1;
         print_endline n2;
         ())
        [@coverage off]));
  [%expect {||}];
  ()
;;
