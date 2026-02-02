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
