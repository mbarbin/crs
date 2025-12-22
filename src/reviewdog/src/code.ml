(****************************************************************************)
(*  ocaml-reviewdog - A reviewdog diagnostics json serializer for OCaml     *)
(*  SPDX-FileCopyrightText: 2025 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: MIT                                            *)
(****************************************************************************)

type t =
  { value : string
  ; url : string option
  }

let to_json { value; url } : Yojson.Basic.t =
  `Assoc
    (List.concat
       [ [ "value", `String value ]
       ; (match url with
          | None -> []
          | Some u -> [ "url", `String u ])
       ])
;;
