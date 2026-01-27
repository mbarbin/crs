(********************************************************************************)
(*  crs - A tool for managing code review comments embedded in source code      *)
(*  Copyright (C) 2024-2025 Mathieu Barbin <mathieu.barbin@gmail.com>           *)
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

module By_type = struct
  module Type = struct
    type t =
      | Invalid
      | CR
      | XCR
      | Soon
      | Someday

    let variant_constructor_name = function
      | Invalid -> "Invalid"
      | CR -> "CR"
      | XCR -> "XCR"
      | Soon -> "Soon"
      | Someday -> "Someday"
    ;;

    let variant_constructor_rank = function
      | Invalid -> 0
      | CR -> 1
      | XCR -> 2
      | Soon -> 3
      | Someday -> 4
    ;;

    let compare t1 t2 =
      Int.compare (variant_constructor_rank t1) (variant_constructor_rank t2)
    ;;

    let to_string = variant_constructor_name

    let of_cr (cr : Cr_comment.t) =
      match Cr_comment.header cr with
      | Error _ -> Invalid
      | Ok h ->
        (match Cr_comment.Header.status h with
         | XCR -> XCR
         | CR ->
           (match Cr_comment.Header.qualifier h with
            | None -> CR
            | Soon -> Soon
            | Someday -> Someday))
    ;;
  end

  module Row = struct
    type t =
      { type_ : Type.t
      ; count : int
      }
  end

  type t = { rows : Row.t list }

  let make (crs : Cr_comment.t list) =
    let rows =
      List.map crs ~f:Type.of_cr
      |> List.sort_and_group ~compare:Type.compare
      |> List.map ~f:(function
        | [] -> assert false
        | type_ :: _ as list -> { Row.type_; count = List.length list })
    in
    { rows }
  ;;

  let columns =
    Print_table.O.
      [ Column.make ~header:"CR Type" (fun (row : Row.t) ->
          Cell.text (Type.to_string row.type_))
      ; Column.make ~header:"Count" ~align:Right (fun (row : Row.t) ->
          Cell.text
            ~style:
              (match row.type_ with
               | Invalid -> Style.fg_red
               | CR | XCR | Soon | Someday -> Style.default)
            (Int.to_string_hum row.count))
      ]
  ;;

  let to_print_table t =
    if List.is_empty t.rows then None else Some (Print_table.make ~columns ~rows:t.rows)
  ;;
end

module Type = struct
  type t =
    | CR
    | XCR
    | Soon
    | Someday

  let of_header h =
    match Cr_comment.Header.status h with
    | XCR -> XCR
    | CR ->
      (match Cr_comment.Header.qualifier h with
       | None -> CR
       | Soon -> Soon
       | Someday -> Someday)
  ;;
end

module Key = struct
  type t =
    { reporter : User_handle.t
    ; recipient : User_handle.t option
    }

  let compare t { reporter; recipient } =
    let r = User_handle.compare t.reporter reporter in
    if r <> 0 then r else Option.compare User_handle.compare t.recipient recipient
  ;;

  let of_header (h : Cr_comment.Header.t) =
    { reporter = Cr_comment.Header.reporter h; recipient = Cr_comment.Header.recipient h }
  ;;
end

module Row = struct
  type t =
    { reporter : User_handle.t
    ; recipient : User_handle.t option
    ; cr_count : int
    ; xcr_count : int
    ; soon_count : int
    ; someday_count : int
    ; total_count : int
    }
end

type t = { rows : Row.t list }

let make (crs : Cr_comment.t list) =
  let rows =
    List.filter_map crs ~f:(fun cr ->
      match Cr_comment.header cr with
      | Error _ -> None
      | Ok h ->
        let key = Key.of_header h in
        let type_ = Type.of_header h in
        Some (key, type_))
    |> List.sort_and_group ~compare:(fun (k1, _) (k2, _) -> Key.compare k1 k2)
    |> List.map ~f:(function
      | [] -> assert false
      | ({ Key.reporter; recipient }, _) :: _ as list ->
        let cr_count = ref 0 in
        let xcr_count = ref 0 in
        let soon_count = ref 0 in
        let someday_count = ref 0 in
        let total_count = ref 0 in
        List.iter list ~f:(fun (_, type_) ->
          Int.incr total_count;
          match (type_ : Type.t) with
          | CR -> Int.incr cr_count
          | XCR -> Int.incr xcr_count
          | Soon -> Int.incr soon_count
          | Someday -> Int.incr someday_count);
        { Row.reporter
        ; recipient
        ; cr_count = !cr_count
        ; xcr_count = !xcr_count
        ; soon_count = !soon_count
        ; someday_count = !someday_count
        ; total_count = !total_count
        })
  in
  { rows }
;;

let columns =
  let count ~header count =
    Print_table.O.(
      Column.make ~header ~align:Right (fun (row : Row.t) ->
        let count = count row in
        if count = 0 then Cell.empty else Cell.text (Int.to_string_hum count)))
  in
  Print_table.O.
    [ Column.make ~header:"Reporter" (fun (row : Row.t) ->
        Cell.text (User_handle.to_string row.reporter))
    ; Column.make ~header:"For" (fun (row : Row.t) ->
        match row.recipient with
        | None -> Cell.empty
        | Some user -> Cell.text (User_handle.to_string user))
    ; count ~header:"CRs" (fun row -> row.cr_count)
    ; count ~header:"XCRs" (fun row -> row.xcr_count)
    ; count ~header:"Soon" (fun row -> row.soon_count)
    ; count ~header:"Someday" (fun row -> row.someday_count)
    ; count ~header:"Total" (fun row -> row.total_count)
    ]
;;

let to_print_table t =
  if List.is_empty t.rows then None else Some (Print_table.make ~columns ~rows:t.rows)
;;
