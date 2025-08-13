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
  File "crs-config.json", line 1, characters 0-0:
  Warning: The config field name [user_mentions_whitelist] is deprecated and
  was renamed [user_mentions_allowlist].
  Hint: Upgrade the config to use the new name.
  
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
  Warning: The config field name [user_mentions_whitelist] is deprecated and
  was renamed [user_mentions_allowlist].
  Hint: Upgrade the config to use the new name.
  
  File "crs-config.json", line 1, characters 0-0:
  Warning: The config field name [invalid_crs_annotation_severity] is now
  expected to be a json string rather than a list.
  Hint: Change it to simply: "Warning"
  
  File "crs-config.json", line 1, characters 0-0:
  Warning: The config field name [crs_due_now_annotation_severity] is now
  expected to be a json string rather than a list.
  Hint: Change it to simply: "Info"
  ((default_repo_owner user1) (user_mentions_allowlist (user1 user2 pr-author))
   (invalid_crs_annotation_severity Warning)
   (crs_due_now_annotation_severity Info))

Fields are usually optional.

  $ cat > crs-config.json <<EOF
  > { invalid_crs_annotation_severity: [ "Error" ] }
  > EOF

  $ crs tools config validate crs-config.json --print
  File "crs-config.json", line 1, characters 0-0:
  Warning: The config field name [invalid_crs_annotation_severity] is now
  expected to be a json string rather than a list.
  Hint: Change it to simply: "Error"
  ((invalid_crs_annotation_severity Error))

Unknown field.

  $ cat > crs-config.json <<EOF
  > { unknown_field: "Hello" }
  > EOF

  $ crs tools config validate crs-config.json >out 2>&1
  $ cat out | sed 's/[a-zA-Z0-9._\/-]*config\.ml/<PATH>\/config.ml/g'
  File "crs-config.json", line 1, characters 0-0:
  Warning: Unknown config field: [unknown_field]
  Hint: Check the documentation for valid field names.

Invalid value.

  $ cat > crs-config.json <<EOF
  > { invalid_crs_annotation_severity: [ "Unknown" ] }
  > EOF

  $ crs tools config validate crs-config.json >out 2>&1
  [123]
  $ cat out | sed 's/[a-zA-Z0-9._\/-]*config\.ml/<PATH>\/config.ml/g'
  File "crs-config.json", line 1, characters 0-0:
  Error: Field [invalid_crs_annotation_severity]:
  Unsupported annotation severity "Unknown".
