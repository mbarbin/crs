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

module Annotation = Crs_cli.Private.Annotation
module Assignee = Crs_cli.Private.Assignee
module Config = Crs_cli.Private.Config
module Github_annotation = Crs_parser.Private.Github_annotation

let path = Vcs.Path_in_repo.v "my_file.ml"

let%expect_test "to_dyn" =
  let file_contents = {|(* $CR user1 for user2: Hello. *)|} in
  let crs = Tests_helpers.parse_file ~path ~file_contents in
  List.iter crs ~f:(fun cr ->
    let annotation =
      Annotation.of_cr
        ~cr
        ~config:Config.empty
        ~review_mode:Revision
        ~with_user_mentions:false
    in
    print_dyn (annotation |> Dyn.option Annotation.to_dyn);
    ());
  [%expect
    {|
    Some
      { cr =
          { path = "my_file.ml"
          ; whole_loc = "_"
          ; content_start_offset = 3
          ; header =
              Ok
                { status = CR
                ; qualifier = None
                ; reporter = "user1"
                ; recipient = Some "user2"
                }
          ; comment_prefix = "(*"
          ; digest_of_condensed_content = "545e005050bf423184690dadd4c3393d"
          ; content = "CR user1 for user2: Hello."
          }
      ; severity = Info
      ; assignee = { user = Some "user2"; reason = Recipient }
      ; with_user_mention = false
      ; title = "CR"
      ; message = "This CR is assigned to user2 (CR recipient)."
      }
    |}];
  ()
;;

let%expect_test "severity" =
  List.iter Annotation.Severity.all ~f:(fun severity ->
    let on_github = Annotation.Severity.to_github severity in
    print_dyn
      (Dyn.record
         [ "severity", severity |> Annotation.Severity.to_dyn
         ; "on_github", on_github |> Github_annotation.Severity.to_dyn
         ]));
  [%expect
    {|
    { severity = Error; on_github = Error }
    { severity = Warning; on_github = Warning }
    { severity = Info; on_github = Notice }
    |}];
  ()
;;

let%expect_test "getters" =
  let t =
    let file_contents = {|(* $CR user1 for user2: Hello. *)|} in
    let crs = Tests_helpers.parse_file ~path ~file_contents in
    match
      List.filter_map crs ~f:(fun cr ->
        Annotation.of_cr
          ~cr
          ~config:Config.empty
          ~review_mode:Revision
          ~with_user_mentions:false)
    with
    | [ hd ] -> hd
    | _ -> assert false
  in
  print_dyn
    (Dyn.record
       [ "severity", Annotation.severity t |> Annotation.Severity.to_dyn
       ; "assignee", Annotation.assignee t |> Assignee.to_dyn
       ; "with_user_mention", Annotation.with_user_mention t |> Dyn.bool
       ; "message", Annotation.message t |> Dyn.string
       ]);
  [%expect
    {|
    { severity = Info
    ; assignee = { user = Some "user2"; reason = Recipient }
    ; with_user_mention = false
    ; message = "This CR is assigned to user2 (CR recipient)."
    }
    |}];
  ()
;;

let test file_contents ~config ~review_mode ~with_user_mentions =
  let crs = Tests_helpers.parse_file ~path ~file_contents in
  Ref.set_temporarily Loc.include_sexp_of_locs true ~f:(fun () ->
    List.iter crs ~f:(fun cr ->
      print_endline "========================";
      print_endline (Cr_comment.reindented_content cr);
      match Annotation.of_cr ~cr ~config ~review_mode ~with_user_mentions with
      | None -> print_endline "No annotation generated."
      | Some annotation ->
        print_endline
          (Printf.sprintf
             "%s: %s"
             (Annotation.severity annotation |> Annotation.Severity.to_string)
             (Annotation.message annotation))))
;;

let%expect_test "compute" =
  test
    Tests_helpers.test_cases
    ~config:Config.empty
    ~review_mode:Revision
    ~with_user_mentions:true;
  [%expect
    {|
    ========================
    CR user: Hello.
    Info: This CR is unassigned (no default repo owner configured).
    ========================
    CR user for user2: Hello.
    Info: This CR is assigned to user2 (CR recipient).
    ========================
    XCR user: Hello.
    Info: This XCR is assigned to user (CR reporter).
    ========================
    XCR user for user2: Hello.
    Info: This XCR is assigned to user (CR reporter).
    ========================
    CR-user: Invalid.
    Warning: This invalid CR is unassigned (no default repo owner configured).
    ========================
    XCR-user: Invalid.
    Warning: This invalid CR is unassigned (no default repo owner configured).
    ========================
    CR-soon user: Hello.
    No annotation generated.
    ========================
    CR-someday user: Hello.
    No annotation generated.
    ========================
    XCR-soon user: Hello.
    Info: This XCR is assigned to user (CR reporter).
    ========================
    XCR-someday user: Hello.
    Info: This XCR is assigned to user (CR reporter).
    |}];
  let config =
    let user = Vcs.User_handle.v "user" in
    let user2 = Vcs.User_handle.v "user2" in
    Config.create ~default_repo_owner:user ~user_mentions_allowlist:[ user; user2 ] ()
  in
  test Tests_helpers.test_cases ~config ~review_mode:Revision ~with_user_mentions:true;
  [%expect
    {|
    ========================
    CR user: Hello.
    Info: This CR is assigned to @user (default repo owner).
    ========================
    CR user for user2: Hello.
    Info: This CR is assigned to @user2 (CR recipient).
    ========================
    XCR user: Hello.
    Info: This XCR is assigned to @user (CR reporter).
    ========================
    XCR user for user2: Hello.
    Info: This XCR is assigned to @user (CR reporter).
    ========================
    CR-user: Invalid.
    Warning: This invalid CR is assigned to @user (default repo owner).
    ========================
    XCR-user: Invalid.
    Warning: This invalid CR is assigned to @user (default repo owner).
    ========================
    CR-soon user: Hello.
    No annotation generated.
    ========================
    CR-someday user: Hello.
    No annotation generated.
    ========================
    XCR-soon user: Hello.
    Info: This XCR is assigned to @user (CR reporter).
    ========================
    XCR-someday user: Hello.
    Info: This XCR is assigned to @user (CR reporter).
    |}];
  (* Here user3 should not be notified because they are not in the allowlist. *)
  test
    "(* $CR user for user3: Hello. *)"
    ~config
    ~review_mode:Revision
    ~with_user_mentions:true;
  [%expect
    {|
    ========================
    CR user for user3: Hello.
    Info: This CR is assigned to user3 (CR recipient).
    |}];
  let config =
    let user = Vcs.User_handle.v "user" in
    Config.create
      ~default_repo_owner:user
      ~invalid_crs_annotation_severity:Error
      ~crs_due_now_annotation_severity:Warning
      ()
  in
  test
    Tests_helpers.test_cases
    ~config
    ~review_mode:(Pull_request { author = Vcs.User_handle.v "user"; base = None })
    ~with_user_mentions:false;
  [%expect
    {|
    ========================
    CR user: Hello.
    Warning: This CR is assigned to user (PR author).
    ========================
    CR user for user2: Hello.
    Warning: This CR is assigned to user2 (CR recipient).
    ========================
    XCR user: Hello.
    Warning: This XCR is assigned to user (CR reporter).
    ========================
    XCR user for user2: Hello.
    Warning: This XCR is assigned to user (CR reporter).
    ========================
    CR-user: Invalid.
    Error: This invalid CR is assigned to user (PR author).
    ========================
    XCR-user: Invalid.
    Error: This invalid CR is assigned to user (PR author).
    ========================
    CR-soon user: Hello.
    No annotation generated.
    ========================
    CR-someday user: Hello.
    No annotation generated.
    ========================
    XCR-soon user: Hello.
    Warning: This XCR is assigned to user (CR reporter).
    ========================
    XCR-someday user: Hello.
    Warning: This XCR is assigned to user (CR reporter).
    |}];
  ()
;;
