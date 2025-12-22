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

open! Import

module Annotation_severity = struct
  type t =
    | Error
    | Warning
    | Info

  let variant_constructor_name = function
    | Error -> "Error"
    | Warning -> "Warning"
    | Info -> "Info"
  ;;

  let to_dyn t = Dyn.Variant (variant_constructor_name t, [])
  let to_json t : Json.t = `String (variant_constructor_name t)

  let of_string = function
    | "Error" -> Some Error
    | "Warning" -> Some Warning
    | "Info" -> Some Info
    | _ -> None
  ;;
end

module User_handle = struct
  type t = Vcs.User_handle.t

  let to_dyn t = Dyn.stringable (module Vcs.User_handle) t
  let to_json t : Json.t = `String (Vcs.User_handle.to_string t)

  let of_json json =
    match (json : Json.t) with
    | `String str ->
      (match Vcs.User_handle.of_string str with
       | Ok t -> t
       | Error (`Msg msg) -> raise (Json.Error (json, msg)))
    | _ -> raise (Json.Error (json, "User handle expected to be a json string."))
  ;;
end

module User_list = struct
  type t = User_handle.t list

  let of_json json : t =
    match (json : Json.t) with
    | `List xs -> List.map xs ~f:User_handle.of_json
    | _ ->
      raise (Json.Error (json, "User handle list expected to be a list of json strings."))
  ;;
end

type t =
  { default_repo_owner : User_handle.t option
  ; user_mentions_allowlist : User_handle.t list option
  ; invalid_crs_annotation_severity : Annotation_severity.t option
  ; crs_due_now_annotation_severity : Annotation_severity.t option
  }

let to_dyn
      { default_repo_owner
      ; user_mentions_allowlist
      ; invalid_crs_annotation_severity
      ; crs_due_now_annotation_severity
      }
  =
  let opt field d = function
    | None -> []
    | Some v -> [ field, d v ]
  in
  Dyn.record
    (List.concat
       [ default_repo_owner |> opt "default_repo_owner" User_handle.to_dyn
       ; user_mentions_allowlist
         |> opt "user_mentions_allowlist" (Dyn.list User_handle.to_dyn)
       ; invalid_crs_annotation_severity
         |> opt "invalid_crs_annotation_severity" Annotation_severity.to_dyn
       ; crs_due_now_annotation_severity
         |> opt "crs_due_now_annotation_severity" Annotation_severity.to_dyn
       ])
;;

let to_json
      { default_repo_owner
      ; user_mentions_allowlist
      ; invalid_crs_annotation_severity
      ; crs_due_now_annotation_severity
      }
  : Json.t
  =
  let opt field to_json = function
    | None -> []
    | Some v -> [ field, to_json v ]
  in
  `Assoc
    (List.concat
       [ default_repo_owner |> opt "default_repo_owner" User_handle.to_json
       ; user_mentions_allowlist
         |> opt "user_mentions_allowlist" (fun xs ->
           `List (List.map xs ~f:User_handle.to_json))
       ; invalid_crs_annotation_severity
         |> opt "invalid_crs_annotation_severity" Annotation_severity.to_json
       ; crs_due_now_annotation_severity
         |> opt "crs_due_now_annotation_severity" Annotation_severity.to_json
       ])
;;

let get_json_enum_constructor json ~loc ~field_name =
  match json with
  | `String str -> `Unwrapped str
  | `List [ `String str ] -> `Wrapped str
  | _ ->
    Err.raise
      ~loc
      Pp.O.
        [ Pp.text "In: " ++ Pp.text (Json.to_string json)
        ; Pp.text "Field "
          ++ Pp_tty.kwd (module String) field_name
          ++ Pp.text " expected to be a json string."
        ]
;;

let raise_duplicate_field ~loc field_name =
  Err.raise
    ~loc
    Pp.O.
      [ Pp.text "Json object field "
        ++ Pp_tty.kwd (module String) field_name
        ++ Pp.text " is duplicated in this config."
      ]
;;

let set_field_once ~loc ~field_name ref_cell value =
  match !ref_cell with
  | Some _ -> raise_duplicate_field ~loc field_name
  | None -> ref_cell := Some value
;;

let parse_severity_field ~loc ~emit_github_annotations ~field_name json =
  let parse_string str =
    match Annotation_severity.of_string str with
    | Some t -> t
    | None ->
      Err.raise
        ~loc
        Pp.O.
          [ Pp.text "Field " ++ Pp_tty.kwd (module String) field_name ++ Pp.text ":"
          ; Pp.textf "Unsupported annotation severity %S." str
          ]
  in
  match get_json_enum_constructor json ~loc ~field_name with
  | `Unwrapped str -> parse_string str
  | `Wrapped str ->
    let severity = parse_string str in
    User_message.warning
      ~loc
      ~emit_github_annotations
      Pp.O.
        [ Pp.text "The config field name "
          ++ Pp_tty.kwd (module String) field_name
          ++ Pp.text " is now expected to be a json string rather than a list."
        ]
      ~hints:[ Pp.textf "Change it to simply: %S" str ];
    severity
;;

let parse_json json ~loc ~emit_github_annotations =
  match json with
  | `Assoc fields ->
    let default_repo_owner_ref = ref None in
    let user_mentions_allowlist_ref = ref None in
    let invalid_crs_annotation_severity_ref = ref None in
    let crs_due_now_annotation_severity_ref = ref None in
    List.iter fields ~f:(fun (field_name, value) ->
      match field_name with
      | "$schema" ->
        (* This allows $schema to be present without causing a warning. *)
        ()
      | "default_repo_owner" ->
        set_field_once ~loc ~field_name default_repo_owner_ref (User_handle.of_json value)
      | "user_mentions_allowlist" ->
        set_field_once
          ~loc
          ~field_name
          user_mentions_allowlist_ref
          (User_list.of_json value)
      | "user_mentions_whitelist" ->
        (* See [upgrading-crs] guide in the documentation for more details about
           deprecated fields and compatibility transitions in the configs. *)
        User_message.warning
          ~loc
          ~emit_github_annotations
          Pp.O.
            [ Pp.text "The config field name "
              ++ Pp_tty.kwd (module String) field_name
              ++ Pp.text " is deprecated and was renamed "
              ++ Pp_tty.kwd (module String) "user_mentions_allowlist"
              ++ Pp.text "."
            ]
          ~hints:[ Pp.text "Upgrade the config to use the new name." ];
        set_field_once
          ~loc
          ~field_name:"user_mentions_allowlist"
          user_mentions_allowlist_ref
          (User_list.of_json value)
      | "invalid_crs_annotation_severity" ->
        set_field_once
          ~loc
          ~field_name
          invalid_crs_annotation_severity_ref
          (parse_severity_field ~loc ~emit_github_annotations ~field_name value)
      | "crs_due_now_annotation_severity" ->
        set_field_once
          ~loc
          ~field_name
          crs_due_now_annotation_severity_ref
          (parse_severity_field ~loc ~emit_github_annotations ~field_name value)
      | _ ->
        User_message.warning
          ~loc
          ~emit_github_annotations
          [ Pp.textf "Unknown config field \"%s\"." field_name ]
          ~hints:[ Pp.text "Check the documentation for valid field names." ]);
    { default_repo_owner = !default_repo_owner_ref
    ; user_mentions_allowlist = !user_mentions_allowlist_ref
    ; invalid_crs_annotation_severity = !invalid_crs_annotation_severity_ref
    ; crs_due_now_annotation_severity = !crs_due_now_annotation_severity_ref
    }
  | _ -> Err.raise ~loc [ Pp.text "Config expected to be a json object." ]
;;

let default_repo_owner t = t.default_repo_owner
let user_mentions_allowlist t = t.user_mentions_allowlist
let invalid_crs_annotation_severity t = t.invalid_crs_annotation_severity
let crs_due_now_annotation_severity t = t.crs_due_now_annotation_severity

let create
      ?default_repo_owner
      ?user_mentions_allowlist
      ?invalid_crs_annotation_severity
      ?crs_due_now_annotation_severity
      ()
  =
  { default_repo_owner
  ; user_mentions_allowlist
  ; invalid_crs_annotation_severity
  ; crs_due_now_annotation_severity
  }
;;

let empty =
  { default_repo_owner = None
  ; user_mentions_allowlist = None
  ; invalid_crs_annotation_severity = None
  ; crs_due_now_annotation_severity = None
  }
;;

let load_exn ~path ~emit_github_annotations =
  match Yojson_five.Basic.from_file (Fpath.to_string path) with
  | Ok json ->
    let loc = Loc.of_file ~path in
    (try parse_json json ~loc ~emit_github_annotations with
     | Json.Error (json, msg) ->
       Err.raise
         ~loc
         Pp.O.
           [ Pp.text "Invalid config."
           ; Pp.text "In: " ++ Pp.text (Json.to_string json)
           ; Pp.text msg
           ])
  | Error msg ->
    Err.raise ~loc:(Loc.of_file ~path) [ Pp.text "Not a valid json file."; Pp.text msg ]
;;
