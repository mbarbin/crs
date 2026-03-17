(********************************************************************************)
(*  crs - A tool for managing inline review comments embedded in source code    *)
(*  Copyright (C) 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>           *)
(*                                                                              *)
(*  This file is part of crs.                                                   *)
(*                                                                              *)
(*  crs is free software; you can redistribute it and/or modify it under the    *)
(*  terms of the GNU Lesser General Public License as published by the Free     *)
(*  Software Foundation either version 3 of the License, or any later version,  *)
(*  with the LGPL-3.0 Linking Exception.                                        *)
(*                                                                              *)
(*  crs is distributed in the hope that it will be useful, but WITHOUT ANY      *)
(*  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS   *)
(*  FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License and     *)
(*  the file `NOTICE.md` at the root of this repository for more details.       *)
(*                                                                              *)
(*  You should have received a copy of the GNU Lesser General Public License    *)
(*  and the LGPL-3.0 Linking Exception along with this library. If not, see     *)
(*  <http://www.gnu.org/licenses/> and <https://spdx.org>, respectively.        *)
(********************************************************************************)

let print_lines (lines : _ Myers.Line.t list) =
  List.iter lines ~f:(function
    | Delete s -> Printf.printf "-%s\n" s
    | Insert s -> Printf.printf "+%s\n" s
    | Keep s -> Printf.printf " %s\n" s)
;;

(* Exercises the [while !x > 0] loop in backtracking — all elements in
   [before] must be deleted, none are in [after]. *)
let%expect_test "compute - all deletions" =
  Myers.compute (module String) [ "a"; "b"; "c" ] [] |> print_lines;
  [%expect
    {|
    -a
    -b
    -c
    |}];
  ()
;;

(* Exercises the [while !y > 0] loop in backtracking — all elements in [after]
   are insertions. *)
let%expect_test "compute - all insertions" =
  Myers.compute (module String) [] [ "x"; "y"; "z" ] |> print_lines;
  [%expect
    {|
    +x
    +y
    +z
    |}];
  ()
;;

(* Exercises the else branch in the forward pass: with two sequences of equal
   length sharing no elements, the algorithm reaches interior diagonals where
   k <> -d and k <> d and v[k-1] >= v[k+1]. *)
let%expect_test "compute - completely different same length" =
  Myers.compute (module String) [ "a"; "b"; "c" ] [ "x"; "y"; "z" ] |> print_lines;
  [%expect
    {|
    -a
    -b
    -c
    +x
    +y
    +z
    |}];
  ()
;;

(* Exercises the [while !x > 0 && !y > 0] loop that emits Keep operations for
   leading common elements after backtracking. *)
let%expect_test "compute - common prefix then changes" =
  Myers.compute (module String) [ "a"; "b"; "c"; "d" ] [ "a"; "b"; "x"; "y" ]
  |> print_lines;
  [%expect
    {|
     a
     b
    -c
    -d
    +x
    +y
    |}];
  ()
;;

(* Single element changed. *)
let%expect_test "compute - single replace" =
  Myers.compute (module String) [ "a" ] [ "b" ] |> print_lines;
  [%expect
    {|
    -a
    +b
    |}];
  ()
;;

(* Exercises the [lines_of_string] path where the input string does not end
   with a newline. *)
let%expect_test "diff - no trailing newline" =
  Myers.diff "a" "b" |> print_string;
  [%expect
    {|
    @@ -1,1 +1,1 @@
    -|a
    +|b
    |}];
  ()
;;

(* Exercises [Insert] as the first change encountered (when not yet in a hunk),
   triggering the [start_hunk] call from the Insert branch. *)
let%expect_test "diff - insertion only" =
  Myers.diff "a\n" "a\nb\n" |> print_string;
  [%expect
    {|
    @@ -1,1 +1,2 @@
      a
    +|b
    |}];
  ()
;;

(* Exercises hunk splitting: two changes separated by enough unchanged lines
   (> 2*context) produce two separate hunks. This tests the trailing-context
   countdown, finish_hunk, and re-start-hunk paths. *)
let%expect_test "diff - multiple hunks" =
  let expected = "1\n2\n3\n4\n5\n6\n7\n8\n9\n10\n" in
  let actual = "X\n2\n3\n4\n5\n6\n7\n8\n9\nY\n" in
  Myers.diff expected actual |> print_string;
  [%expect
    {|
    @@ -1,4 +1,4 @@
    -|1
    +|X
      2
      3
      4
    @@ -7,4 +7,4 @@
      7
      8
      9
    -|10
    +|Y
    |}];
  ()
;;

(* Exercises the label rendering when only one label is given. *)
let%expect_test "diff - partial labels" =
  Myers.diff ~expected_label:"before" "a\n" "b\n" |> print_string;
  [%expect
    {|
    --- before
    +++ actual
    @@ -1,1 +1,1 @@
    -|a
    +|b
    |}];
  Myers.diff ~actual_label:"after" "a\n" "b\n" |> print_string;
  [%expect
    {|
    --- expected
    +++ after
    @@ -1,1 +1,1 @@
    -|a
    +|b
    |}];
  ()
;;

(* Exercises the no-labels path where neither expected_label nor actual_label
   is provided — the header is omitted entirely. *)
let%expect_test "diff - no labels" =
  Myers.diff "a\n" "b\n" |> print_string;
  [%expect
    {|
    @@ -1,1 +1,1 @@
    -|a
    +|b
    |}];
  ()
;;

(* Context=0 means no surrounding context lines in hunks. *)
let%expect_test "diff - zero context" =
  Myers.diff ~context:0 "a\nb\nc\n" "a\nX\nc\n" |> print_string;
  [%expect
    {|
    @@ -2,1 +2,1 @@
    -|b
    +|X
    |}];
  ()
;;

(* Exercises print_diff on a non-trivial diff. *)
let%expect_test "print_diff" =
  Myers.print_diff "hello\nworld\n" "hello\nearth\n";
  [%expect
    {|
    @@ -1,2 +1,2 @@
      hello
    -|world
    +|earth
    |}];
  ()
;;
