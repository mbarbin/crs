[@@@ocaml.warning "-23-27-30-39-44"]

type position =
  { mutable _presence : Pbrt.Bitfield.t (** presence for 2 fields *)
  ; mutable line : int32
  ; mutable column : int32
  }

type range =
  { mutable start : position option
  ; mutable end_ : position option
  }

type location =
  { mutable _presence : Pbrt.Bitfield.t (** presence for 1 fields *)
  ; mutable path : string
  ; mutable range : range option
  }

type severity =
  | Unknown_severity
  | Error
  | Warning
  | Info

type source =
  { mutable _presence : Pbrt.Bitfield.t (** presence for 2 fields *)
  ; mutable name : string
  ; mutable url : string
  }

type code =
  { mutable _presence : Pbrt.Bitfield.t (** presence for 2 fields *)
  ; mutable value : string
  ; mutable url : string
  }

type suggestion =
  { mutable _presence : Pbrt.Bitfield.t (** presence for 1 fields *)
  ; mutable range : range option
  ; mutable text : string
  }

type related_location =
  { mutable _presence : Pbrt.Bitfield.t (** presence for 1 fields *)
  ; mutable message : string
  ; mutable location : location option
  }

type diagnostic =
  { mutable _presence : Pbrt.Bitfield.t (** presence for 3 fields *)
  ; mutable message : string
  ; mutable location : location option
  ; mutable severity : severity
  ; mutable source : source option
  ; mutable code : code option
  ; mutable suggestions : suggestion list
  ; mutable original_output : string
  ; mutable related_locations : related_location list
  }

type diagnostic_result =
  { mutable _presence : Pbrt.Bitfield.t (** presence for 1 fields *)
  ; mutable diagnostics : diagnostic list
  ; mutable source : source option
  ; mutable severity : severity
  }

let default_position () : position =
  { _presence = Pbrt.Bitfield.empty; line = 0l; column = 0l }
;;

let default_range () : range = { start = None; end_ = None }

let default_location () : location =
  { _presence = Pbrt.Bitfield.empty; path = ""; range = None }
;;

let default_severity () = (Unknown_severity : severity)
let default_source () : source = { _presence = Pbrt.Bitfield.empty; name = ""; url = "" }
let default_code () : code = { _presence = Pbrt.Bitfield.empty; value = ""; url = "" }

let default_suggestion () : suggestion =
  { _presence = Pbrt.Bitfield.empty; range = None; text = "" }
;;

let default_related_location () : related_location =
  { _presence = Pbrt.Bitfield.empty; message = ""; location = None }
;;

let default_diagnostic () : diagnostic =
  { _presence = Pbrt.Bitfield.empty
  ; message = ""
  ; location = None
  ; severity = default_severity ()
  ; source = None
  ; code = None
  ; suggestions = []
  ; original_output = ""
  ; related_locations = []
  }
;;

let default_diagnostic_result () : diagnostic_result =
  { _presence = Pbrt.Bitfield.empty
  ; diagnostics = []
  ; source = None
  ; severity = default_severity ()
  }
;;

(** {2 Make functions} *)

let[@inline] position_has_line (self : position) : bool =
  Pbrt.Bitfield.get self._presence 0
;;

let[@inline] position_has_column (self : position) : bool =
  Pbrt.Bitfield.get self._presence 1
;;

let[@inline] position_set_line (self : position) (x : int32) : unit =
  self._presence <- Pbrt.Bitfield.set self._presence 0;
  self.line <- x
;;

let[@inline] position_set_column (self : position) (x : int32) : unit =
  self._presence <- Pbrt.Bitfield.set self._presence 1;
  self.column <- x
;;

let copy_position (self : position) : position = { self with line = self.line }

let make_position ?(line : int32 option) ?(column : int32 option) () : position =
  let _res = default_position () in
  (match line with
   | None -> ()
   | Some v -> position_set_line _res v);
  (match column with
   | None -> ()
   | Some v -> position_set_column _res v);
  _res
;;

let[@inline] range_set_start (self : range) (x : position) : unit = self.start <- Some x
let[@inline] range_set_end_ (self : range) (x : position) : unit = self.end_ <- Some x
let copy_range (self : range) : range = { self with start = self.start }

let make_range ?(start : position option) ?(end_ : position option) () : range =
  let _res = default_range () in
  (match start with
   | None -> ()
   | Some v -> range_set_start _res v);
  (match end_ with
   | None -> ()
   | Some v -> range_set_end_ _res v);
  _res
;;

let[@inline] location_has_path (self : location) : bool =
  Pbrt.Bitfield.get self._presence 0
;;

let[@inline] location_set_path (self : location) (x : string) : unit =
  self._presence <- Pbrt.Bitfield.set self._presence 0;
  self.path <- x
;;

let[@inline] location_set_range (self : location) (x : range) : unit =
  self.range <- Some x
;;

let copy_location (self : location) : location = { self with path = self.path }

let make_location ?(path : string option) ?(range : range option) () : location =
  let _res = default_location () in
  (match path with
   | None -> ()
   | Some v -> location_set_path _res v);
  (match range with
   | None -> ()
   | Some v -> location_set_range _res v);
  _res
;;

let[@inline] source_has_name (self : source) : bool = Pbrt.Bitfield.get self._presence 0
let[@inline] source_has_url (self : source) : bool = Pbrt.Bitfield.get self._presence 1

let[@inline] source_set_name (self : source) (x : string) : unit =
  self._presence <- Pbrt.Bitfield.set self._presence 0;
  self.name <- x
;;

let[@inline] source_set_url (self : source) (x : string) : unit =
  self._presence <- Pbrt.Bitfield.set self._presence 1;
  self.url <- x
;;

let copy_source (self : source) : source = { self with name = self.name }

let make_source ?(name : string option) ?(url : string option) () : source =
  let _res = default_source () in
  (match name with
   | None -> ()
   | Some v -> source_set_name _res v);
  (match url with
   | None -> ()
   | Some v -> source_set_url _res v);
  _res
;;

let[@inline] code_has_value (self : code) : bool = Pbrt.Bitfield.get self._presence 0
let[@inline] code_has_url (self : code) : bool = Pbrt.Bitfield.get self._presence 1

let[@inline] code_set_value (self : code) (x : string) : unit =
  self._presence <- Pbrt.Bitfield.set self._presence 0;
  self.value <- x
;;

let[@inline] code_set_url (self : code) (x : string) : unit =
  self._presence <- Pbrt.Bitfield.set self._presence 1;
  self.url <- x
;;

let copy_code (self : code) : code = { self with value = self.value }

let make_code ?(value : string option) ?(url : string option) () : code =
  let _res = default_code () in
  (match value with
   | None -> ()
   | Some v -> code_set_value _res v);
  (match url with
   | None -> ()
   | Some v -> code_set_url _res v);
  _res
;;

let[@inline] suggestion_has_text (self : suggestion) : bool =
  Pbrt.Bitfield.get self._presence 0
;;

let[@inline] suggestion_set_range (self : suggestion) (x : range) : unit =
  self.range <- Some x
;;

let[@inline] suggestion_set_text (self : suggestion) (x : string) : unit =
  self._presence <- Pbrt.Bitfield.set self._presence 0;
  self.text <- x
;;

let copy_suggestion (self : suggestion) : suggestion = { self with range = self.range }

let make_suggestion ?(range : range option) ?(text : string option) () : suggestion =
  let _res = default_suggestion () in
  (match range with
   | None -> ()
   | Some v -> suggestion_set_range _res v);
  (match text with
   | None -> ()
   | Some v -> suggestion_set_text _res v);
  _res
;;

let[@inline] related_location_has_message (self : related_location) : bool =
  Pbrt.Bitfield.get self._presence 0
;;

let[@inline] related_location_set_message (self : related_location) (x : string) : unit =
  self._presence <- Pbrt.Bitfield.set self._presence 0;
  self.message <- x
;;

let[@inline] related_location_set_location (self : related_location) (x : location) : unit
  =
  self.location <- Some x
;;

let copy_related_location (self : related_location) : related_location =
  { self with message = self.message }
;;

let make_related_location ?(message : string option) ?(location : location option) ()
  : related_location
  =
  let _res = default_related_location () in
  (match message with
   | None -> ()
   | Some v -> related_location_set_message _res v);
  (match location with
   | None -> ()
   | Some v -> related_location_set_location _res v);
  _res
;;

let[@inline] diagnostic_has_message (self : diagnostic) : bool =
  Pbrt.Bitfield.get self._presence 0
;;

let[@inline] diagnostic_has_severity (self : diagnostic) : bool =
  Pbrt.Bitfield.get self._presence 1
;;

let[@inline] diagnostic_has_original_output (self : diagnostic) : bool =
  Pbrt.Bitfield.get self._presence 2
;;

let[@inline] diagnostic_set_message (self : diagnostic) (x : string) : unit =
  self._presence <- Pbrt.Bitfield.set self._presence 0;
  self.message <- x
;;

let[@inline] diagnostic_set_location (self : diagnostic) (x : location) : unit =
  self.location <- Some x
;;

let[@inline] diagnostic_set_severity (self : diagnostic) (x : severity) : unit =
  self._presence <- Pbrt.Bitfield.set self._presence 1;
  self.severity <- x
;;

let[@inline] diagnostic_set_source (self : diagnostic) (x : source) : unit =
  self.source <- Some x
;;

let[@inline] diagnostic_set_code (self : diagnostic) (x : code) : unit =
  self.code <- Some x
;;

let[@inline] diagnostic_set_suggestions (self : diagnostic) (x : suggestion list) : unit =
  self.suggestions <- x
;;

let[@inline] diagnostic_set_original_output (self : diagnostic) (x : string) : unit =
  self._presence <- Pbrt.Bitfield.set self._presence 2;
  self.original_output <- x
;;

let[@inline] diagnostic_set_related_locations
               (self : diagnostic)
               (x : related_location list)
  : unit
  =
  self.related_locations <- x
;;

let copy_diagnostic (self : diagnostic) : diagnostic =
  { self with message = self.message }
;;

let make_diagnostic
      ?(message : string option)
      ?(location : location option)
      ?(severity : severity option)
      ?(source : source option)
      ?(code : code option)
      ?(suggestions = [])
      ?(original_output : string option)
      ?(related_locations = [])
      ()
  : diagnostic
  =
  let _res = default_diagnostic () in
  (match message with
   | None -> ()
   | Some v -> diagnostic_set_message _res v);
  (match location with
   | None -> ()
   | Some v -> diagnostic_set_location _res v);
  (match severity with
   | None -> ()
   | Some v -> diagnostic_set_severity _res v);
  (match source with
   | None -> ()
   | Some v -> diagnostic_set_source _res v);
  (match code with
   | None -> ()
   | Some v -> diagnostic_set_code _res v);
  diagnostic_set_suggestions _res suggestions;
  (match original_output with
   | None -> ()
   | Some v -> diagnostic_set_original_output _res v);
  diagnostic_set_related_locations _res related_locations;
  _res
;;

let[@inline] diagnostic_result_has_severity (self : diagnostic_result) : bool =
  Pbrt.Bitfield.get self._presence 0
;;

let[@inline] diagnostic_result_set_diagnostics
               (self : diagnostic_result)
               (x : diagnostic list)
  : unit
  =
  self.diagnostics <- x
;;

let[@inline] diagnostic_result_set_source (self : diagnostic_result) (x : source) : unit =
  self.source <- Some x
;;

let[@inline] diagnostic_result_set_severity (self : diagnostic_result) (x : severity)
  : unit
  =
  self._presence <- Pbrt.Bitfield.set self._presence 0;
  self.severity <- x
;;

let copy_diagnostic_result (self : diagnostic_result) : diagnostic_result =
  { self with diagnostics = self.diagnostics }
;;

let make_diagnostic_result
      ?(diagnostics = [])
      ?(source : source option)
      ?(severity : severity option)
      ()
  : diagnostic_result
  =
  let _res = default_diagnostic_result () in
  diagnostic_result_set_diagnostics _res diagnostics;
  (match source with
   | None -> ()
   | Some v -> diagnostic_result_set_source _res v);
  (match severity with
   | None -> ()
   | Some v -> diagnostic_result_set_severity _res v);
  _res
;;

[@@@ocaml.warning "-23-27-30-39"]

(** {2 Protobuf YoJson Encoding} *)

let rec encode_json_position (v : position) =
  let assoc = ref [] in
  if position_has_line v
  then assoc := ("line", Pbrt_yojson.make_int (Int32.to_int v.line)) :: !assoc;
  if position_has_column v
  then assoc := ("column", Pbrt_yojson.make_int (Int32.to_int v.column)) :: !assoc;
  `Assoc !assoc
;;

let rec encode_json_range (v : range) =
  let assoc = ref [] in
  (assoc
   := match v.start with
      | None -> !assoc
      | Some v -> ("start", encode_json_position v) :: !assoc);
  (assoc
   := match v.end_ with
      | None -> !assoc
      | Some v -> ("end", encode_json_position v) :: !assoc);
  `Assoc !assoc
;;

let rec encode_json_location (v : location) =
  let assoc = ref [] in
  if location_has_path v then assoc := ("path", Pbrt_yojson.make_string v.path) :: !assoc;
  (assoc
   := match v.range with
      | None -> !assoc
      | Some v -> ("range", encode_json_range v) :: !assoc);
  `Assoc !assoc
;;

let rec encode_json_severity (v : severity) =
  match v with
  | Unknown_severity -> `String "UNKNOWN_SEVERITY"
  | Error -> `String "ERROR"
  | Warning -> `String "WARNING"
  | Info -> `String "INFO"
;;

let rec encode_json_source (v : source) =
  let assoc = ref [] in
  if source_has_name v then assoc := ("name", Pbrt_yojson.make_string v.name) :: !assoc;
  if source_has_url v then assoc := ("url", Pbrt_yojson.make_string v.url) :: !assoc;
  `Assoc !assoc
;;

let rec encode_json_code (v : code) =
  let assoc = ref [] in
  if code_has_value v then assoc := ("value", Pbrt_yojson.make_string v.value) :: !assoc;
  if code_has_url v then assoc := ("url", Pbrt_yojson.make_string v.url) :: !assoc;
  `Assoc !assoc
;;

let rec encode_json_suggestion (v : suggestion) =
  let assoc = ref [] in
  (assoc
   := match v.range with
      | None -> !assoc
      | Some v -> ("range", encode_json_range v) :: !assoc);
  if suggestion_has_text v
  then assoc := ("text", Pbrt_yojson.make_string v.text) :: !assoc;
  `Assoc !assoc
;;

let rec encode_json_related_location (v : related_location) =
  let assoc = ref [] in
  if related_location_has_message v
  then assoc := ("message", Pbrt_yojson.make_string v.message) :: !assoc;
  (assoc
   := match v.location with
      | None -> !assoc
      | Some v -> ("location", encode_json_location v) :: !assoc);
  `Assoc !assoc
;;

let rec encode_json_diagnostic (v : diagnostic) =
  let assoc = ref [] in
  if diagnostic_has_message v
  then assoc := ("message", Pbrt_yojson.make_string v.message) :: !assoc;
  (assoc
   := match v.location with
      | None -> !assoc
      | Some v -> ("location", encode_json_location v) :: !assoc);
  if diagnostic_has_severity v
  then assoc := ("severity", encode_json_severity v.severity) :: !assoc;
  (assoc
   := match v.source with
      | None -> !assoc
      | Some v -> ("source", encode_json_source v) :: !assoc);
  (assoc
   := match v.code with
      | None -> !assoc
      | Some v -> ("code", encode_json_code v) :: !assoc);
  (assoc
   := let l = v.suggestions |> List.map encode_json_suggestion in
      ("suggestions", `List l) :: !assoc);
  if diagnostic_has_original_output v
  then assoc := ("originalOutput", Pbrt_yojson.make_string v.original_output) :: !assoc;
  (assoc
   := let l = v.related_locations |> List.map encode_json_related_location in
      ("relatedLocations", `List l) :: !assoc);
  `Assoc !assoc
;;

let rec encode_json_diagnostic_result (v : diagnostic_result) =
  let assoc = ref [] in
  (assoc
   := let l = v.diagnostics |> List.map encode_json_diagnostic in
      ("diagnostics", `List l) :: !assoc);
  (assoc
   := match v.source with
      | None -> !assoc
      | Some v -> ("source", encode_json_source v) :: !assoc);
  if diagnostic_result_has_severity v
  then assoc := ("severity", encode_json_severity v.severity) :: !assoc;
  `Assoc !assoc
;;

[@@@ocaml.warning "-23-27-30-39"]

(** {2 JSON Decoding} *)

let rec decode_json_position d =
  let v = default_position () in
  let assoc =
    match d with
    | `Assoc assoc -> assoc
    | _ -> assert false
  in
  List.iter
    (function
      | "line", json_value ->
        position_set_line v (Pbrt_yojson.int32 json_value "position" "line")
      | "column", json_value ->
        position_set_column v (Pbrt_yojson.int32 json_value "position" "column")
      | _, _ -> () (*Unknown fields are ignored*))
    assoc;
  ({ _presence = v._presence; line = v.line; column = v.column } : position)
;;

let rec decode_json_range d =
  let v = default_range () in
  let assoc =
    match d with
    | `Assoc assoc -> assoc
    | _ -> assert false
  in
  List.iter
    (function
      | "start", json_value -> range_set_start v (decode_json_position json_value)
      | "end", json_value -> range_set_end_ v (decode_json_position json_value)
      | _, _ -> () (*Unknown fields are ignored*))
    assoc;
  ({ start = v.start; end_ = v.end_ } : range)
;;

let rec decode_json_location d =
  let v = default_location () in
  let assoc =
    match d with
    | `Assoc assoc -> assoc
    | _ -> assert false
  in
  List.iter
    (function
      | "path", json_value ->
        location_set_path v (Pbrt_yojson.string json_value "location" "path")
      | "range", json_value -> location_set_range v (decode_json_range json_value)
      | _, _ -> () (*Unknown fields are ignored*))
    assoc;
  ({ _presence = v._presence; path = v.path; range = v.range } : location)
;;

let rec decode_json_severity json =
  match json with
  | `String "UNKNOWN_SEVERITY" -> (Unknown_severity : severity)
  | `String "ERROR" -> (Error : severity)
  | `String "WARNING" -> (Warning : severity)
  | `String "INFO" -> (Info : severity)
  | _ -> Pbrt_yojson.E.malformed_variant "severity"
;;

let rec decode_json_source d =
  let v = default_source () in
  let assoc =
    match d with
    | `Assoc assoc -> assoc
    | _ -> assert false
  in
  List.iter
    (function
      | "name", json_value ->
        source_set_name v (Pbrt_yojson.string json_value "source" "name")
      | "url", json_value ->
        source_set_url v (Pbrt_yojson.string json_value "source" "url")
      | _, _ -> () (*Unknown fields are ignored*))
    assoc;
  ({ _presence = v._presence; name = v.name; url = v.url } : source)
;;

let rec decode_json_code d =
  let v = default_code () in
  let assoc =
    match d with
    | `Assoc assoc -> assoc
    | _ -> assert false
  in
  List.iter
    (function
      | "value", json_value ->
        code_set_value v (Pbrt_yojson.string json_value "code" "value")
      | "url", json_value -> code_set_url v (Pbrt_yojson.string json_value "code" "url")
      | _, _ -> () (*Unknown fields are ignored*))
    assoc;
  ({ _presence = v._presence; value = v.value; url = v.url } : code)
;;

let rec decode_json_suggestion d =
  let v = default_suggestion () in
  let assoc =
    match d with
    | `Assoc assoc -> assoc
    | _ -> assert false
  in
  List.iter
    (function
      | "range", json_value -> suggestion_set_range v (decode_json_range json_value)
      | "text", json_value ->
        suggestion_set_text v (Pbrt_yojson.string json_value "suggestion" "text")
      | _, _ -> () (*Unknown fields are ignored*))
    assoc;
  ({ _presence = v._presence; range = v.range; text = v.text } : suggestion)
;;

let rec decode_json_related_location d =
  let v = default_related_location () in
  let assoc =
    match d with
    | `Assoc assoc -> assoc
    | _ -> assert false
  in
  List.iter
    (function
      | "message", json_value ->
        related_location_set_message
          v
          (Pbrt_yojson.string json_value "related_location" "message")
      | "location", json_value ->
        related_location_set_location v (decode_json_location json_value)
      | _, _ -> () (*Unknown fields are ignored*))
    assoc;
  ({ _presence = v._presence; message = v.message; location = v.location }
   : related_location)
;;

let rec decode_json_diagnostic d =
  let v = default_diagnostic () in
  let assoc =
    match d with
    | `Assoc assoc -> assoc
    | _ -> assert false
  in
  List.iter
    (function
      | "message", json_value ->
        diagnostic_set_message v (Pbrt_yojson.string json_value "diagnostic" "message")
      | "location", json_value ->
        diagnostic_set_location v (decode_json_location json_value)
      | "severity", json_value ->
        diagnostic_set_severity v (decode_json_severity json_value)
      | "source", json_value -> diagnostic_set_source v (decode_json_source json_value)
      | "code", json_value -> diagnostic_set_code v (decode_json_code json_value)
      | "suggestions", `List l ->
        diagnostic_set_suggestions v
        @@ List.map
             (function
               | json_value -> decode_json_suggestion json_value)
             l
      | "originalOutput", json_value ->
        diagnostic_set_original_output
          v
          (Pbrt_yojson.string json_value "diagnostic" "original_output")
      | "relatedLocations", `List l ->
        diagnostic_set_related_locations v
        @@ List.map
             (function
               | json_value -> decode_json_related_location json_value)
             l
      | _, _ -> () (*Unknown fields are ignored*))
    assoc;
  ({ _presence = v._presence
   ; message = v.message
   ; location = v.location
   ; severity = v.severity
   ; source = v.source
   ; code = v.code
   ; suggestions = v.suggestions
   ; original_output = v.original_output
   ; related_locations = v.related_locations
   }
   : diagnostic)
;;

let rec decode_json_diagnostic_result d =
  let v = default_diagnostic_result () in
  let assoc =
    match d with
    | `Assoc assoc -> assoc
    | _ -> assert false
  in
  List.iter
    (function
      | "diagnostics", `List l ->
        diagnostic_result_set_diagnostics v
        @@ List.map
             (function
               | json_value -> decode_json_diagnostic json_value)
             l
      | "source", json_value ->
        diagnostic_result_set_source v (decode_json_source json_value)
      | "severity", json_value ->
        diagnostic_result_set_severity v (decode_json_severity json_value)
      | _, _ -> () (*Unknown fields are ignored*))
    assoc;
  ({ _presence = v._presence
   ; diagnostics = v.diagnostics
   ; source = v.source
   ; severity = v.severity
   }
   : diagnostic_result)
;;
