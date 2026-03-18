(*********************************************************************************)
(*  crs - A tool for managing inline review comments embedded in source code     *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: LGPL-3.0-or-later WITH LGPL-3.0-linking-exception   *)
(*********************************************************************************)

let%expect_test "all" =
  List.iter Cr_comment.Filter.all ~f:(fun filter ->
    print_dyn
      (Dyn.record
         [ "filter", filter |> Cr_comment.Filter.to_dyn
         ; "to_string", Cr_comment.Filter.to_string filter |> Dyn.string
         ; "shorthand", Cr_comment.Filter.shorthand filter |> Dyn.char
         ]));
  [%expect
    {|
    { filter = All; to_string = "all"; shorthand = a }
    { filter = Invalid; to_string = "invalid"; shorthand = i }
    { filter = CRs; to_string = "crs"; shorthand = c }
    { filter = XCRs; to_string = "xcrs"; shorthand = x }
    { filter = Now; to_string = "now"; shorthand = w }
    { filter = Soon; to_string = "soon"; shorthand = o }
    { filter = Someday; to_string = "someday"; shorthand = d }
    |}];
  ()
;;

let%expect_test "equal" =
  require_equal (module Cr_comment.Filter) All All;
  require_not_equal (module Cr_comment.Filter) All Invalid;
  [%expect {||}];
  ()
;;

let%expect_test "compare" =
  print_dyn
    (List.sort
       (List.concat [ List.rev Cr_comment.Filter.all; [ Soon; Invalid; Someday; Now ] ])
       ~compare:Cr_comment.Filter.compare
     |> Dyn.list Cr_comment.Filter.to_dyn);
  [%expect
    {| [ All; Invalid; Invalid; CRs; XCRs; Now; Now; Soon; Soon; Someday; Someday ] |}];
  ()
;;

let%expect_test "string count" =
  let module String_set = Set.Make (String) in
  let count = List.length Cr_comment.Filter.all in
  let string_count =
    String_set.of_list (List.map Cr_comment.Filter.all ~f:Cr_comment.Filter.to_string)
    |> String_set.cardinal
  in
  require_equal (module Int) count string_count;
  [%expect {||}];
  ()
;;

let%expect_test "shorthand count" =
  let module Char_set = Set.Make (Char) in
  let count = List.length Cr_comment.Filter.all in
  let shorthand_count =
    Char_set.of_list (List.map Cr_comment.Filter.all ~f:Cr_comment.Filter.shorthand)
    |> Char_set.cardinal
  in
  require_equal (module Int) count shorthand_count;
  [%expect {||}];
  ()
;;
