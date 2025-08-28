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

module T = struct
  [@@@coverage off]

  type t =
    | Pull_request of
        { author : Vcs.User_handle.t
        ; base : Vcs.Rev.t option
        }
    | Revision
  [@@deriving equal, sexp_of]
end

include T

module Name = struct
  type t =
    | Pull_request
    | Revision

  let to_string = function
    | Pull_request -> "pull-request"
    | Revision -> "revision"
  ;;
end

module Name_compatibility = struct
  (* For a few releases we accept "commit" as former name for "revision" as a
     compatibility mode. We'll drop this support at some future point. *)

  type t =
    | Pull_request
    | Commit
    | Revision
  [@@deriving enumerate]

  let to_name : t -> Name.t = function
    | Pull_request -> Pull_request
    | Commit | Revision -> Revision
  ;;

  let to_string = function
    | Commit -> "commit"
    | (Pull_request | Revision) as t -> Name.to_string (to_name t)
  ;;
end

let arg ~print_gh_annotation_warnings =
  let open Command.Std in
  let pull_request_author_switch = "pull-request-author" in
  let pull_request_base_switch = "pull-request-base" in
  let review_mode_switch = "review-mode" in
  let+ name =
    Arg.named_with_default
      [ review_mode_switch ]
      (Param.enumerated ~docv:"MODE" (module Name_compatibility))
      ~default:Revision
      ~doc:
        "Specifies the review context in which this command is executed. Use \
         $(b,pull-request) when running in the context of a pull request (requires \
         $(b,--pull-request-{author,base})). Use $(b,revision) when running in the \
         context of a push to a branch (default). This setting affects how CRs are \
         assigned and annotated. As a compatibility transition, this command accepts the \
         $(b,commit) parameter as an alias for $(b,revision), however this should not be \
         used in new code."
  and+ pull_request_author =
    Arg.named_opt
      [ pull_request_author_switch ]
      (Param.validated_string ~docv:"AUTHOR" (module Vcs.User_handle))
      ~doc:
        (Printf.sprintf
           "When $(b,--%s) is a pull-request this argument must be supplied to set the \
            PR author."
           review_mode_switch)
  and+ pull_request_base =
    Arg.named_opt
      [ pull_request_base_switch ]
      (Param.validated_string ~docv:"REV" (module Vcs.Rev))
      ~doc:
        (Printf.sprintf
           "When $(b,--%s) is a pull-request this argument must be supplied to set the \
            PR base."
           review_mode_switch)
  in
  let () =
    match name with
    | Pull_request | Revision -> ()
    | Commit ->
      let messages =
        Pp.O.
          [ Pp.verbatim "Parameter "
            ++ Pp_tty.id (module Name_compatibility) Commit
            ++ Pp.verbatim " for "
            ++ Pp_tty.kwd (module String) ("--" ^ review_mode_switch)
            ++ Pp.verbatim " was renamed "
            ++ Pp_tty.id (module Name_compatibility) Revision
            ++ Pp.text "."
          ; Pp.verbatim "Please attend."
          ]
      in
      User_message.warning ~print_gh_annotation_warnings messages
  in
  (* Both errors are covered but disabled due to an issue with bisect_ppx out
     edge creating false negative. *)
  match Name_compatibility.to_name name with
  | Revision ->
    let () =
      if Option.is_some pull_request_author
      then
        Err.raise
          ~exit_code:Err.Exit_code.cli_error
          Pp.O.
            [ Pp_tty.kwd (module String) ("--" ^ pull_request_author_switch)
              ++ Pp.text " should not be set when review mode is "
              ++ Pp_tty.kwd (module Name) Revision
              ++ Pp.text "."
            ] [@coverage off];
      if Option.is_some pull_request_base
      then
        Err.raise
          ~exit_code:Err.Exit_code.cli_error
          Pp.O.
            [ Pp_tty.kwd (module String) ("--" ^ pull_request_base_switch)
              ++ Pp.text " should not be set when review mode is "
              ++ Pp_tty.kwd (module Name) Revision
              ++ Pp.text "."
            ] [@coverage off];
      ()
    in
    Revision
  | Pull_request ->
    let author =
      match pull_request_author with
      | Some author -> author
      | None ->
        Err.raise
          ~exit_code:Err.Exit_code.cli_error
          Pp.O.
            [ Pp.text "Review mode "
              ++ Pp_tty.kwd (module String) "pull-request"
              ++ Pp.text " requires "
              ++ Pp_tty.kwd (module String) ("--" ^ pull_request_author_switch)
              ++ Pp.text "."
            ] [@coverage off]
    in
    let base =
      (match pull_request_base with
       | Some _ -> ()
       | None ->
         let messages =
           Pp.O.
             [ Pp.verbatim "Review mode "
               ++ Pp_tty.kwd (module String) "pull-request"
               ++ Pp.verbatim " requires "
               ++ Pp_tty.kwd (module String) ("--" ^ pull_request_base_switch)
               ++ Pp.verbatim "."
             ; Pp.verbatim "It will become mandatory in the future, please attend."
             ]
         in
         User_message.warning ~print_gh_annotation_warnings messages);
      pull_request_base
    in
    Pull_request { author; base }
;;
