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

module T = struct
  [@@@coverage off]

  type t =
    | Pull_request of { author : Vcs.User_handle.t }
    | Commit
  [@@deriving equal, sexp_of]
end

include T

module Name = struct
  type t =
    | Pull_request
    | Commit
  [@@deriving enumerate]

  let to_string = function
    | Pull_request -> "pull-request"
    | Commit -> "commit"
  ;;
end

let arg =
  let open Command.Std in
  let pull_request_author_switch = "pull-request-author" in
  let review_mode_switch = "review-mode" in
  let+ name =
    Arg.named_with_default
      [ review_mode_switch ]
      (Param.enumerated ~docv:"MODE" (module Name))
      ~default:Commit
      ~doc:
        "Specifies the review context in which this command is executed. Use \
         $(b,pull-request) when running in the context of a pull request (requires \
         $(b,--pull-request-author)). Use $(b,commit) when running in the context of a \
         direct commit or push to a branch (default). This setting affects how CRs are \
         assigned and annotated."
  and+ pull_request_author =
    Arg.named_opt
      [ pull_request_author_switch ]
      (Param.validated_string ~docv:"AUTHOR" (module Vcs.User_handle))
      ~doc:
        (Printf.sprintf
           "When $(b,--%s) is a pull-request this argument must be supplied to set the \
            PR author."
           review_mode_switch)
  in
  (* Both errors are covered but disabled due to an issue with bisect_ppx out
     edge creating false negative. *)
  match name with
  | Commit ->
    let () =
      if Option.is_some pull_request_author
      then
        Err.raise
          ~exit_code:Err.Exit_code.cli_error
          Pp.O.
            [ Pp.text "Argument "
              ++ Pp_tty.kwd (module String) ("--" ^ pull_request_author_switch)
              ++ Pp.text " should not be set when review mode is "
              ++ Pp_tty.kwd (module String) "commit"
              ++ Pp.text "."
            ] [@coverage off]
    in
    Commit
  | Pull_request ->
    let author =
      match pull_request_author with
      | Some author -> author
      | None ->
        Err.raise
          ~exit_code:Err.Exit_code.cli_error
          Pp.O.
            [ Pp.text "Argument "
              ++ Pp_tty.kwd (module String) ("--" ^ pull_request_author_switch)
              ++ Pp.text " should be set when review mode is "
              ++ Pp_tty.kwd (module String) "pull-request"
              ++ Pp.text "."
            ] [@coverage off]
    in
    Pull_request { author }
;;
