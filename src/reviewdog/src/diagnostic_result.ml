(****************************************************************************)
(*  ocaml-reviewdog - A reviewdog diagnostics json serializer for OCaml     *)
(*  SPDX-FileCopyrightText: 2025 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                            *)
(****************************************************************************)

type t =
  { source : Source.t option
  ; severity : Severity.t option
  ; diagnostics : Diagnostic.t list
  }

let to_json { source; severity; diagnostics } : Yojson.Basic.t =
  `Assoc
    (List.concat
       [ [ "diagnostics", `List (List.map Diagnostic.to_json diagnostics) ]
       ; (match source with
          | None -> []
          | Some s -> [ "source", Source.to_json s ])
       ; (match severity with
          | None -> []
          | Some s -> [ "severity", Severity.to_json s ])
       ])
;;
