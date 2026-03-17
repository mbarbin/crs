(**************************************************************************)
(*  Copyright (c) 2026 Invariant Systems. All rights reserved.            *)
(*  SPDX-License-Identifier: ISC                                          *)
(**************************************************************************)

open Windtrap

module Int_equal = struct
  type t = int

  let equal (a : int) (b : int) = a = b
end

let line_equal eq a b =
  match a, b with
  | Myers.Line.Delete x, Myers.Line.Delete y -> eq x y
  | Myers.Line.Insert x, Myers.Line.Insert y -> eq x y
  | Myers.Line.Keep x, Myers.Line.Keep y -> eq x y
  | _ -> false
;;

let line_list_equal eq a b =
  List.length a = List.length b && List.for_all2 (line_equal eq) a b
;;

let contains ~needle haystack =
  let plen = String.length needle in
  let slen = String.length haystack in
  let rec loop i =
    if i + plen > slen
    then false
    else if String.sub haystack i plen = needle
    then true
    else loop (i + 1)
  in
  if plen = 0 then true else loop 0
;;

let compute_tests =
  group
    "compute"
    [ test "empty sequences" (fun () ->
        let script = Myers.compute (module Int_equal) [] [] in
        is_true (script = []))
    ; test "identical sequences" (fun () ->
        let script = Myers.compute (module Int_equal) [ 1; 2 ] [ 1; 2 ] in
        is_true
          (line_list_equal Int.equal script [ Myers.Line.Keep 1; Myers.Line.Keep 2 ]))
    ; test "mixed insert and delete" (fun () ->
        let script = Myers.compute (module Int_equal) [ 1; 2; 3 ] [ 1; 3; 4 ] in
        is_true
          (line_list_equal
             Int.equal
             script
             [ Myers.Line.Keep 1
             ; Myers.Line.Delete 2
             ; Myers.Line.Keep 3
             ; Myers.Line.Insert 4
             ]))
    ]
;;

let diff_tests =
  group
    "diff"
    [ test "renders unified diff" (fun () ->
        let actual = Myers.diff "a\nb\n" "a\nc\n" in
        equal Testable.string "@@ -1,2 +1,2 @@\n  a\n-|b\n+|c\n" actual)
    ; test "supports custom labels" (fun () ->
        let actual =
          Myers.diff ~expected_label:"before" ~actual_label:"after" "x\n" "y\n"
        in
        is_true (contains ~needle:"--- before\n+++ after\n" actual))
    ; test "print_diff writes to stdout" (fun () ->
        let expected = Myers.diff "left\n" "right\n" in
        capture_exact (fun () -> Myers.print_diff "left\n" "right\n") expected |> ignore)
    ]
;;

let () = run "Myers" [ compute_tests; diff_tests ]
