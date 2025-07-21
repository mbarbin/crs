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
    { Reviewdog.Diagnostic_result.source = Some Reviewdog_utils.source
    ; severity = Some Info
    ; diagnostics
    }
  in
  let json = Reviewdog.Diagnostic_result.yojson_of_t diagnostic_result in
  print_endline (Yojson.Safe.pretty_to_string ~std:true json)
;;

let%expect_test "compute" =
  test
    Tests_helpers.test_cases
    ~config:Config.empty
    ~review_mode:Revision
    ~with_user_mentions:true;
  [%expect
    {|
    {
      "source": { "name": "crs", "url": "https://github.com/mbarbin/crs" },
      "severity": "INFO",
      "diagnostics": [
        {
          "message": "This CR is unassigned (no default repo owner configured).",
          "location": {
            "path": "my_file.ml",
            "range": {
              "start": { "line": 1, "column": 1 },
              "end": { "line": 1, "column": 22 }
            }
          },
          "severity": "INFO",
          "originalOutput": "CR user: Hello."
        },
        {
          "message": "This CR is assigned to user2 (CR recipient).",
          "location": {
            "path": "my_file.ml",
            "range": {
              "start": { "line": 2, "column": 1 },
              "end": { "line": 2, "column": 32 }
            }
          },
          "severity": "INFO",
          "originalOutput": "CR user for user2: Hello."
        },
        {
          "message": "This XCR is assigned to user (CR reporter).",
          "location": {
            "path": "my_file.ml",
            "range": {
              "start": { "line": 3, "column": 1 },
              "end": { "line": 3, "column": 23 }
            }
          },
          "severity": "INFO",
          "originalOutput": "XCR user: Hello."
        },
        {
          "message": "This XCR is assigned to user (CR reporter).",
          "location": {
            "path": "my_file.ml",
            "range": {
              "start": { "line": 4, "column": 1 },
              "end": { "line": 4, "column": 33 }
            }
          },
          "severity": "INFO",
          "originalOutput": "XCR user for user2: Hello."
        },
        {
          "message": "This invalid CR is unassigned (no default repo owner configured).",
          "location": {
            "path": "my_file.ml",
            "range": {
              "start": { "line": 5, "column": 1 },
              "end": { "line": 5, "column": 24 }
            }
          },
          "severity": "WARNING",
          "originalOutput": "CR-user: Invalid."
        },
        {
          "message": "This invalid CR is unassigned (no default repo owner configured).",
          "location": {
            "path": "my_file.ml",
            "range": {
              "start": { "line": 6, "column": 1 },
              "end": { "line": 6, "column": 25 }
            }
          },
          "severity": "WARNING",
          "originalOutput": "XCR-user: Invalid."
        },
        {
          "message": "This XCR is assigned to user (CR reporter).",
          "location": {
            "path": "my_file.ml",
            "range": {
              "start": { "line": 9, "column": 1 },
              "end": { "line": 9, "column": 28 }
            }
          },
          "severity": "INFO",
          "originalOutput": "XCR-soon user: Hello."
        },
        {
          "message": "This XCR is assigned to user (CR reporter).",
          "location": {
            "path": "my_file.ml",
            "range": {
              "start": { "line": 10, "column": 1 },
              "end": { "line": 11, "column": 1 }
            }
          },
          "severity": "INFO",
          "originalOutput": "XCR-someday user: Hello."
        }
      ]
    }
    |}];
  let config = Config.create ~invalid_crs_annotation_severity:Error () in
  test
    {|(* $CR-invalid : Invalid *)|}
    ~config
    ~review_mode:Revision
    ~with_user_mentions:false;
  [%expect
    {|
    {
      "source": { "name": "crs", "url": "https://github.com/mbarbin/crs" },
      "severity": "INFO",
      "diagnostics": [
        {
          "message": "This invalid CR is unassigned (no default repo owner configured).",
          "location": {
            "path": "my_file.ml",
            "range": {
              "start": { "line": 1, "column": 1 },
              "end": { "line": 2, "column": 1 }
            }
          },
          "severity": "ERROR",
          "originalOutput": "CR-invalid : Invalid"
        }
      ]
    }
    |}];
  ()
;;
