(***************************************************************************************)
(*  Crs_stdlib - Extending OCaml's Stdlib for crs                                      *)
(*  SPDX-FileCopyrightText: 2025-2026 Mathieu Barbin <mathieu.barbin@gmail.com>        *)
(*  SPDX-License-Identifier: MIT OR LGPL-3.0-or-later WITH LGPL-3.0-linking-exception  *)
(***************************************************************************************)

type t =
  { message : string
  ; data : (string * Dyn.t) list
  }

exception E of t

let raise message data = raise (E { message; data })
let to_dyn { message; data } = Dyn.Tuple [ Dyn.String message; Record data ]

let () =
  Printexc.register_printer (function
    | E t -> Some (Dyn.to_string (to_dyn t))
    | _ -> None [@coverage off])
;;
