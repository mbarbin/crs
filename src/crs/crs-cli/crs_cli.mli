(*_********************************************************************************)
(*_  crs - A tool for managing inline review comments embedded in source code     *)
(*_  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*_  SPDX-License-Identifier: LGPL-3.0-or-later WITH LGPL-3.0-linking-exception   *)
(*_********************************************************************************)

val main : unit Command.t

(** {1 Private}

    This module is exported to be used by tests and libraries with strong ties
    to [crs]. Its signature may change in breaking ways at any time without
    prior notice, and outside of the guidelines set by semver. *)

module Private : sig
  val grep_cmd : unit Command.t

  module Std : sig
    module Annotation = Annotation
    module Assignee = Assignee
    module Config = Config
    module Review_mode = Review_mode
    module Reviewdog_utils = Reviewdog_utils
    module Summary_table = Summary_table
  end
end
