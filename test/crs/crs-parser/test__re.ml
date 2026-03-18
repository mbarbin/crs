(*********************************************************************************)
(*  crs - A tool for managing inline review comments embedded in source code     *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: LGPL-3.0-or-later WITH LGPL-3.0-linking-exception   *)
(*********************************************************************************)

(* We monitor some characteristics of [ocaml-re] that the code relies on. *)

let%expect_test "stop" =
  let name = "wo#name" in
  let re = Re.compile Re.(group ~name (str "wo")) in
  (* [group_names] is available on this compiled regexp. *)
  let group_names = Re.group_names re in
  print_dyn
    (Dyn.record
       [ ( "group_names"
         , group_names |> Dyn.list (fun (s, i) -> Dyn.Tuple [ Dyn.string s; Dyn.int i ]) )
       ]);
  [%expect {| { group_names = [ ("wo#name", 1) ] } |}];
  let wo_index =
    List.find_exn group_names ~f:(fun (n, _) -> String.equal n name) |> snd
  in
  print_dyn (Dyn.record [ "wo_index", wo_index |> Dyn.int ]);
  [%expect {| { wo_index = 1 } |}];
  let group = Re.exec re "hello world" in
  (* The stop offset is excluded. *)
  print_dyn (Dyn.record [ "get0", Re.Group.get group 0 |> Dyn.string ]);
  [%expect {| { get0 = "wo" } |}];
  print_dyn
    (Dyn.record
       [ ( "offset"
         , Re.Group.offset group wo_index
           |> fun (i, j) -> Dyn.Tuple [ Dyn.int i; Dyn.int j ] )
       ]);
  [%expect {| { offset = (6, 8) } |}];
  print_dyn (Dyn.record [ "stop", Re.Group.stop group wo_index |> Dyn.int ]);
  [%expect {| { stop = 8 } |}];
  ()
;;
