(*********************************************************************************)
(*  crs - A tool for managing inline review comments embedded in source code     *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: LGPL-3.0-or-later WITH LGPL-3.0-linking-exception   *)
(*********************************************************************************)

let parse_file ~path ~file_contents =
  let file_contents =
    file_contents
    |> String.strip
    |> String.substr_replace_all ~pattern:"$CR" ~with_:"CR"
    |> String.substr_replace_all ~pattern:"$XCR" ~with_:"XCR"
    |> Vcs.File_contents.create
  in
  Crs_parser.parse_file ~path ~file_contents |> Cr_comment.sort
;;

let test_cases =
  {|
(* $CR user: Hello. *)
(* $CR user for user2: Hello. *)
(* $XCR user: Hello. *)
(* $XCR user for user2: Hello. *)
(* $CR-user: Invalid. *)
(* $XCR-user: Invalid. *)
(* $CR-soon user: Hello. *)
(* $CR-someday user: Hello. *)
(* $XCR-soon user: Hello. *)
(* $XCR-someday user: Hello. *)
|}
;;
