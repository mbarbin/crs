(*_***************************************************************************)
(*_  crs-myers - Vendoring windtrap.myers with minor changes                 *)
(*_  Copyright (C) 2026 Mathieu Barbin <mathieu.barbin@gmail.com>            *)
(*_  SPDX-License-Identifier: ISC                                            *)
(*_                                                                          *)
(*_  The code was vendored from [https://github.com/invariant-hq/windtrap].  *)
(*_                                                                          *)
(*_  Copyright (c) 2026 Invariant Systems. All rights reserved.              *)
(*_  SPDX-License-Identifier: ISC                                            *)
(*_***************************************************************************)

(** Minimal polymorphic Myers diff implementation. *)

module type Equal = sig
  type t

  val equal : t -> t -> bool
end

module Line : sig
  type 'a t =
    | Delete of 'a
    | Insert of 'a
    | Keep of 'a
end

(** [compute (module E) before after] returns a shortest edit script from
    [before] to [after]. *)
val compute : (module Equal with type t = 'a) -> 'a list -> 'a list -> 'a Line.t list

(** [diff expected actual] renders a unified diff for text inputs. *)
val diff
  :  ?context:int
  -> ?expected_label:string
  -> ?actual_label:string
  -> string
  -> string
  -> string

(** [print_diff expected actual] writes {!diff} to stdout. *)
val print_diff
  :  ?context:int
  -> ?expected_label:string
  -> ?actual_label:string
  -> string
  -> string
  -> unit
