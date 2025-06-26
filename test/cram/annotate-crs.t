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
  > , user_mentions_whitelist: [ "user1", "user2", "pr-author" ]
  > , invalid_crs_annotation_severity: [ "Warning" ]
  > , crs_due_now_annotation_severity: [ "Info" ]
  > }
  > EOF

  $ crs tools github annotate-crs --config=crs-config.json
  ::notice file=foo/a.txt,line=2,col=1,endLine=2,endColumn=39,title=XCR::This XCR is assigned to user1 (CR reporter).
  ::notice file=foo/foo.c,line=1,col=1,endLine=1,endColumn=61,title=CR::This CR is assigned to user3 (CR recipient).
  ::notice file=foo/pr.ml,line=1,col=1,endLine=1,endColumn=51,title=CR::This CR is assigned to user1 (default repo owner).
  ::notice file=hello,line=2,col=1,endLine=2,endColumn=61,title=CR::This CR is assigned to user2 (CR recipient).

Test it in the context of a pull review too.

  $ crs tools github annotate-crs --config=crs-config.json \
  >   --review-mode=pull-request \
  >   --pull-request-author="pr-author"
  ::notice file=foo/a.txt,line=2,col=1,endLine=2,endColumn=39,title=XCR::This XCR is assigned to user1 (CR reporter).
  ::notice file=foo/foo.c,line=1,col=1,endLine=1,endColumn=61,title=CR::This CR is assigned to user3 (CR recipient).
  ::notice file=foo/pr.ml,line=1,col=1,endLine=1,endColumn=51,title=CR::This CR is assigned to pr-author (PR author).
  ::notice file=hello,line=2,col=1,endLine=2,endColumn=61,title=CR::This CR is assigned to user2 (CR recipient).

Let's test the reviewdog annotations too.

  $ crs tools reviewdog annotate-crs | tee without-config
  {
    "severity": "INFO",
    "source": { "url": "https://github.com/mbarbin/crs", "name": "crs" },
    "diagnostics": [
      {
        "relatedLocations": [],
        "originalOutput": "XCR user1: Fix this. Edit: Done.",
        "suggestions": [],
        "severity": "INFO",
        "location": {
          "range": {
            "end": { "column": 39, "line": 2 },
            "start": { "column": 1, "line": 2 }
          },
          "path": "foo/a.txt"
        },
        "message": "This XCR is assigned to user1 (CR reporter)."
      },
      {
        "relatedLocations": [],
        "originalOutput": "CR user1 for user3: Hey, this is a code review comment",
        "suggestions": [],
        "severity": "INFO",
        "location": {
          "range": {
            "end": { "column": 61, "line": 1 },
            "start": { "column": 1, "line": 1 }
          },
          "path": "foo/foo.c"
        },
        "message": "This CR is assigned to user3 (CR recipient)."
      },
      {
        "relatedLocations": [],
        "originalOutput": "CR user1: Hey, this is a code review comment",
        "suggestions": [],
        "severity": "INFO",
        "location": {
          "range": {
            "end": { "column": 51, "line": 1 },
            "start": { "column": 1, "line": 1 }
          },
          "path": "foo/pr.ml"
        },
        "message": "This CR is unassigned (no default repo owner configured)."
      },
      {
        "relatedLocations": [],
        "originalOutput": "CR user1 for user2: Hey, this is a code review comment",
        "suggestions": [],
        "severity": "INFO",
        "location": {
          "range": {
            "end": { "column": 61, "line": 2 },
            "start": { "column": 1, "line": 2 }
          },
          "path": "hello"
        },
        "message": "This CR is assigned to user2 (CR recipient)."
      }
    ]
  }

  $ crs tools reviewdog annotate-crs --config=crs-config.json > with-config

  $ diff without-config with-config
  45c45
  <       "message": "This CR is unassigned (no default repo owner configured)."
  ---
  >       "message": "This CR is assigned to user1 (default repo owner)."
  [1]

  $ crs tools reviewdog annotate-crs --config=crs-config.json \
  >   --review-mode=pull-request \
  >   --pull-request-author="pr-author" \
  >   --with-user-mentions=true \
  >  > for-pull-request

  $ diff with-config for-pull-request
  17c17
  <       "message": "This XCR is assigned to user1 (CR reporter)."
  ---
  >       "message": "This XCR is assigned to @user1 (CR reporter)."
  45c45
  <       "message": "This CR is assigned to user1 (default repo owner)."
  ---
  >       "message": "This CR is assigned to @pr-author (PR author)."
  59c59
  <       "message": "This CR is assigned to user2 (CR recipient)."
  ---
  >       "message": "This CR is assigned to @user2 (CR recipient)."
  [1]

We can also print a summary comment,

  $ crs tools github summary-comment | tee without-config
  ```
  ┌─────────┬───────┐
  │ CR Type │ Count │
  ├─────────┼───────┤
  │ CR      │     3 │
  │ XCR     │     1 │
  └─────────┴───────┘
  ```
  
  ```
  ┌──────────┬───────┬─────┬──────┬───────┐
  │ Reporter │ For   │ CRs │ XCRs │ Total │
  ├──────────┼───────┼─────┼──────┼───────┤
  │ user1    │       │   1 │    1 │     2 │
  │ user1    │ user2 │   1 │      │     1 │
  │ user1    │ user3 │   1 │      │     1 │
  └──────────┴───────┴─────┴──────┴───────┘
  ```
  
  Users with active CRs/XCRs: user1, user2, user3

  $ crs tools github summary-comment --config=crs-config.json \
  >   --review-mode=pull-request \
  >   --pull-request-author="pr-author" \
  >   --with-user-mentions=true \
  >  > for-pull-request

  $ diff without-config for-pull-request
  20c20
  < Users with active CRs/XCRs: user1, user2, user3
  ---
  > Users with active CRs/XCRs: @pr-author, @user1, @user2, user3
  [1]
