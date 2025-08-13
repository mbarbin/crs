First we need to setup a repo in a way that satisfies the test environment. This
includes specifics required by the GitHub Actions environment.

  $ volgo-vcs init -q .
  $ volgo-vcs set-user-config --user.name "Test User" --user.email "test@example.com"

To make sure the CRs are not mistaken for actual cr comments in this
file, we make use of some trick.

  $ export CR="CR"
  $ export XCR="XCR"

Let's add some files to the tree.

  $ cat > hello << EOF
  > Hello World
  > EOF

  $ cat hello
  Hello World

  $ mkdir -p foo/bar

  $ cat > foo/a.txt << EOF
  > Some contents in this file.
  > EOF

  $ cat > foo/bar/b.txt << EOF
  > Some contents in this file too.
  > EOF

  $ volgo-vcs add hello
  $ volgo-vcs add foo
  $ rev0=$(volgo-vcs commit -m "Initial commit")

Making sure the branch name is deterministic.

  $ volgo-vcs rename-current-branch main

Now let's add some CRs.

  $ printf "(* $CR user1: Hey, this is a code review comment *)\n" >> foo/pr.ml

  $ printf "(* $CR user1 for user2: Hey, this is a code review comment *)\n" >> hello

  $ printf "(* ${XCR} user1: Fix this. Edit: Done. *)\n" >> foo/a.txt

  $ printf "/* $CR user1 for user3: Hey, this is a code review comment */\n" >> foo/foo.c

  $ printf "(* ${CR}-someday user1: Reconsider if/when updating to the new version. *)\n" >> foo/b.txt

  $ printf "(* ${CR}-soon user1: Hey, this is a code review comment *)\n" >> foo/bar/b.txt

  $ volgo-vcs add hello
  $ volgo-vcs add foo
  $ rev1=$(volgo-vcs commit -m "CRs")

Next we exercise some commands that can create annotations for CRs.

  $ crs tools github annotate-crs
  ::notice file=foo/a.txt,line=2,col=1,endLine=2,endColumn=39,title=XCR::This XCR is assigned to user1 (CR reporter).
  ::notice file=foo/foo.c,line=1,col=1,endLine=1,endColumn=61,title=CR::This CR is assigned to user3 (CR recipient).
  ::notice file=foo/pr.ml,line=1,col=1,endLine=1,endColumn=51,title=CR::This CR is unassigned (no default repo owner configured).
  ::notice file=hello,line=2,col=1,endLine=2,endColumn=61,title=CR::This CR is assigned to user2 (CR recipient).

Let's add a config.

  $ cat > crs-config.json <<EOF
  > { default_repo_owner: "user1"
  > , user_mentions_allowlist: [ "user1", "user2", "pr-author" ]
  > , invalid_crs_annotation_severity: "Warning"
  > , crs_due_now_annotation_severity: "Info"
  > }
  > EOF

Test that deprecated field generates a warning with GitHub annotations.

  $ cat > crs-config-deprecated.json <<EOF
  > { default_repo_owner: "user1"
  > , user_mentions_whitelist: [ "user1", "user2", "pr-author" ]
  > , invalid_crs_annotation_severity: "Warning"
  > , crs_due_now_annotation_severity: "Info"
  > }
  > EOF

  $ crs tools github annotate-crs --config=crs-config-deprecated.json
  File "crs-config-deprecated.json", line 1, characters 0-0:
  Warning: The config field name [user_mentions_whitelist] is deprecated and
  was renamed [user_mentions_allowlist].
  Hint: Upgrade the config to use the new name.
  ::warning file=crs-config-deprecated.json,line=1,col=1,endLine=1,endColumn=1,title=crs::The config field name [user_mentions_whitelist] is deprecated and was renamed%0A[user_mentions_allowlist].%0AHints: Upgrade the config to use the new%0Aname.
  ::notice file=foo/a.txt,line=2,col=1,endLine=2,endColumn=39,title=XCR::This XCR is assigned to user1 (CR reporter).
  ::notice file=foo/foo.c,line=1,col=1,endLine=1,endColumn=61,title=CR::This CR is assigned to user3 (CR recipient).
  ::notice file=foo/pr.ml,line=1,col=1,endLine=1,endColumn=51,title=CR::This CR is assigned to user1 (default repo owner).
  ::notice file=hello,line=2,col=1,endLine=2,endColumn=61,title=CR::This CR is assigned to user2 (CR recipient).

  $ crs tools github annotate-crs --config=crs-config.json
  ::notice file=foo/a.txt,line=2,col=1,endLine=2,endColumn=39,title=XCR::This XCR is assigned to user1 (CR reporter).
  ::notice file=foo/foo.c,line=1,col=1,endLine=1,endColumn=61,title=CR::This CR is assigned to user3 (CR recipient).
  ::notice file=foo/pr.ml,line=1,col=1,endLine=1,endColumn=51,title=CR::This CR is assigned to user1 (default repo owner).
  ::notice file=hello,line=2,col=1,endLine=2,endColumn=61,title=CR::This CR is assigned to user2 (CR recipient).

Test it in the context of a pull review too.

  $ crs tools github annotate-crs --config=crs-config.json \
  >   --review-mode=pull-request \
  >   --pull-request-author="pr-author"
  Warning: Review mode [pull-request] requires [--pull-request-base].
  It will become mandatory in the future, please attend.
  ::warning title=crs::Review mode [pull-request] requires [--pull-request-base].%0AIt will become mandatory in the future, please attend.
  ::notice file=foo/a.txt,line=2,col=1,endLine=2,endColumn=39,title=XCR::This XCR is assigned to user1 (CR reporter).
  ::notice file=foo/foo.c,line=1,col=1,endLine=1,endColumn=61,title=CR::This CR is assigned to user3 (CR recipient).
  ::notice file=foo/pr.ml,line=1,col=1,endLine=1,endColumn=51,title=CR::This CR is assigned to pr-author (PR author).
  ::notice file=hello,line=2,col=1,endLine=2,endColumn=61,title=CR::This CR is assigned to user2 (CR recipient).

Let's add the required base revision.

  $ crs tools github annotate-crs --config=crs-config.json \
  >   --review-mode=pull-request \
  >   --pull-request-author="pr-author" \
  >   --pull-request-base="${rev0}"
  ::notice file=foo/a.txt,line=2,col=1,endLine=2,endColumn=39,title=XCR::This XCR is assigned to user1 (CR reporter).
  ::notice file=foo/foo.c,line=1,col=1,endLine=1,endColumn=61,title=CR::This CR is assigned to user3 (CR recipient).
  ::notice file=foo/pr.ml,line=1,col=1,endLine=1,endColumn=51,title=CR::This CR is assigned to pr-author (PR author).
  ::notice file=hello,line=2,col=1,endLine=2,endColumn=61,title=CR::This CR is assigned to user2 (CR recipient).

Let's test the reviewdog annotations too.

  $ crs tools reviewdog annotate-crs | tee without-config
  {
    "source": { "name": "crs", "url": "https://github.com/mbarbin/crs" },
    "severity": "INFO",
    "diagnostics": [
      {
        "message": "This XCR is assigned to user1 (CR reporter).",
        "location": {
          "path": "foo/a.txt",
          "range": {
            "start": { "line": 2, "column": 1 },
            "end": { "line": 2, "column": 39 }
          }
        },
        "severity": "INFO",
        "originalOutput": "XCR user1: Fix this. Edit: Done."
      },
      {
        "message": "This CR is assigned to user3 (CR recipient).",
        "location": {
          "path": "foo/foo.c",
          "range": {
            "start": { "line": 1, "column": 1 },
            "end": { "line": 1, "column": 61 }
          }
        },
        "severity": "INFO",
        "originalOutput": "CR user1 for user3: Hey, this is a code review comment"
      },
      {
        "message": "This CR is unassigned (no default repo owner configured).",
        "location": {
          "path": "foo/pr.ml",
          "range": {
            "start": { "line": 1, "column": 1 },
            "end": { "line": 1, "column": 51 }
          }
        },
        "severity": "INFO",
        "originalOutput": "CR user1: Hey, this is a code review comment"
      },
      {
        "message": "This CR is assigned to user2 (CR recipient).",
        "location": {
          "path": "hello",
          "range": {
            "start": { "line": 2, "column": 1 },
            "end": { "line": 2, "column": 61 }
          }
        },
        "severity": "INFO",
        "originalOutput": "CR user1 for user2: Hey, this is a code review comment"
      }
    ]
  }

  $ crs tools reviewdog annotate-crs --config=crs-config.json > with-config

  $ diff without-config with-config
  30c30
  <       "message": "This CR is unassigned (no default repo owner configured).",
  ---
  >       "message": "This CR is assigned to user1 (default repo owner).",
  [1]

  $ crs tools reviewdog annotate-crs --config=crs-config.json \
  >   --review-mode=pull-request \
  >   --pull-request-author="pr-author" \
  >   --pull-request-base="${rev0}" \
  >   --with-user-mentions=true \
  >  > for-pull-request

  $ diff with-config for-pull-request
  6c6
  <       "message": "This XCR is assigned to user1 (CR reporter).",
  ---
  >       "message": "This XCR is assigned to @user1 (CR reporter).",
  30c30
  <       "message": "This CR is assigned to user1 (default repo owner).",
  ---
  >       "message": "This CR is assigned to @pr-author (PR author).",
  42c42
  <       "message": "This CR is assigned to user2 (CR recipient).",
  ---
  >       "message": "This CR is assigned to @user2 (CR recipient).",
  [1]

We can also print a summary comment,

  $ crs tools github summary-comment | tee without-config
  | CR Type | Count |
  |:--------|------:|
  | CR      |     3 |
  | XCR     |     1 |
  
  | Reporter | For   | CRs | XCRs | Total |
  |:---------|:------|----:|-----:|------:|
  | user1    |       |   1 |    1 |     2 |
  | user1    | user2 |   1 |      |     1 |
  | user1    | user3 |   1 |      |     1 |
  
  Users with assigned CRs/XCRs: user1, user2, user3

  $ crs tools github summary-comment --config=crs-config.json \
  >   --review-mode=pull-request \
  >   --pull-request-author="pr-author" \
  >   --pull-request-base="${rev0}" \
  >   --with-user-mentions=true \
  >  > for-pull-request

  $ diff without-config for-pull-request
  12c12
  < Users with assigned CRs/XCRs: user1, user2, user3
  ---
  > Users with assigned CRs/XCRs: @pr-author, @user1, @user2, user3
  [1]
