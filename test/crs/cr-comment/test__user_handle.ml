(********************************************************************************)
(*  crs - A tool for managing code review comments embedded in source code      *)
(*  Copyright (C) 2024-2025 Mathieu Barbin <mathieu.barbin@gmail.com>           *)
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

(* At the moment the type used by crs for user-handles found in CR components is
   from the [Vcs] library. We envision future changes where we'll mint a
   dedicated type for that in crs, with different constraints. *)
module User_handle = Vcs.User_handle

let%expect_test "of_string" =
  let or_msg_to_dyn = function
    | Ok user -> Dyn.Variant ("Ok", [ Dyn.string (User_handle.to_string user) ])
    | Error (`Msg msg) ->
      Dyn.Variant ("Error", [ Dyn.Variant ("Msg", [ Dyn.string msg ]) ])
  in
  let test str = print_dyn (or_msg_to_dyn (User_handle.of_string str)) in
  test "user1";
  [%expect {| Ok "user1" |}];
  test "dependabot[bot]";
  [%expect {| Error (Msg "\"dependabot[bot]\": invalid user_handle") |}];
  ()
;;
