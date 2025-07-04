[@@@ocaml.warning "-27-30-39-44"]

type position =
  { line : int32
  ; column : int32
  }

type range =
  { start : position option
  ; end_ : position option
  }

type location =
  { path : string
  ; range : range option
  }

type severity =
  | Unknown_severity
  | Error
  | Warning
  | Info

type source =
  { name : string
  ; url : string
  }

type code =
  { value : string
  ; url : string
  }

type suggestion =
  { range : range option
  ; text : string
  }

type related_location =
  { message : string
  ; location : location option
  }

type diagnostic =
  { message : string
  ; location : location option
  ; severity : severity
  ; source : source option
  ; code : code option
  ; suggestions : suggestion list
  ; original_output : string
  ; related_locations : related_location list
  }

type diagnostic_result =
  { diagnostics : diagnostic list
  ; source : source option
  ; severity : severity
  }

let rec default_position ?(line : int32 = 0l) ?(column : int32 = 0l) () : position =
  { line; column }
;;

let rec default_range
          ?(start : position option = None)
          ?(end_ : position option = None)
          ()
  : range
  =
  { start; end_ }
;;

let rec default_location ?(path : string = "") ?(range : range option = None) ()
  : location
  =
  { path; range }
;;

let rec default_severity () = (Unknown_severity : severity)

let rec default_source ?(name : string = "") ?(url : string = "") () : source =
  { name; url }
;;

let rec default_code ?(value : string = "") ?(url : string = "") () : code =
  { value; url }
;;

let rec default_suggestion ?(range : range option = None) ?(text : string = "") ()
  : suggestion
  =
  { range; text }
;;

let rec default_related_location
          ?(message : string = "")
          ?(location : location option = None)
          ()
  : related_location
  =
  { message; location }
;;

let rec default_diagnostic
          ?(message : string = "")
          ?(location : location option = None)
          ?(severity : severity = default_severity ())
          ?(source : source option = None)
          ?(code : code option = None)
          ?(suggestions : suggestion list = [])
          ?(original_output : string = "")
          ?(related_locations : related_location list = [])
          ()
  : diagnostic
  =
  { message
  ; location
  ; severity
  ; source
  ; code
  ; suggestions
  ; original_output
  ; related_locations
  }
;;

let rec default_diagnostic_result
          ?(diagnostics : diagnostic list = [])
          ?(source : source option = None)
          ?(severity : severity = default_severity ())
          ()
  : diagnostic_result
  =
  { diagnostics; source; severity }
;;

type position_mutable =
  { mutable line : int32
  ; mutable column : int32
  }

let default_position_mutable () : position_mutable = { line = 0l; column = 0l }

type range_mutable =
  { mutable start : position option
  ; mutable end_ : position option
  }

let default_range_mutable () : range_mutable = { start = None; end_ = None }

type location_mutable =
  { mutable path : string
  ; mutable range : range option
  }

let default_location_mutable () : location_mutable = { path = ""; range = None }

type source_mutable =
  { mutable name : string
  ; mutable url : string
  }

let default_source_mutable () : source_mutable = { name = ""; url = "" }

type code_mutable =
  { mutable value : string
  ; mutable url : string
  }

let default_code_mutable () : code_mutable = { value = ""; url = "" }

type suggestion_mutable =
  { mutable range : range option
  ; mutable text : string
  }

let default_suggestion_mutable () : suggestion_mutable = { range = None; text = "" }

type related_location_mutable =
  { mutable message : string
  ; mutable location : location option
  }

let default_related_location_mutable () : related_location_mutable =
  { message = ""; location = None }
;;

type diagnostic_mutable =
  { mutable message : string
  ; mutable location : location option
  ; mutable severity : severity
  ; mutable source : source option
  ; mutable code : code option
  ; mutable suggestions : suggestion list
  ; mutable original_output : string
  ; mutable related_locations : related_location list
  }

let default_diagnostic_mutable () : diagnostic_mutable =
  { message = ""
  ; location = None
  ; severity = default_severity ()
  ; source = None
  ; code = None
  ; suggestions = []
  ; original_output = ""
  ; related_locations = []
  }
;;

type diagnostic_result_mutable =
  { mutable diagnostics : diagnostic list
  ; mutable source : source option
  ; mutable severity : severity
  }

let default_diagnostic_result_mutable () : diagnostic_result_mutable =
  { diagnostics = []; source = None; severity = default_severity () }
;;

(** {2 Make functions} *)

let rec make_position ~(line : int32) ~(column : int32) () : position = { line; column }

let rec make_range ?(start : position option = None) ?(end_ : position option = None) ()
  : range
  =
  { start; end_ }
;;

let rec make_location ~(path : string) ?(range : range option = None) () : location =
  { path; range }
;;

let rec make_source ~(name : string) ~(url : string) () : source = { name; url }
let rec make_code ~(value : string) ~(url : string) () : code = { value; url }

let rec make_suggestion ?(range : range option = None) ~(text : string) () : suggestion =
  { range; text }
;;

let rec make_related_location ~(message : string) ?(location : location option = None) ()
  : related_location
  =
  { message; location }
;;

let rec make_diagnostic
          ~(message : string)
          ?(location : location option = None)
          ~(severity : severity)
          ?(source : source option = None)
          ?(code : code option = None)
          ~(suggestions : suggestion list)
          ~(original_output : string)
          ~(related_locations : related_location list)
          ()
  : diagnostic
  =
  { message
  ; location
  ; severity
  ; source
  ; code
  ; suggestions
  ; original_output
  ; related_locations
  }
;;

let rec make_diagnostic_result
          ~(diagnostics : diagnostic list)
          ?(source : source option = None)
          ~(severity : severity)
          ()
  : diagnostic_result
  =
  { diagnostics; source; severity }
;;

[@@@ocaml.warning "-27-30-39"]

(** {2 Protobuf YoJson Encoding} *)

let rec encode_json_position (v : position) =
  let assoc = [] in
  let assoc = ("line", Pbrt_yojson.make_int (Int32.to_int v.line)) :: assoc in
  let assoc = ("column", Pbrt_yojson.make_int (Int32.to_int v.column)) :: assoc in
  `Assoc assoc
;;

let rec encode_json_range (v : range) =
  let assoc = [] in
  let assoc =
    match v.start with
    | None -> assoc
    | Some v -> ("start", encode_json_position v) :: assoc
  in
  let assoc =
    match v.end_ with
    | None -> assoc
    | Some v -> ("end", encode_json_position v) :: assoc
  in
  `Assoc assoc
;;

let rec encode_json_location (v : location) =
  let assoc = [] in
  let assoc = ("path", Pbrt_yojson.make_string v.path) :: assoc in
  let assoc =
    match v.range with
    | None -> assoc
    | Some v -> ("range", encode_json_range v) :: assoc
  in
  `Assoc assoc
;;

let rec encode_json_severity (v : severity) =
  match v with
  | Unknown_severity -> `String "UNKNOWN_SEVERITY"
  | Error -> `String "ERROR"
  | Warning -> `String "WARNING"
  | Info -> `String "INFO"
;;

let rec encode_json_source (v : source) =
  let assoc = [] in
  let assoc = ("name", Pbrt_yojson.make_string v.name) :: assoc in
  let assoc = ("url", Pbrt_yojson.make_string v.url) :: assoc in
  `Assoc assoc
;;

let rec encode_json_code (v : code) =
  let assoc = [] in
  let assoc = ("value", Pbrt_yojson.make_string v.value) :: assoc in
  let assoc = ("url", Pbrt_yojson.make_string v.url) :: assoc in
  `Assoc assoc
;;

let rec encode_json_suggestion (v : suggestion) =
  let assoc = [] in
  let assoc =
    match v.range with
    | None -> assoc
    | Some v -> ("range", encode_json_range v) :: assoc
  in
  let assoc = ("text", Pbrt_yojson.make_string v.text) :: assoc in
  `Assoc assoc
;;

let rec encode_json_related_location (v : related_location) =
  let assoc = [] in
  let assoc = ("message", Pbrt_yojson.make_string v.message) :: assoc in
  let assoc =
    match v.location with
    | None -> assoc
    | Some v -> ("location", encode_json_location v) :: assoc
  in
  `Assoc assoc
;;

let rec encode_json_diagnostic (v : diagnostic) =
  let assoc = [] in
  let assoc = ("message", Pbrt_yojson.make_string v.message) :: assoc in
  let assoc =
    match v.location with
    | None -> assoc
    | Some v -> ("location", encode_json_location v) :: assoc
  in
  let assoc = ("severity", encode_json_severity v.severity) :: assoc in
  let assoc =
    match v.source with
    | None -> assoc
    | Some v -> ("source", encode_json_source v) :: assoc
  in
  let assoc =
    match v.code with
    | None -> assoc
    | Some v -> ("code", encode_json_code v) :: assoc
  in
  let assoc =
    let l = v.suggestions |> List.map encode_json_suggestion in
    ("suggestions", `List l) :: assoc
  in
  let assoc = ("originalOutput", Pbrt_yojson.make_string v.original_output) :: assoc in
  let assoc =
    let l = v.related_locations |> List.map encode_json_related_location in
    ("relatedLocations", `List l) :: assoc
  in
  `Assoc assoc
;;

let rec encode_json_diagnostic_result (v : diagnostic_result) =
  let assoc = [] in
  let assoc =
    let l = v.diagnostics |> List.map encode_json_diagnostic in
    ("diagnostics", `List l) :: assoc
  in
  let assoc =
    match v.source with
    | None -> assoc
    | Some v -> ("source", encode_json_source v) :: assoc
  in
  let assoc = ("severity", encode_json_severity v.severity) :: assoc in
  `Assoc assoc
;;

[@@@ocaml.warning "-27-30-39"]

(** {2 JSON Decoding} *)

let rec decode_json_position d =
  let v = default_position_mutable () in
  let assoc =
    match d with
    | `Assoc assoc -> assoc
    | _ -> assert false
  in
  List.iter
    (function
      | "line", json_value -> v.line <- Pbrt_yojson.int32 json_value "position" "line"
      | "column", json_value ->
        v.column <- Pbrt_yojson.int32 json_value "position" "column"
      | _, _ -> () (*Unknown fields are ignored*))
    assoc;
  ({ line = v.line; column = v.column } : position)
;;

let rec decode_json_range d =
  let v = default_range_mutable () in
  let assoc =
    match d with
    | `Assoc assoc -> assoc
    | _ -> assert false
  in
  List.iter
    (function
      | "start", json_value -> v.start <- Some (decode_json_position json_value)
      | "end", json_value -> v.end_ <- Some (decode_json_position json_value)
      | _, _ -> () (*Unknown fields are ignored*))
    assoc;
  ({ start = v.start; end_ = v.end_ } : range)
;;

let rec decode_json_location d =
  let v = default_location_mutable () in
  let assoc =
    match d with
    | `Assoc assoc -> assoc
    | _ -> assert false
  in
  List.iter
    (function
      | "path", json_value -> v.path <- Pbrt_yojson.string json_value "location" "path"
      | "range", json_value -> v.range <- Some (decode_json_range json_value)
      | _, _ -> () (*Unknown fields are ignored*))
    assoc;
  ({ path = v.path; range = v.range } : location)
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
  let v = default_source_mutable () in
  let assoc =
    match d with
    | `Assoc assoc -> assoc
    | _ -> assert false
  in
  List.iter
    (function
      | "name", json_value -> v.name <- Pbrt_yojson.string json_value "source" "name"
      | "url", json_value -> v.url <- Pbrt_yojson.string json_value "source" "url"
      | _, _ -> () (*Unknown fields are ignored*))
    assoc;
  ({ name = v.name; url = v.url } : source)
;;

let rec decode_json_code d =
  let v = default_code_mutable () in
  let assoc =
    match d with
    | `Assoc assoc -> assoc
    | _ -> assert false
  in
  List.iter
    (function
      | "value", json_value -> v.value <- Pbrt_yojson.string json_value "code" "value"
      | "url", json_value -> v.url <- Pbrt_yojson.string json_value "code" "url"
      | _, _ -> () (*Unknown fields are ignored*))
    assoc;
  ({ value = v.value; url = v.url } : code)
;;

let rec decode_json_suggestion d =
  let v = default_suggestion_mutable () in
  let assoc =
    match d with
    | `Assoc assoc -> assoc
    | _ -> assert false
  in
  List.iter
    (function
      | "range", json_value -> v.range <- Some (decode_json_range json_value)
      | "text", json_value -> v.text <- Pbrt_yojson.string json_value "suggestion" "text"
      | _, _ -> () (*Unknown fields are ignored*))
    assoc;
  ({ range = v.range; text = v.text } : suggestion)
;;

let rec decode_json_related_location d =
  let v = default_related_location_mutable () in
  let assoc =
    match d with
    | `Assoc assoc -> assoc
    | _ -> assert false
  in
  List.iter
    (function
      | "message", json_value ->
        v.message <- Pbrt_yojson.string json_value "related_location" "message"
      | "location", json_value -> v.location <- Some (decode_json_location json_value)
      | _, _ -> () (*Unknown fields are ignored*))
    assoc;
  ({ message = v.message; location = v.location } : related_location)
;;

let rec decode_json_diagnostic d =
  let v = default_diagnostic_mutable () in
  let assoc =
    match d with
    | `Assoc assoc -> assoc
    | _ -> assert false
  in
  List.iter
    (function
      | "message", json_value ->
        v.message <- Pbrt_yojson.string json_value "diagnostic" "message"
      | "location", json_value -> v.location <- Some (decode_json_location json_value)
      | "severity", json_value -> v.severity <- decode_json_severity json_value
      | "source", json_value -> v.source <- Some (decode_json_source json_value)
      | "code", json_value -> v.code <- Some (decode_json_code json_value)
      | "suggestions", `List l ->
        v.suggestions
        <- List.map
             (function
               | json_value -> decode_json_suggestion json_value)
             l
      | "originalOutput", json_value ->
        v.original_output <- Pbrt_yojson.string json_value "diagnostic" "original_output"
      | "relatedLocations", `List l ->
        v.related_locations
        <- List.map
             (function
               | json_value -> decode_json_related_location json_value)
             l
      | _, _ -> () (*Unknown fields are ignored*))
    assoc;
  ({ message = v.message
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
  let v = default_diagnostic_result_mutable () in
  let assoc =
    match d with
    | `Assoc assoc -> assoc
    | _ -> assert false
  in
  List.iter
    (function
      | "diagnostics", `List l ->
        v.diagnostics
        <- List.map
             (function
               | json_value -> decode_json_diagnostic json_value)
             l
      | "source", json_value -> v.source <- Some (decode_json_source json_value)
      | "severity", json_value -> v.severity <- decode_json_severity json_value
      | _, _ -> () (*Unknown fields are ignored*))
    assoc;
  ({ diagnostics = v.diagnostics; source = v.source; severity = v.severity }
   : diagnostic_result)
;;
