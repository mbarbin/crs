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

  $ echo -e "(* $CR user1 for user2: Hey, this is a code review comment *)" >> hello

  $ echo -e "(* ${XCR} user1: Fix this. Edit: Done. *)" >> foo/a.txt

  $ echo -e "/* $CR user1 for user3: Hey, this is a code review comment */" >> foo/foo.c

  $ echo -e "(* ${CR}-someday user1: Reconsider if/when updating to the new version. *)" >> foo/b.txt

  $ echo -e "(* ${CR}-soon user1: Hey, this is a code review comment *)" >> foo/bar/b.txt

To avoid ignoring CRs that are unintentionally invalid, the tool will
recognized comments that look like CRs, but flag them as invalid.

  $ echo -e "(* ${CR}-user: Hey, I'm trying to use CR, it's cool! *)" >> foo/bar/c.txt

  $ echo -e "(* ${CR} : Hey, this comment look like a CR but it's not quite one. *)" >> foo/bar/d.txt

  $ volgo-vcs add hello
  $ volgo-vcs add foo
  $ rev1=$(volgo-vcs commit -m "CRs")

Now let's grep for the CRs.

A basic [sexp] output is available.

  $ crs grep --sexp
  ((path foo/a.txt) (whole_loc _)
   (header (Ok ((kind XCR) (due Now) (reported_by user1) (for_ ()))))
   (digest_of_condensed_content 9dce8eceb787a95abf3fccb037d164ea)
   (content "XCR user1: Fix this. Edit: Done."))
  ((path foo/b.txt) (whole_loc _)
   (header (Ok ((kind CR) (due Someday) (reported_by user1) (for_ ()))))
   (digest_of_condensed_content 22722b7a3948f75ec004a651d97d02bb)
   (content
    "CR-someday user1: Reconsider if/when updating to the new version."))
  ((path foo/bar/b.txt) (whole_loc _)
   (header (Ok ((kind CR) (due Soon) (reported_by user1) (for_ ()))))
   (digest_of_condensed_content 8b683d9bff5df08ee3642df3cf2426ce)
   (content "CR-soon user1: Hey, this is a code review comment"))
  ((path foo/bar/c.txt) (whole_loc _)
   (header
    (Error
     ("Invalid CR comment" "CR-user: Hey, I'm trying to use CR, it's cool!")))
   (digest_of_condensed_content 49a84095611ebd8cb3f83e4546e67533)
   (content "CR-user: Hey, I'm trying to use CR, it's cool!"))
  ((path foo/bar/d.txt) (whole_loc _)
   (header
    (Error
     ("Invalid CR comment"
      "CR : Hey, this comment look like a CR but it's not quite one.")))
   (digest_of_condensed_content d8a25b0acac6d3a23ff4f4c1e4c990a3)
   (content "CR : Hey, this comment look like a CR but it's not quite one."))
  ((path foo/foo.c) (whole_loc _)
   (header (Ok ((kind CR) (due Now) (reported_by user1) (for_ (user3)))))
   (digest_of_condensed_content 4721a5c5f8a37bdcb9e065268bbd0153)
   (content "CR user1 for user3: Hey, this is a code review comment"))
  ((path hello) (whole_loc _)
   (header (Ok ((kind CR) (due Now) (reported_by user1) (for_ (user2)))))
   (digest_of_condensed_content 970aabfe0c3d4ec5707918edd3f01a8a)
   (content "CR user1 for user2: Hey, this is a code review comment"))

The default is to print them, visually separated.

  $ crs grep
  File "foo/a.txt", line 2, characters 3-41:
    XCR user1: Fix this. Edit: Done.
  
  File "foo/b.txt", line 1, characters 3-74:
    CR-someday user1: Reconsider if/when updating to the new version.
  
  File "foo/bar/b.txt", line 2, characters 3-58:
    CR-soon user1: Hey, this is a code review comment
  
  File "foo/bar/c.txt", line 1, characters 3-55:
    CR-user: Hey, I'm trying to use CR, it's cool!
  
  File "foo/bar/d.txt", line 1, characters 3-70:
    CR : Hey, this comment look like a CR but it's not quite one.
  
  File "foo/foo.c", line 1, characters 3-63:
    CR user1 for user3: Hey, this is a code review comment
  
  File "hello", line 2, characters 3-63:
    CR user1 for user2: Hey, this is a code review comment

You may restrict the search to a subdirectory only.

  $ crs grep --below ./foo/bar
  File "foo/bar/b.txt", line 2, characters 3-58:
    CR-soon user1: Hey, this is a code review comment
  
  File "foo/bar/c.txt", line 1, characters 3-55:
    CR-user: Hey, I'm trying to use CR, it's cool!
  
  File "foo/bar/d.txt", line 1, characters 3-70:
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

There's also an option to display the results as summary tables.

  $ crs grep --summary
  ┌─────────┬───────┐
  │ type    │ count │
  ├─────────┼───────┤
  │ Invalid │     2 │
  │ CR      │     2 │
  │ XCR     │     1 │
  │ Soon    │     1 │
  │ Someday │     1 │
  └─────────┴───────┘
  
  ┌──────────┬───────┬─────┬──────┬──────┬─────────┬───────┐
  │ reporter │ for   │ CRs │ XCRs │ Soon │ Someday │ Total │
  ├──────────┼───────┼─────┼──────┼──────┼─────────┼───────┤
  │ user1    │       │     │    1 │    1 │       1 │     3 │
  │ user1    │ user2 │   1 │      │      │         │     1 │
  │ user1    │ user3 │   1 │      │      │         │     1 │
  └──────────┴───────┴─────┴──────┴──────┴─────────┴───────┘

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
