(********************************************************************************)
(*  crs - A tool to parse code review comments embedded in source code          *)
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

(* This module is derived from Iron (v0.9.114.44+47), file
   * [./hg/cr_comment.ml], which is released under Apache 2.0:
   *
   * Copyright (c) 2016-2017 Jane Street Group, LLC <opensource-contacts@janestreet.com>
   *
   * Licensed under the Apache License, Version 2.0 (the "License"); you may not
   * use this file except in compliance with the License. You may obtain a copy
   * of the License at:
   *
   *     http://www.apache.org/licenses/LICENSE-2.0
   *
   * Unless required by applicable law or agreed to in writing, software
   * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
   * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
   * License for the specific language governing permissions and limitations
   * under the License.
   *
   * See the file `NOTICE.md` at the root of this repository for more details.
   *
   * Changes:
   *
   * - Migrate to this file only the part that relates to grepping versioned files.
   * - Remove dependency to [Core] - make small adjustments to use [Base] instead.
   * - Remove dependency to [Async] - replace by [Shexp] and [Stdio].
   * - Use [Vcs] instead of [Hg].
*)

let grep ~vcs ~repo_root ~below =
  let files_to_grep = Vcs.ls_files vcs ~repo_root ~below in
  let stdin =
    files_to_grep |> List.map ~f:Vcs.Path_in_repo.to_string |> String.concat ~sep:"\n"
  in
  let files_to_grep =
    let context =
      Shexp_process.Context.create ~cwd:(Path (Vcs.Repo_root.to_string repo_root)) ()
    in
    let process =
      Shexp_process.pipe
        (Shexp_process.echo stdin)
        (Shexp_process.capture
           [ Stdout ]
           (Shexp_process.call_exit_code
              [ "xargs"
              ; "-r"
              ; "-d"
              ; "\n"
              ; "grep"
              ; "--no-messages"
              ; "-E"
              ; "-l"
              ; "--binary-files=without-match"
              ; File_parser.cr_pattern_egrep
              ]))
    in
    let exit_code, stdout = Shexp_process.eval ~context process in
    match exit_code with
    | 0 | 123 -> stdout |> String.split_lines |> List.map ~f:Vcs.Path_in_repo.v
    | _ -> raise_s [%sexp "xargs process failed", { exit_code : int }]
  in
  List.concat_map files_to_grep ~f:(fun path_in_repo ->
    let file_contents =
      In_channel.read_all
        (Vcs.Repo_root.append repo_root path_in_repo |> Absolute_path.to_string)
      |> Vcs.File_contents.create
    in
    File_parser.extract ~path:path_in_repo ~file_contents)
;;
