(*_********************************************************************************)
(*_  crs - A tool for managing inline review comments embedded in source code     *)
(*_  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*_  SPDX-License-Identifier: LGPL-3.0-or-later WITH LGPL-3.0-linking-exception   *)
(*_********************************************************************************)

module Status = Status
module Filter = Filter
module Priority = Priority
module Qualifier = Qualifier
module User_handle = User_handle
include module type of Cr_comment0

module Std : sig
  module User_handle = User_handle
end
