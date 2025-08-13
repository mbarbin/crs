(********************************************************************************)
(*  crs - A tool for managing code review comments embedded in source code      *)
(*  Copyright (C) 2024-2025 Mathieu Barbin <mathieu.barbin@gmail.com>           *)
(*                                                                              *)
(*  This file is part of crs.                                                   *)
(*                                                                              *)
(*  crs is free software; you can redistribute it and/or modify it under the    *)
(*  terms of the GNU Lesser General Public License as published by the Free     *)
(*  Software Foundation either version 3 of the License, or any later version,  *)
(*  with the LGPL-3.0 Linking Exception.                                        *)
(*                                                                              *)
(*  crs is distributed in the hope that it will be useful, but WITHOUT ANY      *)
(*  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS   *)
(*  FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License and     *)
(*  the file `NOTICE.md` at the root of this repository for more details.       *)
(*                                                                              *)
(*  You should have received a copy of the GNU Lesser General Public License    *)
(*  and the LGPL-3.0 Linking Exception along with this library. If not, see     *)
(*  <http://www.gnu.org/licenses/> and <https://spdx.org>, respectively.        *)
(********************************************************************************)

module Annotation_severity = struct
  type t =
    | Error
    | Warning
    | Info
  [@@deriving of_yojson, sexp_of]
end

open! Ppx_yojson_conv_lib.Yojson_conv.Primitives

module User_handle = struct
  type t = Vcs.User_handle.t [@@deriving sexp_of]

  let t_of_yojson json = json |> string_of_yojson |> Vcs.User_handle.v
end

type t =
  { default_repo_owner : User_handle.t option [@yojson.option] [@sexp.option]
  ; user_mentions_whitelist : User_handle.t list option [@yojson.option] [@sexp.option]
  ; invalid_crs_annotation_severity : Annotation_severity.t option
        [@yojson.option] [@sexp.option]
  ; crs_due_now_annotation_severity : Annotation_severity.t option
        [@yojson.option] [@sexp.option]
  }
[@@deriving of_yojson, sexp_of]

let default_repo_owner t = t.default_repo_owner
let user_mentions_allowlist t = t.user_mentions_whitelist
let invalid_crs_annotation_severity t = t.invalid_crs_annotation_severity
let crs_due_now_annotation_severity t = t.crs_due_now_annotation_severity

let create
      ?default_repo_owner
      ?user_mentions_allowlist:user_mentions_whitelist
      ?invalid_crs_annotation_severity
      ?crs_due_now_annotation_severity
      ()
  =
  { default_repo_owner
  ; user_mentions_whitelist
  ; invalid_crs_annotation_severity
  ; crs_due_now_annotation_severity
  }
;;

let empty =
  { default_repo_owner = None
  ; user_mentions_whitelist = None
  ; invalid_crs_annotation_severity = None
  ; crs_due_now_annotation_severity = None
  }
;;

let load_exn ~path =
  match Yojson_five.Safe.from_file (Fpath.to_string path) with
  | Error msg ->
    Err.raise ~loc:(Loc.of_file ~path) [ Pp.text "Not a valid json file."; Pp.text msg ]
  | Ok json ->
    (match t_of_yojson json with
     | t -> t
     | exception Ppx_yojson_conv_lib.Yojson_conv.Of_yojson_error (exn, json) ->
       Err.raise
         ~loc:(Loc.of_file ~path)
         Pp.O.
           [ Pp.text "Invalid config."
           ; Pp.text "In: " ++ Pp.text (Yojson.Safe.to_string json)
           ; Err.exn exn
           ])
;;
