(****************************************************************************)
(*  ocaml-reviewdog - A reviewdog diagnostics json serializer for OCaml     *)
(*  SPDX-FileCopyrightText: 2025 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                            *)
(****************************************************************************)

type t =
  { path : string
  ; range : Range.t option
  }

let to_json { path; range } : Yojson.Basic.t =
  `Assoc
    (List.concat
       [ [ "path", `String path ]
       ; (match range with
          | None -> []
          | Some r -> [ "range", Range.to_json r ])
       ])
;;
