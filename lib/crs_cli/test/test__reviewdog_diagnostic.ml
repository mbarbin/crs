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
module Reviewdog_utils = Crs_cli.Private.Reviewdog_utils

let path = Vcs.Path_in_repo.v "my_file.ml"

let test file_contents ~config ~review_mode ~with_user_mentions =
  let crs = Tests_helpers.parse_file ~path ~file_contents in
  let diagnostics =
    List.filter_map crs ~f:(fun cr ->
      Annotation.of_cr ~cr ~config ~review_mode ~with_user_mentions
      |> Option.map ~f:Annotation.to_reviewdog_diagnostic)
  in
  let diagnostic_result =
    Reviewdog_rdf.make_diagnostic_result
      ~diagnostics
      ~source:(Some Reviewdog_utils.source)
      ~severity:Info
      ()
  in
  let json = Reviewdog_rdf.encode_json_diagnostic_result diagnostic_result in
  print_endline (Yojson.Basic.pretty_to_string ~std:true json)
;;

let test_cases =
  {|
(* $CR user: Hello. *)
(* $CR user for user2: Hello. *)
(* $XCR user for user2: Hello. *)
(* $CR-user: Invalid. *)
(* $CR-soon user: Hello. *)
(* $CR-someday user: Hello. *)
|}
;;

let%expect_test "compute" =
  test test_cases ~config:Config.empty ~review_mode:Commit ~with_user_mentions:true;
  [%expect
    {|
    {
      "severity": "INFO",
      "source": { "url": "https://github.com/mbarbin/crs", "name": "crs" },
      "diagnostics": [
        {
          "relatedLocations": [],
          "originalOutput": "CR user: Hello.",
          "suggestions": [],
          "severity": "INFO",
          "location": {
            "range": {
              "end": { "column": 22, "line": 1 },
              "start": { "column": 1, "line": 1 }
            },
            "path": "my_file.ml"
          },
          "message": "This CR is unassigned (no default repo owner configured)."
        },
        {
          "relatedLocations": [],
          "originalOutput": "CR user for user2: Hello.",
          "suggestions": [],
          "severity": "INFO",
          "location": {
            "range": {
              "end": { "column": 32, "line": 2 },
              "start": { "column": 1, "line": 2 }
            },
            "path": "my_file.ml"
          },
          "message": "This CR is assigned to user2 (CR recipient)."
        },
        {
          "relatedLocations": [],
          "originalOutput": "XCR user for user2: Hello.",
          "suggestions": [],
          "severity": "INFO",
          "location": {
            "range": {
              "end": { "column": 33, "line": 3 },
              "start": { "column": 1, "line": 3 }
            },
            "path": "my_file.ml"
          },
          "message": "This XCR is assigned to user (CR reporter)."
        },
        {
          "relatedLocations": [],
          "originalOutput": "CR-user: Invalid.",
          "suggestions": [],
          "severity": "WARNING",
          "location": {
            "range": {
              "end": { "column": 24, "line": 4 },
              "start": { "column": 1, "line": 4 }
            },
            "path": "my_file.ml"
          },
          "message": "This invalid CR is unassigned (no default repo owner configured)."
        }
      ]
    }
    |}];
  let config = Config.create ~invalid_crs_annotation_severity:Error () in
  test
    {|(* $CR-invalid : Invalid *)|}
    ~config
    ~review_mode:Commit
    ~with_user_mentions:false;
  [%expect
    {|
    {
      "severity": "INFO",
      "source": { "url": "https://github.com/mbarbin/crs", "name": "crs" },
      "diagnostics": [
        {
          "relatedLocations": [],
          "originalOutput": "CR-invalid : Invalid",
          "suggestions": [],
          "severity": "ERROR",
          "location": {
            "range": {
              "end": { "column": 1, "line": 2 },
              "start": { "column": 1, "line": 1 }
            },
            "path": "my_file.ml"
          },
          "message": "This invalid CR is unassigned (no default repo owner configured)."
        }
      ]
    }
    |}];
  ()
;;
