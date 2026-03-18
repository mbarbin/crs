(*********************************************************************************)
(*  crs - A tool for managing inline review comments embedded in source code     *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: LGPL-3.0-or-later WITH LGPL-3.0-linking-exception   *)
(*********************************************************************************)

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
  let json = Reviewdog.Diagnostic_result.to_json diagnostic_result in
  print_endline (Json.to_string json)
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
      ],
      "source": { "name": "crs", "url": "https://github.com/mbarbin/crs" },
      "severity": "INFO"
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
      ],
      "source": { "name": "crs", "url": "https://github.com/mbarbin/crs" },
      "severity": "INFO"
    }
    |}];
  ()
;;
