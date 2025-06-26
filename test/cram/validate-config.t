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
  > , user_mentions_whitelist: [ "user1", "user2", "pr-author" ]
  > , invalid_crs_annotation_severity: [ "Warning" ]
  > , crs_due_now_annotation_severity: [ "Info" ]
  > }
  > EOF

  $ crs tools config validate crs-config.json
  $ crs tools config validate crs-config.json --print
  ((default_repo_owner user1) (user_mentions_whitelist (user1 user2 pr-author))
   (invalid_crs_annotation_severity Warning)
   (crs_due_now_annotation_severity Info))

Fields are usually optional.

  $ cat > crs-config.json <<EOF
  > { invalid_crs_annotation_severity: [ "Error" ] }
  > EOF

  $ crs tools config validate crs-config.json --print
  ((invalid_crs_annotation_severity Error))

Unknown field.

  $ cat > crs-config.json <<EOF
  > { unknown_field: "Hello" }
  > EOF

  $ crs tools config validate crs-config.json >out 2>&1
  [123]
  $ cat out | sed 's/[a-zA-Z0-9._\/-]*config\.ml/<PATH>\/config.ml/g'
  File "crs-config.json", line 1, characters 0-0:
  Error: Invalid config.
  In: {"unknown_field":"Hello"}
  (Failure
   "<PATH>/config.ml.t_of_yojson: extra fields: unknown_field")

Invalid value.

  $ cat > crs-config.json <<EOF
  > { invalid_crs_annotation_severity: [ "Unknown" ] }
  > EOF

  $ crs tools config validate crs-config.json >out 2>&1
  [123]
  $ cat out | sed 's/[a-zA-Z0-9._\/-]*config\.ml/<PATH>\/config.ml/g'
  File "crs-config.json", line 1, characters 0-0:
  Error: Invalid config.
  In: ["Unknown"]
  (Failure
   "<PATH>/config.ml.Annotation_severity.t_of_yojson: unexpected variant constructor")
