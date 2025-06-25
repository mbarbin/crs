First we need to setup a repo in a way that satisfies the test environment. This
includes specifics required by the GitHub Actions environment.

  $ volgo-vcs init -q .
  $ volgo-vcs set-user-config --user.name "Test User" --user.email "test@example.com"

To make sure the CRs are not mistaken for actual cr comments in this
file, we make use of some trick.

  $ export CR="CR"
  $ export XCR="XCR"

We disable the pager in this test.

  $ export GIT_PAGER=cat

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

If we grep from there, there is no CR in the tree.

  $ crs grep --sexp

  $ crs grep --summary

Now let's add some CRs.

  $ printf "(* $CR user1 for user2: Hey, this is a code review comment *)\n" >> hello

  $ printf "(* ${XCR} user1: Fix this. Edit: Done. *)\n" >> foo/a.txt

  $ printf "/* $CR user1 for user3: Hey, this is a code review comment */\n" >> foo/foo.c

  $ printf "(* ${CR}-someday user1: Reconsider if/when updating to the new version. *)\n" >> foo/b.txt

  $ printf "(* ${CR}-soon user1: Hey, this is a code review comment *)\n" >> foo/bar/b.txt

To avoid ignoring CRs that are unintentionally invalid, the tool will
recognized comments that look like CRs, but flag them as invalid.

  $ printf "(* ${CR}-user: Hey, I'm trying to use CR, it's cool! *)\n" >> foo/bar/c.txt

  $ printf "(* ${CR} : Hey, this comment look like a CR but it's not quite one. *)\n" >> foo/bar/d.txt

We do not match CRs when they are located in ignored or untracked files.

  $ printf "(* $CR user1: A CR in an untracked file. *)\n" > untracked-file
  $ printf "(* $CR user1: A CR in an ignored file. *)\n" > ignored-file
  $ echo "ignored-file" >> .gitignore
  $ volgo-vcs add .gitignore

We also specifically ignore binary files.

  $ printf "\000 \n(* $CR user1: This is CR in a binary file - it is ignored. *)" > binary-file

  $ grep 'CR' binary-file --binary-file=without-match
  [1]

  $ volgo-vcs add hello
  $ volgo-vcs add foo
  $ volgo-vcs add binary-file
  $ rev1=$(volgo-vcs commit -m "CRs")

Now let's grep for the CRs.

A basic [sexp] output is available.

  $ crs grep --sexp
  ((path foo/a.txt) (whole_loc ((start foo/a.txt:2:0) (stop foo/a.txt:2:38)))
   (header
    (Ok
     ((kind ((txt XCR) (loc ((start foo/a.txt:2:3) (stop foo/a.txt:2:6)))))
      (qualifier
       ((txt None) (loc ((start foo/a.txt:2:3) (stop foo/a.txt:2:6)))))
      (reporter
       ((txt user1) (loc ((start foo/a.txt:2:7) (stop foo/a.txt:2:12)))))
      (recipient ()))))
   (comment_prefix "(*")
   (digest_of_condensed_content 9dce8eceb787a95abf3fccb037d164ea)
   (content "XCR user1: Fix this. Edit: Done."))
  ((path foo/b.txt) (whole_loc ((start foo/b.txt:1:0) (stop foo/b.txt:1:71)))
   (header
    (Ok
     ((kind ((txt CR) (loc ((start foo/b.txt:1:3) (stop foo/b.txt:1:5)))))
      (qualifier
       ((txt Someday) (loc ((start foo/b.txt:1:6) (stop foo/b.txt:1:13)))))
      (reporter
       ((txt user1) (loc ((start foo/b.txt:1:14) (stop foo/b.txt:1:19)))))
      (recipient ()))))
   (comment_prefix "(*")
   (digest_of_condensed_content 22722b7a3948f75ec004a651d97d02bb)
   (content
    "CR-someday user1: Reconsider if/when updating to the new version."))
  ((path foo/bar/b.txt)
   (whole_loc ((start foo/bar/b.txt:2:0) (stop foo/bar/b.txt:2:55)))
   (header
    (Ok
     ((kind
       ((txt CR) (loc ((start foo/bar/b.txt:2:3) (stop foo/bar/b.txt:2:5)))))
      (qualifier
       ((txt Soon) (loc ((start foo/bar/b.txt:2:6) (stop foo/bar/b.txt:2:10)))))
      (reporter
       ((txt user1)
        (loc ((start foo/bar/b.txt:2:11) (stop foo/bar/b.txt:2:16)))))
      (recipient ()))))
   (comment_prefix "(*")
   (digest_of_condensed_content 8b683d9bff5df08ee3642df3cf2426ce)
   (content "CR-soon user1: Hey, this is a code review comment"))
  ((path foo/bar/c.txt)
   (whole_loc ((start foo/bar/c.txt:1:0) (stop foo/bar/c.txt:1:52)))
   (header
    (Error
     ("Invalid CR comment" "CR-user: Hey, I'm trying to use CR, it's cool!")))
   (comment_prefix "(*")
   (digest_of_condensed_content 49a84095611ebd8cb3f83e4546e67533)
   (content "CR-user: Hey, I'm trying to use CR, it's cool!"))
  ((path foo/bar/d.txt)
   (whole_loc ((start foo/bar/d.txt:1:0) (stop foo/bar/d.txt:1:67)))
   (header
    (Error
     ("Invalid CR comment"
      "CR : Hey, this comment look like a CR but it's not quite one.")))
   (comment_prefix "(*")
   (digest_of_condensed_content d8a25b0acac6d3a23ff4f4c1e4c990a3)
   (content "CR : Hey, this comment look like a CR but it's not quite one."))
  ((path foo/foo.c) (whole_loc ((start foo/foo.c:1:0) (stop foo/foo.c:1:60)))
   (header
    (Ok
     ((kind ((txt CR) (loc ((start foo/foo.c:1:3) (stop foo/foo.c:1:5)))))
      (qualifier
       ((txt None) (loc ((start foo/foo.c:1:3) (stop foo/foo.c:1:5)))))
      (reporter
       ((txt user1) (loc ((start foo/foo.c:1:6) (stop foo/foo.c:1:11)))))
      (recipient
       (((txt user3) (loc ((start foo/foo.c:1:16) (stop foo/foo.c:1:21)))))))))
   (comment_prefix /*)
   (digest_of_condensed_content 4721a5c5f8a37bdcb9e065268bbd0153)
   (content "CR user1 for user3: Hey, this is a code review comment"))
  ((path hello) (whole_loc ((start hello:2:0) (stop hello:2:60)))
   (header
    (Ok
     ((kind ((txt CR) (loc ((start hello:2:3) (stop hello:2:5)))))
      (qualifier ((txt None) (loc ((start hello:2:3) (stop hello:2:5)))))
      (reporter ((txt user1) (loc ((start hello:2:6) (stop hello:2:11)))))
      (recipient (((txt user2) (loc ((start hello:2:16) (stop hello:2:21)))))))))
   (comment_prefix "(*")
   (digest_of_condensed_content 970aabfe0c3d4ec5707918edd3f01a8a)
   (content "CR user1 for user2: Hey, this is a code review comment"))

The default is to print them, visually separated.

  $ crs grep
  File "foo/a.txt", line 2, characters 0-38:
    XCR user1: Fix this. Edit: Done.
  
  File "foo/b.txt", line 1, characters 0-71:
    CR-someday user1: Reconsider if/when updating to the new version.
  
  File "foo/bar/b.txt", line 2, characters 0-55:
    CR-soon user1: Hey, this is a code review comment
  
  File "foo/bar/c.txt", line 1, characters 0-52:
    CR-user: Hey, I'm trying to use CR, it's cool!
  
  File "foo/bar/d.txt", line 1, characters 0-67:
    CR : Hey, this comment look like a CR but it's not quite one.
  
  File "foo/foo.c", line 1, characters 0-60:
    CR user1 for user3: Hey, this is a code review comment
  
  File "hello", line 2, characters 0-60:
    CR user1 for user2: Hey, this is a code review comment

You may restrict the search to a subdirectory only.

  $ crs grep --below ./foo/bar
  File "foo/bar/b.txt", line 2, characters 0-55:
    CR-soon user1: Hey, this is a code review comment
  
  File "foo/bar/c.txt", line 1, characters 0-52:
    CR-user: Hey, I'm trying to use CR, it's cool!
  
  File "foo/bar/d.txt", line 1, characters 0-67:
    CR : Hey, this comment look like a CR but it's not quite one.

  $ crs grep --below /tmp
  Error: Path "/tmp" is not in repo.
  [123]

  $ crs grep --below not-a-directory
  Context:
  (Vcs.ls_files
   (repo_root
    $TESTCASE_ROOT)
   (below not-a-directory))
  ((prog git) (args (ls-files --full-name)) (exit_status Unknown)
   (cwd
    $TESTCASE_ROOT/not-a-directory)
   (stdout "") (stderr ""))
  Error:
  (Unix.Unix_error "No such file or directory" chdir
   $TESTCASE_ROOT/not-a-directory)
  [123]

  $ mkdir empty-directory
  $ crs grep --below empty-directory

Filtering flags are available to select a subset of the CRs.

  $ crs grep --xcrs
  File "foo/a.txt", line 2, characters 0-38:
    XCR user1: Fix this. Edit: Done.

Filtering flags may be combined to select their union.

  $ crs grep --soon --someday
  File "foo/b.txt", line 1, characters 0-71:
    CR-someday user1: Reconsider if/when updating to the new version.
  
  File "foo/bar/b.txt", line 2, characters 0-55:
    CR-soon user1: Hey, this is a code review comment

There's also an option to display the results as summary tables.

  $ crs grep --summary
  ┌─────────┬───────┐
  │ CR Type │ Count │
  ├─────────┼───────┤
  │ Invalid │     2 │
  │ CR      │     2 │
  │ XCR     │     1 │
  │ Soon    │     1 │
  │ Someday │     1 │
  └─────────┴───────┘
  
  ┌──────────┬───────┬─────┬──────┬──────┬─────────┬───────┐
  │ Reporter │ For   │ CRs │ XCRs │ Soon │ Someday │ Total │
  ├──────────┼───────┼─────┼──────┼──────┼─────────┼───────┤
  │ user1    │       │     │    1 │    1 │       1 │     3 │
  │ user1    │ user2 │   1 │      │      │         │     1 │
  │ user1    │ user3 │   1 │      │      │         │     1 │
  └──────────┴───────┴─────┴──────┴──────┴─────────┴───────┘

  $ crs grep --below ./foo/bar --summary
  ┌─────────┬───────┐
  │ CR Type │ Count │
  ├─────────┼───────┤
  │ Invalid │     2 │
  │ Soon    │     1 │
  └─────────┴───────┘
  
  ┌──────────┬──────┬───────┐
  │ Reporter │ Soon │ Total │
  ├──────────┼──────┼───────┤
  │ user1    │    1 │     1 │
  └──────────┴──────┴───────┘

Summary tables may not be displayed as sexps.

  $ crs grep --summary --sexp
  Error: The flags [sexp] and [summary] are exclusive.
  Hint: Please choose one.
  [124]

The grep strategy involves a first filtering of the files based on a regexp
matching. This involves running [xargs]. Let's cover for some failures there.

  $ cat > xargs <<EOF
  > #!/bin/bash -e
  > # Read and discard all stdin to avoid broken pipe
  > cat > /dev/null
  > echo "Hello Fake xargs"
  > exit 42
  > EOF
  $ chmod +x ./xargs

  $ PATH=".:$PATH" crs grep
  Error: Process xargs exited abnormally.
  ((exit_status (Exited 42)) (stdout "Hello Fake xargs\n") (stderr ""))
  [123]

When the return code is `1` or `123` we require stderr to be empty.

  $ cat > xargs <<EOF
  > #!/bin/bash -e
  > # Read and discard all stdin to avoid broken pipe
  > cat > /dev/null
  > echo "Hello Fake xargs" >&2
  > exit 1
  > EOF
  $ chmod +x ./xargs

  $ PATH=".:$PATH" crs grep
  Error: Process xargs exited abnormally.
  ((exit_status (Exited 1)) (stdout "") (stderr "Hello Fake xargs\n"))
  [123]

  $ cat > xargs <<EOF
  > #!/bin/bash -e
  > # Read and discard all stdin to avoid broken pipe
  > cat > /dev/null
  > echo "Hello Fake xargs" >&2
  > exit 123
  > EOF
  $ chmod +x ./xargs

  $ PATH=".:$PATH" crs grep
  Error: Process xargs exited abnormally.
  ((exit_status (Exited 123)) (stdout "") (stderr "Hello Fake xargs\n"))
  [123]

  $ cat > xargs <<EOF
  > #!/bin/bash -e
  > # Read and discard all stdin to avoid broken pipe
  > cat > /dev/null
  > exit 1
  > EOF
  $ chmod +x ./xargs

  $ PATH=".:$PATH" crs grep

  $ cat > xargs <<EOF
  > #!/bin/bash -e
  > # Read and discard all stdin to avoid broken pipe
  > cat > /dev/null
  > exit 123
  > EOF
  $ chmod +x ./xargs

  $ PATH=".:$PATH" crs grep

When [xargs] runs the grep command several times, if one of the command yields
no match, the exit code of the overall call to [xargs] will be [123]. However,
in this case its output will contain matches from the other run, and thus this
needs to be treated as a successful execution. We cover this below.

  $ cat > xargs <<EOF
  > #!/bin/bash -e
  > # Read and discard all stdin to avoid broken pipe
  > cat > /dev/null
  > echo "foo/a.txt"
  > exit 1
  > EOF
  $ chmod +x ./xargs

  $ PATH=".:$PATH" crs grep
  File "foo/a.txt", line 2, characters 0-38:
    XCR user1: Fix this. Edit: Done.

  $ cat > xargs <<EOF
  > #!/bin/bash -e
  > # Read and discard all stdin to avoid broken pipe
  > cat > /dev/null
  > echo "foo/a.txt"
  > exit 123
  > EOF
  $ chmod +x ./xargs

  $ PATH=".:$PATH" crs grep
  File "foo/a.txt", line 2, characters 0-38:
    XCR user1: Fix this. Edit: Done.
