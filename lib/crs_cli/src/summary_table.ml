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

module Column = struct
  type 'a t =
    { header : string
    ; make_box : 'a -> PrintBox.t
    ; align_h : [ `Left | `Center | `Right ]
    }

  let make header ?(align = `Left) f = { header; make_box = f; align_h = align }
end

let make_table columns rows =
  let pad_cell box = PrintBox.hpad 1 box in
  PrintBox.(
    frame
      (hlist
         (List.filter_map columns ~f:(fun { Column.header; make_box; align_h } ->
            let rows = List.map rows ~f:make_box in
            if
              List.for_all rows ~f:(fun box ->
                match PrintBox.view box with
                | Empty -> true
                | _ -> false)
            then None
            else
              Some
                (vlist
                   [ align ~h:align_h ~v:`Center (pad_cell (line header))
                   ; grid_l
                       ~bars:false
                       (List.map rows ~f:(fun box ->
                          let box =
                            (* When encountering an empty cell, [grid_l] shifts
                               the remaining rows up one level, which creates a
                               misalignment. Thus we use a workaround here. *)
                            match PrintBox.view box with
                            | Empty -> line " "
                            | _ -> box
                          in
                          [ align ~h:align_h ~v:`Center (pad_cell box) ]))
                   ])))))
;;

module By_type = struct
  module Type = struct
    type t =
      | Invalid
      | CR
      | XCR
      | Soon
      | Someday
    [@@deriving compare, sexp_of]

    let to_string t =
      match sexp_of_t t with
      | Atom a -> a
      | List _ -> assert false
    ;;

    let of_cr (cr : Cr_comment.t) =
      match Cr_comment.header cr with
      | Error _ -> Invalid
      | Ok h ->
        (match Cr_comment.Header.kind h with
         | XCR -> XCR
         | CR ->
           (match Cr_comment.Header.due h with
            | Now -> CR
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
    PrintBox.
      [ Column.make "type" (fun (row : Row.t) -> line (Type.to_string row.type_))
      ; Column.make "count" ~align:`Right (fun (row : Row.t) ->
          line_with_style
            (match row.type_ with
             | Invalid -> Style.fg_color Red
             | CR | XCR | Soon | Someday -> Style.default)
            (Int.to_string_hum row.count))
      ]
  ;;

  let to_string t =
    if List.is_empty t.rows
    then ""
    else PrintBox_text.to_string (make_table columns t.rows) ^ "\n"
  ;;
end

module Type = struct
  type t =
    | CR
    | XCR
    | Soon
    | Someday

  let of_header h =
    match Cr_comment.Header.kind h with
    | XCR -> XCR
    | CR ->
      (match Cr_comment.Header.due h with
       | Now -> CR
       | Soon -> Soon
       | Someday -> Someday)
  ;;
end

module Key = struct
  type t =
    { reporter : Vcs.User_handle.t
    ; for_ : Vcs.User_handle.t option
    }
  [@@deriving compare]

  let of_header (h : Cr_comment.Header.t) =
    { reporter = Cr_comment.Header.reported_by h; for_ = Cr_comment.Header.for_ h }
  ;;
end

module Row = struct
  type t =
    { reporter : Vcs.User_handle.t
    ; for_ : Vcs.User_handle.t option
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
      | ({ Key.reporter; for_ }, _) :: _ as list ->
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
        ; for_
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
  let count label count =
    PrintBox.(
      Column.make label ~align:`Right (fun (row : Row.t) ->
        let count = count row in
        if count = 0 then empty else line (Int.to_string_hum count)))
  in
  PrintBox.
    [ Column.make "reporter" (fun (row : Row.t) ->
        line (Vcs.User_handle.to_string row.reporter))
    ; Column.make "for" (fun (row : Row.t) ->
        match row.for_ with
        | None -> empty
        | Some user -> line (Vcs.User_handle.to_string user))
    ; count "CRs" (fun row -> row.cr_count)
    ; count "XCRs" (fun row -> row.xcr_count)
    ; count "Soon" (fun row -> row.soon_count)
    ; count "Someday" (fun row -> row.someday_count)
    ; count "Total" (fun row -> row.total_count)
    ]
;;

let to_string t =
  if List.is_empty t.rows
  then ""
  else PrintBox_text.to_string (make_table columns t.rows) ^ "\n"
;;
