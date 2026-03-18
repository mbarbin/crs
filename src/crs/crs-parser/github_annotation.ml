(*********************************************************************************)
(*  crs - A tool for managing inline review comments embedded in source code     *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: LGPL-3.0-or-later WITH LGPL-3.0-linking-exception   *)
(*********************************************************************************)

module Severity = struct
  type t =
    | Error
    | Warning
    | Notice

  let variant_constructor_name = function
    | Error -> "Error"
    | Warning -> "Warning"
    | Notice -> "Notice"
  ;;

  let to_dyn t = Dyn.variant (variant_constructor_name t) []

  let to_string = function
    | Error -> "error"
    | Warning -> "warning"
    | Notice -> "notice"
  ;;
end

type t =
  { loc : Loc.t
  ; severity : Severity.t
  ; title : string
  ; message : string
  }

let to_dyn { loc; severity; title; message } =
  Dyn.record
    [ "loc", loc |> Loc.to_dyn
    ; "severity", severity |> Severity.to_dyn
    ; "title", title |> Dyn.string
    ; "message", message |> Dyn.string
    ]
;;

let create ~loc ~severity ~title ~message = { loc; severity; title; message }

let to_loc_fields_internal ~loc =
  let column (pos : Lexing.position) = pos.pos_cnum - pos.pos_bol + 1 in
  let start_pos = Loc.start loc in
  let stop_pos = Loc.stop loc in
  [ "file", Fpath.to_string (Loc.path loc)
  ; "line", Int.to_string start_pos.pos_lnum
  ; "col", Int.to_string (column start_pos)
  ; "endLine", Int.to_string stop_pos.pos_lnum
  ; "endColumn", Int.to_string (column stop_pos)
  ]
;;

let to_loc_fields ~loc = if Loc.is_none loc then [] else to_loc_fields_internal ~loc

let to_string { loc; severity; title; message } =
  let fields = to_loc_fields ~loc @ [ "title", title ] in
  String.concat
    ~sep:""
    [ "::"
    ; Severity.to_string severity
    ; " "
    ; List.map fields ~f:(fun (field, value) -> Printf.sprintf "%s=%s" field value)
      |> String.concat ~sep:","
    ; "::"
    ; String.substr_replace_all message ~pattern:"\n" ~with_:"%0A"
    ]
;;
