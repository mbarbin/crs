(*********************************************************************************)
(*  crs - A tool for managing inline review comments embedded in source code     *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: LGPL-3.0-or-later WITH LGPL-3.0-linking-exception   *)
(*********************************************************************************)

let main =
  Command.make
    ~summary:"A util to get info about the enclosing repo."
    ~readme:(fun () ->
      "This debug command locates the root of the repository containing the current \
       working directory.\n\n\
       It then displays a json-expression containing several fields related to that \
       repository and the current path.\n\n\
       - $(b,repo_root) : The root of the enclosing repo (absolute path).\n\n\
       - $(b,path_in_repo) : The path of the current directory related to the repo root \
       (relative path).\n\n\
       - $(b,vcs_kind) : The kind of version control for the enclosing repository \
       (Git|Hg).\n\n\
       This command is meant for debug and quick tests only. Its output is unstable and \
       may change without semver updates. In particular it should not be relied on in \
       scripts.")
    (let open Command.Std in
     let+ () = Log_cli.set_config () in
     let cwd = Unix.getcwd () |> Absolute_path.v in
     let { Enclosing_repo.vcs_kind; repo_root; vcs = _ } =
       Common_helpers.find_enclosing_repo ~from:cwd
     in
     let path_in_repo =
       Common_helpers.relativize ~repo_root ~cwd ~path:(Relative_path.empty :> Fpath.t)
     in
     (* Even though we say that this command shall not be used by scripts, it is
        actually used internally by the emacs-mode provided by this repo. We
        control both code and release them in sync, however breaking upgrades
        shall be done with care. At the moment, the emacs code relies on the
        presence of [json-string] fields [repo_root] and [path_in_repo]. *)
     print_endline
       (Json.to_string
          (`Assoc
              [ "repo_root", `String (repo_root |> Vcs.Repo_root.to_string)
              ; "path_in_repo", `String (path_in_repo |> Vcs.Path_in_repo.to_string)
              ; "vcs_kind", `String (vcs_kind |> Enclosing_repo.Vcs_kind.to_string)
              ]));
     ())
;;
