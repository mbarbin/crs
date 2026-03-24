(*********************************************************************************)
(*  crs - A tool for managing inline review comments embedded in source code     *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: LGPL-3.0-or-later WITH LGPL-3.0-linking-exception   *)
(*********************************************************************************)

let version =
  match Build_info.V1.version () with
  | None -> "n/a"
  | Some v -> Build_info.V1.Version.to_string v [@coverage off]
;;

let () = Cmdlang_cmdliner_err_runner.run Crs_cli.main ~name:"crs" ~version
