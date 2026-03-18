(*_********************************************************************************)
(*_  crs - A tool for managing inline review comments embedded in source code     *)
(*_  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*_  SPDX-License-Identifier: LGPL-3.0-or-later WITH LGPL-3.0-linking-exception   *)
(*_********************************************************************************)

module By_type : sig
  type t

  val make : Cr_comment.t list -> t
  val to_print_table : t -> Print_table.t option
end

type t

val make : Cr_comment.t list -> t
val to_print_table : t -> Print_table.t option
