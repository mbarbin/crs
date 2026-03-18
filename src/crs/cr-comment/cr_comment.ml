(*********************************************************************************)
(*  crs - A tool for managing inline review comments embedded in source code     *)
(*  SPDX-FileCopyrightText: 2024-2026 Mathieu Barbin <mathieu.barbin@gmail.com>  *)
(*  SPDX-License-Identifier: LGPL-3.0-or-later WITH LGPL-3.0-linking-exception   *)
(*********************************************************************************)

module Status = Status
module Filter = Filter
module Priority = Priority
module Qualifier = Qualifier
module User_handle = User_handle
include Cr_comment0

module Std = struct
  module User_handle = User_handle
end
