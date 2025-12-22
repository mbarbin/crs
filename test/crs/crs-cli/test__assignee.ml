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

module Assignee = Crs_cli.Private.Assignee
module Config = Crs_cli.Private.Config

let%expect_test "reasons" =
  List.iter Assignee.Reason.all ~f:(fun reason ->
    print_dyn
      (Dyn.record
         [ "reason", reason |> Assignee.Reason.to_dyn
         ; "text", Assignee.Reason.to_string_hum reason |> Dyn.string
         ]));
  [%expect
    {|
    { reason = Not_due_now; text = "CR not due now" }
    { reason = Recipient; text = "CR recipient" }
    { reason = Reporter; text = "CR reporter" }
    { reason = Default_repo_owner; text = "default repo owner" }
    { reason = No_default_repo_owner; text = "no default repo owner configured" }
    { reason = Pull_request_author; text = "PR author" }
    |}];
  ()
;;

let path = Vcs.Path_in_repo.v "my_file.ml"

let test file_contents ~config ~review_mode =
  let crs = Tests_helpers.parse_file ~path ~file_contents in
  List.iter crs ~f:(fun cr ->
    let assignee = Assignee.compute ~cr ~config ~review_mode in
    print_endline "========================";
    print_endline (Cr_comment.reindented_content cr);
    print_dyn (Dyn.record [ "assignee", assignee |> Assignee.to_dyn ]))
;;

let%expect_test "compute" =
  let config = Config.create ~default_repo_owner:(Vcs.User_handle.v "owner") () in
  test Tests_helpers.test_cases ~config ~review_mode:Revision;
  [%expect
    {|
    ========================
    CR user: Hello.
    { assignee = { user = Some "owner"; reason = Default_repo_owner } }
    ========================
    CR user for user2: Hello.
    { assignee = { user = Some "user2"; reason = Recipient } }
    ========================
    XCR user: Hello.
    { assignee = { user = Some "user"; reason = Reporter } }
    ========================
    XCR user for user2: Hello.
    { assignee = { user = Some "user"; reason = Reporter } }
    ========================
    CR-user: Invalid.
    { assignee = { user = Some "owner"; reason = Default_repo_owner } }
    ========================
    XCR-user: Invalid.
    { assignee = { user = Some "owner"; reason = Default_repo_owner } }
    ========================
    CR-soon user: Hello.
    { assignee = { user = None; reason = Not_due_now } }
    ========================
    CR-someday user: Hello.
    { assignee = { user = None; reason = Not_due_now } }
    ========================
    XCR-soon user: Hello.
    { assignee = { user = Some "user"; reason = Reporter } }
    ========================
    XCR-someday user: Hello.
    { assignee = { user = Some "user"; reason = Reporter } }
    |}];
  let config = Config.create ~default_repo_owner:(Vcs.User_handle.v "owner") () in
  test
    Tests_helpers.test_cases
    ~config
    ~review_mode:(Pull_request { author = Vcs.User_handle.v "pr-author"; base = None });
  [%expect
    {|
    ========================
    CR user: Hello.
    { assignee = { user = Some "pr-author"; reason = Pull_request_author } }
    ========================
    CR user for user2: Hello.
    { assignee = { user = Some "user2"; reason = Recipient } }
    ========================
    XCR user: Hello.
    { assignee = { user = Some "user"; reason = Reporter } }
    ========================
    XCR user for user2: Hello.
    { assignee = { user = Some "user"; reason = Reporter } }
    ========================
    CR-user: Invalid.
    { assignee = { user = Some "pr-author"; reason = Pull_request_author } }
    ========================
    XCR-user: Invalid.
    { assignee = { user = Some "pr-author"; reason = Pull_request_author } }
    ========================
    CR-soon user: Hello.
    { assignee = { user = None; reason = Not_due_now } }
    ========================
    CR-someday user: Hello.
    { assignee = { user = None; reason = Not_due_now } }
    ========================
    XCR-soon user: Hello.
    { assignee = { user = Some "user"; reason = Reporter } }
    ========================
    XCR-someday user: Hello.
    { assignee = { user = Some "user"; reason = Reporter } }
    |}];
  ()
;;
