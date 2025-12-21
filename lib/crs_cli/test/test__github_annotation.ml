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
module Config = Crs_cli.Private.Config
module Github_annotation = Crs_parser.Private.Github_annotation

let path = Vcs.Path_in_repo.v "my_file.ml"

let test file_contents ~config ~review_mode ~with_user_mentions =
  let crs = Tests_helpers.parse_file ~path ~file_contents in
  Ref.set_temporarily Loc.include_sexp_of_locs true ~f:(fun () ->
    List.iter crs ~f:(fun cr ->
      print_endline "========================";
      print_endline (Cr_comment.reindented_content cr);
      match Annotation.of_cr ~cr ~config ~review_mode ~with_user_mentions with
      | None -> print_endline "No annotation generated."
      | Some annotation ->
        let github_annotation = Annotation.to_github_annotation annotation in
        print_dyn
          (Dyn.record
             [ "github_annotation", github_annotation |> Github_annotation.to_dyn ]);
        print_endline (Github_annotation.to_string github_annotation)))
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
    { github_annotation =
        { loc = { start = "my_file.ml:1:0"; stop = "my_file.ml:1:21" }
        ; severity = Notice
        ; title = "CR"
        ; message = "This CR is unassigned (no default repo owner configured)."
        }
    }
    ::notice file=my_file.ml,line=1,col=1,endLine=1,endColumn=22,title=CR::This CR is unassigned (no default repo owner configured).
    ========================
    CR user for user2: Hello.
    { github_annotation =
        { loc = { start = "my_file.ml:2:0"; stop = "my_file.ml:2:31" }
        ; severity = Notice
        ; title = "CR"
        ; message = "This CR is assigned to user2 (CR recipient)."
        }
    }
    ::notice file=my_file.ml,line=2,col=1,endLine=2,endColumn=32,title=CR::This CR is assigned to user2 (CR recipient).
    ========================
    XCR user: Hello.
    { github_annotation =
        { loc = { start = "my_file.ml:3:0"; stop = "my_file.ml:3:22" }
        ; severity = Notice
        ; title = "XCR"
        ; message = "This XCR is assigned to user (CR reporter)."
        }
    }
    ::notice file=my_file.ml,line=3,col=1,endLine=3,endColumn=23,title=XCR::This XCR is assigned to user (CR reporter).
    ========================
    XCR user for user2: Hello.
    { github_annotation =
        { loc = { start = "my_file.ml:4:0"; stop = "my_file.ml:4:32" }
        ; severity = Notice
        ; title = "XCR"
        ; message = "This XCR is assigned to user (CR reporter)."
        }
    }
    ::notice file=my_file.ml,line=4,col=1,endLine=4,endColumn=33,title=XCR::This XCR is assigned to user (CR reporter).
    ========================
    CR-user: Invalid.
    { github_annotation =
        { loc = { start = "my_file.ml:5:0"; stop = "my_file.ml:5:23" }
        ; severity = Warning
        ; title = "Invalid CR"
        ; message =
            "This invalid CR is unassigned (no default repo owner configured)."
        }
    }
    ::warning file=my_file.ml,line=5,col=1,endLine=5,endColumn=24,title=Invalid CR::This invalid CR is unassigned (no default repo owner configured).
    ========================
    XCR-user: Invalid.
    { github_annotation =
        { loc = { start = "my_file.ml:6:0"; stop = "my_file.ml:6:24" }
        ; severity = Warning
        ; title = "Invalid CR"
        ; message =
            "This invalid CR is unassigned (no default repo owner configured)."
        }
    }
    ::warning file=my_file.ml,line=6,col=1,endLine=6,endColumn=25,title=Invalid CR::This invalid CR is unassigned (no default repo owner configured).
    ========================
    CR-soon user: Hello.
    No annotation generated.
    ========================
    CR-someday user: Hello.
    No annotation generated.
    ========================
    XCR-soon user: Hello.
    { github_annotation =
        { loc = { start = "my_file.ml:9:0"; stop = "my_file.ml:9:27" }
        ; severity = Notice
        ; title = "XCR"
        ; message = "This XCR is assigned to user (CR reporter)."
        }
    }
    ::notice file=my_file.ml,line=9,col=1,endLine=9,endColumn=28,title=XCR::This XCR is assigned to user (CR reporter).
    ========================
    XCR-someday user: Hello.
    { github_annotation =
        { loc = { start = "my_file.ml:10:0"; stop = "my_file.ml:11:0" }
        ; severity = Notice
        ; title = "XCR"
        ; message = "This XCR is assigned to user (CR reporter)."
        }
    }
    ::notice file=my_file.ml,line=10,col=1,endLine=11,endColumn=1,title=XCR::This XCR is assigned to user (CR reporter).
    |}];
  let config = Config.create ~invalid_crs_annotation_severity:Error () in
  test
    {|(* $CR-invalid : Invalid *)|}
    ~config
    ~review_mode:Revision
    ~with_user_mentions:false;
  [%expect
    {|
    ========================
    CR-invalid : Invalid
    { github_annotation =
        { loc = { start = "my_file.ml:1:0"; stop = "my_file.ml:2:0" }
        ; severity = Error
        ; title = "Invalid CR"
        ; message =
            "This invalid CR is unassigned (no default repo owner configured)."
        }
    }
    ::error file=my_file.ml,line=1,col=1,endLine=2,endColumn=1,title=Invalid CR::This invalid CR is unassigned (no default repo owner configured).
    |}];
  ()
;;

let%expect_test "multilines annotations" =
  let github_annotation =
    Github_annotation.create
      ~loc:(Loc.of_file ~path:(Vcs.Path_in_repo.to_relative_path path :> Fpath.t))
      ~severity:Warning
      ~title:"Hello Multiline Message"
      ~message:"This message has\nmultiple lines!"
  in
  print_endline (Github_annotation.to_string github_annotation);
  [%expect
    {| ::warning file=my_file.ml,line=1,col=1,endLine=1,endColumn=1,title=Hello Multiline Message::This message has%0Amultiple lines! |}];
  ()
;;

let%expect_test "no loc" =
  let github_annotation =
    Github_annotation.create
      ~loc:Loc.none
      ~severity:Warning
      ~title:"Hello Loc.none"
      ~message:"This message has no location!"
  in
  print_endline (Github_annotation.to_string github_annotation);
  [%expect {| ::warning title=Hello Loc.none::This message has no location! |}];
  ()
;;
