(****************************************************************************)
(*  ocaml-reviewdog - A reviewdog diagnostics json serializer for OCaml     *)
(*  SPDX-FileCopyrightText: 2025 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                            *)
(****************************************************************************)

type t =
  { message : string option
  ; location : Location.t
  }

let to_json { message; location } : Yojson.Basic.t =
  `Assoc
    (List.concat
       [ (match message with
          | None -> []
          | Some m -> [ "message", `String m ])
       ; [ "location", Location.to_json location ]
       ])
;;
