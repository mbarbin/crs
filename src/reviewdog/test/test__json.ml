(****************************************************************************)
(*  ocaml-reviewdog - A reviewdog diagnostics json serializer for OCaml     *)
(*  SPDX-FileCopyrightText: 2025 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                            *)
(****************************************************************************)

let print_json json = print_endline (Yojson.Basic.pretty_to_string json ~std:true)

let%expect_test "Severity.to_json" =
  List.iter
    (fun severity -> print_json (Reviewdog.Severity.to_json severity))
    Reviewdog.Severity.all;
  [%expect
    {|
    "UNKNOWN_SEVERITY"
    "ERROR"
    "WARNING"
    "INFO"
    |}]
;;

let%expect_test "Position.to_json" =
  print_json (Reviewdog.Position.to_json { line = 10; column = 5 });
  [%expect {| { "line": 10, "column": 5 } |}]
;;

let%expect_test "Range.to_json" =
  print_json (Reviewdog.Range.to_json { start = { line = 1; column = 1 }; end_ = None });
  [%expect {| { "start": { "line": 1, "column": 1 } } |}];
  print_json
    (Reviewdog.Range.to_json
       { start = { line = 1; column = 1 }; end_ = Some { line = 1; column = 10 } });
  [%expect
    {| { "start": { "line": 1, "column": 1 }, "end": { "line": 1, "column": 10 } } |}]
;;

let%expect_test "Location.to_json" =
  print_json (Reviewdog.Location.to_json { path = "src/main.ml"; range = None });
  [%expect {| { "path": "src/main.ml" } |}];
  print_json
    (Reviewdog.Location.to_json
       { path = "src/main.ml"
       ; range =
           Some
             { start = { line = 5; column = 3 }; end_ = Some { line = 5; column = 15 } }
       });
  [%expect
    {|
    {
      "path": "src/main.ml",
      "range": {
        "start": { "line": 5, "column": 3 },
        "end": { "line": 5, "column": 15 }
      }
    }
    |}]
;;

let%expect_test "Source.to_json" =
  print_json (Reviewdog.Source.to_json { name = "ocaml-lsp"; url = None });
  [%expect {| { "name": "ocaml-lsp" } |}];
  print_json
    (Reviewdog.Source.to_json
       { name = "ocaml-lsp"; url = Some "https://github.com/ocaml/ocaml-lsp" });
  [%expect {| { "name": "ocaml-lsp", "url": "https://github.com/ocaml/ocaml-lsp" } |}]
;;

let%expect_test "Code.to_json" =
  print_json (Reviewdog.Code.to_json { value = "E001"; url = None });
  [%expect {| { "value": "E001" } |}];
  print_json
    (Reviewdog.Code.to_json
       { value = "E001"; url = Some "https://example.com/errors/E001" });
  [%expect {| { "value": "E001", "url": "https://example.com/errors/E001" } |}]
;;

let%expect_test "Suggestion.to_json" =
  print_json
    (Reviewdog.Suggestion.to_json
       { range =
           { start = { line = 1; column = 5 }; end_ = Some { line = 1; column = 10 } }
       ; text = "fixed_name"
       });
  [%expect
    {|
    {
      "range": {
        "start": { "line": 1, "column": 5 },
        "end": { "line": 1, "column": 10 }
      },
      "text": "fixed_name"
    }
    |}]
;;

let%expect_test "Related_location.to_json" =
  print_json
    (Reviewdog.Related_location.to_json
       { message = None; location = { path = "src/other.ml"; range = None } });
  [%expect {| { "location": { "path": "src/other.ml" } } |}];
  print_json
    (Reviewdog.Related_location.to_json
       { message = Some "Related definition here"
       ; location = { path = "src/other.ml"; range = None }
       });
  [%expect
    {|
    {
      "message": "Related definition here",
      "location": { "path": "src/other.ml" }
    }
    |}]
;;

let%expect_test "Diagnostic.to_json" =
  (* Minimal diagnostic. *)
  print_json
    (Reviewdog.Diagnostic.to_json
       { message = "Unused variable 'x'"
       ; location = { path = "src/main.ml"; range = None }
       ; severity = None
       ; source = None
       ; code = None
       ; suggestions = []
       ; original_output = None
       ; related_locations = []
       });
  [%expect
    {| { "message": "Unused variable 'x'", "location": { "path": "src/main.ml" } } |}];
  (* Full diagnostic. *)
  print_json
    (Reviewdog.Diagnostic.to_json
       { message = "Unused variable 'x'"
       ; location =
           { path = "src/main.ml"
           ; range =
               Some
                 { start = { line = 10; column = 5 }
                 ; end_ = Some { line = 10; column = 6 }
                 }
           }
       ; severity = Some Warning
       ; source = Some { name = "ocaml-lsp"; url = None }
       ; code = Some { value = "unused-var"; url = None }
       ; suggestions =
           [ { range =
                 { start = { line = 10; column = 5 }
                 ; end_ = Some { line = 10; column = 6 }
                 }
             ; text = "_x"
             }
           ]
       ; original_output = Some "Warning 26: unused variable x."
       ; related_locations = []
       });
  [%expect
    {|
    {
      "message": "Unused variable 'x'",
      "location": {
        "path": "src/main.ml",
        "range": {
          "start": { "line": 10, "column": 5 },
          "end": { "line": 10, "column": 6 }
        }
      },
      "severity": "WARNING",
      "source": { "name": "ocaml-lsp" },
      "code": { "value": "unused-var" },
      "suggestions": [
        {
          "range": {
            "start": { "line": 10, "column": 5 },
            "end": { "line": 10, "column": 6 }
          },
          "text": "_x"
        }
      ],
      "originalOutput": "Warning 26: unused variable x."
    }
    |}];
  (* Diagnostic with related locations. *)
  print_json
    (Reviewdog.Diagnostic.to_json
       { message = "Variable 'x' shadows previous definition"
       ; location =
           { path = "src/main.ml"
           ; range = Some { start = { line = 20; column = 5 }; end_ = None }
           }
       ; severity = Some Warning
       ; source = None
       ; code = None
       ; suggestions = []
       ; original_output = None
       ; related_locations =
           [ { message = Some "Previous definition here"
             ; location =
                 { path = "src/main.ml"
                 ; range = Some { start = { line = 10; column = 5 }; end_ = None }
                 }
             }
           ; { message = None; location = { path = "src/other.ml"; range = None } }
           ]
       });
  [%expect
    {|
    {
      "message": "Variable 'x' shadows previous definition",
      "location": {
        "path": "src/main.ml",
        "range": { "start": { "line": 20, "column": 5 } }
      },
      "severity": "WARNING",
      "relatedLocations": [
        {
          "message": "Previous definition here",
          "location": {
            "path": "src/main.ml",
            "range": { "start": { "line": 10, "column": 5 } }
          }
        },
        { "location": { "path": "src/other.ml" } }
      ]
    }
    |}]
;;

let%expect_test "Diagnostic_result.to_json" =
  print_json
    (Reviewdog.Diagnostic_result.to_json
       { source = None; severity = None; diagnostics = [] });
  [%expect {| { "diagnostics": [] } |}];
  (* With source and diagnostics. *)
  print_json
    (Reviewdog.Diagnostic_result.to_json
       { source = Some { name = "ocaml-lsp"; url = None }
       ; severity = Some Error
       ; diagnostics =
           [ { message = "Unbound value 'foo'"
             ; location = { path = "src/main.ml"; range = None }
             ; severity = Some Error
             ; source = None
             ; code = None
             ; suggestions = []
             ; original_output = None
             ; related_locations = []
             }
           ]
       });
  [%expect
    {|
    {
      "diagnostics": [
        {
          "message": "Unbound value 'foo'",
          "location": { "path": "src/main.ml" },
          "severity": "ERROR"
        }
      ],
      "source": { "name": "ocaml-lsp" },
      "severity": "ERROR"
    }
    |}]
;;
