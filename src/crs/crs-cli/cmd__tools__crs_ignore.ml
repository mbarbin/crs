(********************************************************************************)
(*  crs - A tool for managing inline review comments embedded in source code    *)
(*  Copyright (C) 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>           *)
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

let find_crs_ignore_files files_in_repo =
  let filename = Fsegment.to_string Crs_ignore.filename in
  List.filter files_in_repo ~f:(fun file ->
    String.equal filename (Fpath.basename (Vcs.Path_in_repo.to_fpath file)))
;;

let list_included_files_cmd =
  Command.make
    ~summary:"List files that are included when searched for CRs."
    ~readme:(fun () ->
      "This command lists all files that would be included when grepping for CRs, after \
       applying $(b,.crs-ignore) rules.\n\n\
       This is useful for understanding which files are being searched and for debugging \
       $(b,.crs-ignore) configurations.")
    (let open Command.Std in
     let+ below =
       Arg.named_opt
         [ "below" ]
         (Param.validated_string (module Fpath))
         ~docv:"PATH"
         ~doc:"Only list included files located below the supplied path."
     in
     let cwd = Unix.getcwd () |> Absolute_path.v in
     let { Enclosing_repo.repo_root; vcs; vcs_kind = _ } =
       Common_helpers.find_enclosing_repo ~from:cwd
     in
     let files_in_repo = Vcs.ls_files vcs ~repo_root ~below:Vcs.Path_in_repo.root in
     let rules =
       List.map (find_crs_ignore_files files_in_repo) ~f:(fun path ->
         Crs_ignore.File.load_exn
           ~repo_root
           ~path
           ~invalid_patterns_are_errors:false
           ~emit_github_annotations:false)
       |> Crs_ignore.Rules.create
     in
     let below =
       match below with
       | None -> Relative_path.empty
       | Some path ->
         Common_helpers.relativize ~repo_root ~cwd ~path
         |> Vcs.Path_in_repo.to_relative_path
     in
     let included_files =
       List.filter files_in_repo ~f:(fun path ->
         Option.is_some
           (Relative_path.chop_prefix
              ~prefix:below
              (Vcs.Path_in_repo.to_relative_path path))
         && not (Crs_ignore.Rules.is_file_ignored rules ~path))
       |> List.sort ~compare:Vcs.Path_in_repo.compare
     in
     List.iter included_files ~f:(fun file ->
       print_endline (Vcs.Path_in_repo.to_string file)))
;;

let list_ignored_files_cmd =
  Command.make
    ~summary:"List files that are excluded when searched for CRs."
    ~readme:(fun () ->
      "This command lists all files that would be excluded when grepping for CRs, after \
       applying $(b,.crs-ignore) rules.\n\n\
       This is useful for understanding which files are being searched and for debugging \
       $(b,.crs-ignore) configurations.")
    (let open Command.Std in
     let+ below =
       Arg.named_opt
         [ "below" ]
         (Param.validated_string (module Fpath))
         ~docv:"PATH"
         ~doc:"Only list excluded files that are located below the supplied path."
     in
     let cwd = Unix.getcwd () |> Absolute_path.v in
     let { Enclosing_repo.repo_root; vcs; vcs_kind = _ } =
       Common_helpers.find_enclosing_repo ~from:cwd
     in
     let files_in_repo = Vcs.ls_files vcs ~repo_root ~below:Vcs.Path_in_repo.root in
     let rules =
       List.map (find_crs_ignore_files files_in_repo) ~f:(fun path ->
         Crs_ignore.File.load_exn
           ~repo_root
           ~path
           ~invalid_patterns_are_errors:false
           ~emit_github_annotations:false)
       |> Crs_ignore.Rules.create
     in
     let below =
       match below with
       | None -> Relative_path.empty
       | Some path ->
         Common_helpers.relativize ~repo_root ~cwd ~path
         |> Vcs.Path_in_repo.to_relative_path
     in
     let ignored_files =
       List.filter files_in_repo ~f:(fun path ->
         Option.is_some
           (Relative_path.chop_prefix
              ~prefix:below
              (Vcs.Path_in_repo.to_relative_path path))
         && Crs_ignore.Rules.is_file_ignored rules ~path)
       |> List.sort ~compare:Vcs.Path_in_repo.compare
     in
     List.iter ignored_files ~f:(fun file ->
       print_endline (Vcs.Path_in_repo.to_string file)))
;;

let validate_cmd =
  Command.make
    ~summary:"Validate the crs-ignore files found in the repo."
    ~readme:(fun () ->
      "This command validates that the crs-ignore files in the repo are valid.")
    (let open Command.Std in
     let+ emit_github_annotations =
       Common_helpers.emit_github_annotations_arg ~default:false
     and+ only_this_file =
       Arg.pos_opt
         ~pos:0
         Param.file
         ~doc:
           "Instead of loading all $(b,.crs-ignore) files from the repo, validate this \
            specific file only."
     in
     let cwd = Unix.getcwd () |> Absolute_path.v in
     let { Enclosing_repo.repo_root; vcs; vcs_kind = _ } =
       Common_helpers.find_enclosing_repo ~from:cwd
     in
     let files_in_repo = Vcs.ls_files vcs ~repo_root ~below:Vcs.Path_in_repo.root in
     let crs_ignore_files =
       match only_this_file with
       | Some file -> [ Common_helpers.relativize ~repo_root ~cwd ~path:(Fpath.v file) ]
       | None -> find_crs_ignore_files files_in_repo
     in
     let rules =
       List.map crs_ignore_files ~f:(fun path ->
         Crs_ignore.File.load_exn
           ~repo_root
           ~path
           ~invalid_patterns_are_errors:true
           ~emit_github_annotations)
       |> Crs_ignore.Rules.create
     in
     let ignored_files =
       List.filter files_in_repo ~f:(fun path ->
         Crs_ignore.Rules.is_file_ignored rules ~path)
     in
     ignore (ignored_files : Vcs.Path_in_repo.t list);
     (* Having gone through all files in the repo, any patterns that is still
        unused at this point is dead code and should be cleaned up. *)
     List.iter (Crs_ignore.Rules.unused_patterns rules) ~f:(fun pattern ->
       User_message.warning
         ~loc:pattern.loc
         ~emit_github_annotations
         [ Pp.text "This ignore pattern is unused." ]
         ~hints:
           Pp.O.
             [ Pp.text "Remove it from this "
               ++ Pp_tty.kwd (module Fsegment) Crs_ignore.filename
               ++ Pp.text " file."
             ]))
;;

let main =
  Command.group
    ~summary:"Utils related to crs-ignore files."
    [ "list-ignored-files", list_ignored_files_cmd
    ; "list-included-files", list_included_files_cmd
    ; "validate", validate_cmd
    ]
;;
