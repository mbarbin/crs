In this test we execise the config parsing and error handling.

  $ volgo-vcs init -q .
  $ volgo-vcs set-user-config --user.name "Test User" --user.email "test@example.com"

Let's validate some configs.

An empty file.

  $ printf "" > crs-config.json
  $ crs tools config validate crs-config.json
  File "crs-config.json", line 1, characters 0-0:
  Error: Not a valid json file.
  Line 0: Unexpected end of input
  [123]

An empty json.

  $ printf "{}" > crs-config.json
  $ crs tools config validate crs-config.json

Note we can re-print the config too.

  $ crs tools config validate crs-config.json --print
  ()

Let's try with valid configs.

  $ cat > crs-config.json <<EOF
  > { default_repo_owner: "user1"
  > , user_mentions_allowlist: [ "user1", "user2", "pr-author" ]
  > , invalid_crs_annotation_severity: "Warning"
  > , crs_due_now_annotation_severity: "Info"
  > }
  > EOF

  $ crs tools config validate crs-config.json
  $ crs tools config validate crs-config.json --print
  ((default_repo_owner user1) (user_mentions_allowlist (user1 user2 pr-author))
   (invalid_crs_annotation_severity Warning)
   (crs_due_now_annotation_severity Info))

Fields are usually optional.

  $ cat > crs-config.json <<EOF
  > { invalid_crs_annotation_severity: "Error" }
  > EOF

  $ crs tools config validate crs-config.json --print
  ((invalid_crs_annotation_severity Error))

Wrapped variants. At this time we allow both representation for variants,
wrapped in a list and unwrapped. The goal is to deprecate the wrapper version
at some future point.

  $ cat > crs-config.json <<EOF
  > { invalid_crs_annotation_severity: [ "Warning" ]
  > , crs_due_now_annotation_severity: [ "Info" ]
  > }
  > EOF

  $ crs tools config validate crs-config.json
  File "crs-config.json", line 1, characters 0-0:
  Warning: The config field name [invalid_crs_annotation_severity] is now
  expected to be a json string rather than a list.
  Hint: Change it to simply: "Warning"
  
  File "crs-config.json", line 1, characters 0-0:
  Warning: The config field name [crs_due_now_annotation_severity] is now
  expected to be a json string rather than a list.
  Hint: Change it to simply: "Info"
  $ crs tools config validate crs-config.json --print
  File "crs-config.json", line 1, characters 0-0:
  Warning: The config field name [invalid_crs_annotation_severity] is now
  expected to be a json string rather than a list.
  Hint: Change it to simply: "Warning"
  
  File "crs-config.json", line 1, characters 0-0:
  Warning: The config field name [crs_due_now_annotation_severity] is now
  expected to be a json string rather than a list.
  Hint: Change it to simply: "Info"
  ((invalid_crs_annotation_severity Warning)
   (crs_due_now_annotation_severity Info))

Unknown fields.

  $ cat > crs-config.json <<EOF
  > { unknown_field2: "Hello"
  > , unknown_field1: "Hello"
  > }
  > EOF

  $ crs tools config validate crs-config.json
  File "crs-config.json", line 1, characters 0-0:
  Warning: Unknown config field "unknown_field2".
  Hint: Check the documentation for valid field names.
  
  File "crs-config.json", line 1, characters 0-0:
  Warning: Unknown config field "unknown_field1".
  Hint: Check the documentation for valid field names.

Invalid value.

  $ cat > crs-config.json <<EOF
  > { invalid_crs_annotation_severity: "Unknown" }
  > EOF

  $ crs tools config validate crs-config.json
  File "crs-config.json", line 1, characters 0-0:
  Error: Field [invalid_crs_annotation_severity]:
  Unsupported annotation severity "Unknown".
  [123]

Test that config must be a JSON object (not an array or other type).

  $ cat > crs-config.json <<EOF
  > [ "not", "an", "object" ]
  > EOF

  $ crs tools config validate crs-config.json
  File "crs-config.json", line 1, characters 0-0:
  Error: Config expected to be a json object.
  [123]

Test severity field with invalid type (integer instead of string).

  $ cat > crs-config.json <<EOF
  > { invalid_crs_annotation_severity: 42 }
  > EOF

  $ crs tools config validate crs-config.json
  File "crs-config.json", line 1, characters 0-0:
  Error: In: 42
  Field [invalid_crs_annotation_severity] expected to be a json string.
  [123]

Test severity field with invalid type (object instead of string).

  $ cat > crs-config.json <<EOF
  > { crs_due_now_annotation_severity: { "nested": "object" } }
  > EOF

  $ crs tools config validate crs-config.json
  File "crs-config.json", line 1, characters 0-0:
  Error: In: {"nested":"object"}
  Field [crs_due_now_annotation_severity] expected to be a json string.
  [123]

Test duplicate field detection.

  $ cat > crs-config.json <<EOF
  > { default_repo_owner: "user1"
  > , default_repo_owner: "user2"
  > }
  > EOF

  $ crs tools config validate crs-config.json
  File "crs-config.json", line 1, characters 0-0:
  Error: Json object field [default_repo_owner] is duplicated in this config.
  [123]

Test malformed JSON file.

  $ echo "{ invalid json" > crs-config.json
  $ crs tools config validate crs-config.json
  File "crs-config.json", line 1, characters 0-0:
  Error: Not a valid json file.
  Line 1: Expected ':' but found IDENTIFIER_NAME "json"
  [123]

Test invalid type for user handle (should be string, not array).

  $ cat > crs-config.json <<EOF
  > { default_repo_owner: ["not", "a", "string"] }
  > EOF

  $ crs tools config validate crs-config.json
  File "crs-config.json", line 1, characters 0-0:
  Error: Invalid config.
  In: ["not","a","string"]
  User handle expected to be a json string.
  [123]

Test invalid user handle with forbidden characters.

  $ cat > crs-config.json <<EOF
  > { default_repo_owner: "user@with@invalid@chars" }
  > EOF

  $ crs tools config validate crs-config.json
  File "crs-config.json", line 1, characters 0-0:
  Error: Invalid config.
  In: "user@with@invalid@chars"
  "user@with@invalid@chars": invalid user_handle
  [123]

Test user_mentions_allowlist with invalid type (integer instead of list).

  $ cat > crs-config.json <<EOF
  > { user_mentions_allowlist: 42 }
  > EOF

  $ crs tools config validate crs-config.json
  File "crs-config.json", line 1, characters 0-0:
  Error: Invalid config.
  In: 42
  User handle list expected to be a list of json strings.
  [123]

Test deprecated field with GitHub annotation warnings.

  $ cat > crs-config.json <<EOF
  > { user_mentions_whitelist: [ "user1", "user2" ] }
  > EOF

  $ crs tools config validate crs-config.json
  File "crs-config.json", line 1, characters 0-0:
  Warning: The config field name [user_mentions_whitelist] is deprecated and
  was renamed [user_mentions_allowlist].
  Hint: Upgrade the config to use the new name.

  $ crs tools config validate crs-config.json --with-github-annotations-warnings=true
  File "crs-config.json", line 1, characters 0-0:
  Warning: The config field name [user_mentions_whitelist] is deprecated and
  was renamed [user_mentions_allowlist].
  Hint: Upgrade the config to use the new name.
  ::warning file=crs-config.json,line=1,col=1,endLine=1,endColumn=1,title=crs::The config field name [user_mentions_whitelist] is deprecated and was renamed%0A[user_mentions_allowlist].%0AHints: Upgrade the config to use the new%0Aname.

Monitor the error message for empty fields.

  $ cat > crs-config.json <<EOF
  > { "": "hello"
  > , "default_repo_owner": "user1"
  > }
  > EOF

  $ crs tools config validate crs-config.json
  File "crs-config.json", line 1, characters 0-0:
  Warning: Unknown config field "".
  Hint: Check the documentation for valid field names.

Test that we support having a field for json schemas.

  $ cat > crs-config.json <<EOF
  > { "\$schema": "path/to/crs-config.schema.json"
  > , "default_repo_owner": "user1"
  > }
  > EOF

  $ crs tools config validate crs-config.json
