(****************************************************************************)
(*  ocaml-reviewdog - A reviewdog diagnostics json serializer for OCaml     *)
(*  SPDX-FileCopyrightText: 2025 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                            *)
(****************************************************************************)

type t =
  { name : string
  ; url : string option
  }

let to_json { name; url } : Yojson.Basic.t =
  `Assoc
    (List.concat
       [ [ "name", `String name ]
       ; (match url with
          | None -> []
          | Some u -> [ "url", `String u ])
       ])
;;
