(****************************************************************************)
(*  ocaml-reviewdog - A reviewdog diagnostics json serializer for OCaml     *)
(*  SPDX-FileCopyrightText: 2025 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                            *)
(****************************************************************************)

type t =
  { start : Position.t
  ; end_ : Position.t option
  }

let to_json { start; end_ } : Yojson.Basic.t =
  `Assoc
    (List.concat
       [ [ "start", Position.to_json start ]
       ; (match end_ with
          | None -> []
          | Some end_pos -> [ "end", Position.to_json end_pos ])
       ])
;;
