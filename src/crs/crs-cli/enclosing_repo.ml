(*********************************************************************************)
(*  crs - A tool for managing inline review comments embedded in source code     *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: LGPL-3.0-or-later WITH LGPL-3.0-linking-exception   *)
(*********************************************************************************)

module Vcs_kind = struct
  type t =
    [ `Git
    | `Hg
    ]

  let to_string = function
    | `Git -> "Git"
    | `Hg -> "Hg"
  ;;
end

type vcs = < Vcs.Trait.file_system ; Vcs.Trait.ls_files > Vcs.t

type t =
  { vcs_kind : Vcs_kind.t
  ; repo_root : Vcs.Repo_root.t
  ; vcs : vcs
  }
