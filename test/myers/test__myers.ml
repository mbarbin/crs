(**************************************************************************)
(*  crs-myers - Myers diff computation and unified-diff printing          *)
(*  Copyright (C) 2026 Mathieu Barbin <mathieu.barbin@gmail.com>          *)
(*  SPDX-License-Identifier: ISC                                          *)
(**************************************************************************)

let print_lines (lines : _ Myers.Line.t list) =
  List.iter lines ~f:(function
    | Delete s -> Printf.printf "-%s\n" s
    | Insert s -> Printf.printf "+%s\n" s
    | Keep s -> Printf.printf " %s\n" s)
;;

(* Exercises the [n = 0 && m = 0] early-return branch in [Merge3.diff]. *)
let%expect_test "compute - empty" =
  Myers.compute (module String) [] [] |> print_lines;
  [%expect {| |}];
  ()
;;

(* Exercises the [m = 0] early-return branch (all deletions). *)
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

(* Exercises the [n = 0] early-return branch (all insertions). *)
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

(* Identical non-empty sequences: the forward pass terminates at d = 0 and
   backtracking emits only the trailing [while !x > 0] Keep loop. *)
let%expect_test "compute - identical" =
  Myers.compute (module String) [ "a"; "b"; "c" ] [ "a"; "b"; "c" ] |> print_lines;
  [%expect
    {|
     a
     b
     c
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

(* Exercises the trailing [while !x > 0] Keep loop after backtracking for a
   leading common prefix, plus an interior [Delete]/[Insert] choice. *)
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

(* Mixed insert and delete around kept elements — exercises both the [Insert]
   and [Delete] backtracking branches with interior snakes. *)
let%expect_test "compute - mixed insert and delete" =
  Myers.compute (module String) [ "1"; "2"; "3" ] [ "1"; "3"; "4" ] |> print_lines;
  [%expect
    {|
     1
    -2
     3
    +4
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
