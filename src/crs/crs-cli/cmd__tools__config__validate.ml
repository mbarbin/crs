(*********************************************************************************)
(*  crs - A tool for managing inline review comments embedded in source code     *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: LGPL-3.0-or-later WITH LGPL-3.0-linking-exception   *)
(*********************************************************************************)

let main =
  Command.make
    ~summary:"Validate the supplied config file."
    ~readme:(fun () ->
      "You can use this command to validate that the supplied file is a valid config \
       file for $(b,crs).")
    (let open Command.Std in
     let+ path = Arg.pos ~pos:0 Param.file ~doc:"Config file to customize crs."
     and+ print = Arg.flag [ "print" ] ~doc:"Print the parsed config as JSON."
     and+ emit_github_annotations =
       Common_helpers.emit_github_annotations_arg ~default:false
     in
     let config = Config.load_exn ~path:(Fpath.v path) ~emit_github_annotations in
     if print then print_endline (Json.to_string (Config.to_json config)))
;;
