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
  [@@deriving sexp_of]

  let of_string = function
    | "Error" -> Some Error
    | "Warning" -> Some Warning
    | "Info" -> Some Info
    | _ -> None
  ;;
end

module User_handle = struct
  type t = Vcs.User_handle.t [@@deriving sexp_of]

  let of_yojson json =
    match (json : Yojson.Safe.t) with
    | `String str ->
      (match Vcs.User_handle.of_string str with
       | Ok _ as ok -> ok
       | Error (`Msg msg) -> Error msg)
    | _ -> Error "User handle expected to be a json string."
  ;;
end

module User_list = struct
  type t = User_handle.t list

  let of_yojson json : (t, string) Result.t =
    match (json : Yojson.Safe.t) with
    | `List xs -> Ppx_deriving_yojson_runtime.map_bind User_handle.of_yojson [] xs
    | _ -> Error "User handle list expected to be a list of json strings."
  ;;
end

type t =
  { default_repo_owner : User_handle.t option [@sexp.option]
  ; user_mentions_allowlist : User_handle.t list option [@sexp.option]
  ; invalid_crs_annotation_severity : Annotation_severity.t option [@sexp.option]
  ; crs_due_now_annotation_severity : Annotation_severity.t option [@sexp.option]
  }
[@@deriving sexp_of]

let get_json_field ~loc ~fields ~field_name =
  match
    List.filter_map fields ~f:(fun (name, json) ->
      Option.some_if (String.equal name field_name) json)
  with
  | [] -> None
  | [ f ] -> Some f
  | _ :: _ :: _ ->
    Err.raise
      ~loc
      Pp.O.
        [ Pp.text "Json object field "
          ++ Pp_tty.kwd (module String) field_name
          ++ Pp.text " is duplicated in this config."
        ]
;;

let get_json_enum_constructor json ~loc ~field_name =
  match json with
  | `String str -> `Unwrapped str
  | `List [ `String str ] -> `Wrapped str
  | _ ->
    Err.raise
      ~loc
      Pp.O.
        [ Pp.text "In: " ++ Pp.text (Yojson.Safe.to_string json)
        ; Pp.text "Field "
          ++ Pp_tty.kwd (module String) field_name
          ++ Pp.text " expected to be a json string."
        ]
;;

let parse_json json ~loc ~emit_github_annotations =
  let of_yojson_exn f json =
    match f json with
    | Ok x -> x
    | Error msg ->
      Err.raise
        ~loc
        Pp.O.
          [ Pp.text "Invalid config."
          ; Pp.text "In: " ++ Pp.text (Yojson.Safe.to_string json)
          ; Pp.text msg
          ]
  in
  match json with
  | `Assoc fields ->
    (* Track which fields have been accessed *)
    let used_fields = Hash_set.create (module String) in
    let field field_name =
      Hash_set.add used_fields field_name;
      get_json_field ~loc ~fields ~field_name
    in
    let default_repo_owner =
      match field "default_repo_owner" with
      | Some json -> Some (of_yojson_exn User_handle.of_yojson json)
      | None -> None
    in
    let user_mentions_allowlist =
      let field_name = "user_mentions_allowlist" in
      match field field_name with
      | Some json -> Some (of_yojson_exn User_list.of_yojson json)
      | None ->
        (* See [upgrading-crs] guide in the documentation for more details about
           deprecated fields and compatibility transitions in the configs. *)
        let deprecated_field_name = "user_mentions_whitelist" in
        (match field deprecated_field_name with
         | None -> None
         | Some json ->
           User_message.warning
             ~loc
             ~emit_github_annotations
             Pp.O.
               [ Pp.text "The config field name "
                 ++ Pp_tty.kwd (module String) deprecated_field_name
                 ++ Pp.text " is deprecated and was renamed "
                 ++ Pp_tty.kwd (module String) field_name
                 ++ Pp.text "."
               ]
             ~hints:[ Pp.text "Upgrade the config to use the new name." ];
           Some (of_yojson_exn User_list.of_yojson json))
    in
    let severity_field ~field_name =
      match field field_name with
      | None -> None
      | Some json ->
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
        (match get_json_enum_constructor json ~loc ~field_name with
         | `Unwrapped str -> Some (parse_string str)
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
           Some severity)
    in
    let invalid_crs_annotation_severity =
      severity_field ~field_name:"invalid_crs_annotation_severity"
    in
    let crs_due_now_annotation_severity =
      severity_field ~field_name:"crs_due_now_annotation_severity"
    in
    (* Emit warnings for any unknown fields *)
    List.iter fields ~f:(fun (name, _) ->
      if not (Hash_set.mem used_fields name)
      then
        User_message.warning
          ~loc
          ~emit_github_annotations
          Pp.O.[ Pp.text "Unknown config field: " ++ Pp_tty.kwd (module String) name ]
          ~hints:[ Pp.text "Check the documentation for valid field names." ]);
    { default_repo_owner
    ; user_mentions_allowlist
    ; invalid_crs_annotation_severity
    ; crs_due_now_annotation_severity
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
  match Yojson_five.Safe.from_file (Fpath.to_string path) with
  | Ok json -> parse_json json ~loc:(Loc.of_file ~path) ~emit_github_annotations
  | Error msg ->
    Err.raise ~loc:(Loc.of_file ~path) [ Pp.text "Not a valid json file."; Pp.text msg ]
;;
