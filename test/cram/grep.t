First we need to setup a repo in a way that satisfies the test environment. This
includes specifics required by the GitHub Actions environment.

  $ ocaml-vcs init -q .
  $ ocaml-vcs set-user-config --user.name "Test User" --user.email "test@example.com"

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

  $ ocaml-vcs add hello
  $ ocaml-vcs add foo
  $ rev0=$(ocaml-vcs commit -m "Initial commit")

Making sure the branch name is deterministic.

  $ ocaml-vcs rename-current-branch main

If we grep from there, there is no CR in the tree.

  $ crs grep --sexp

  $ crs grep --summary

Now let's add some CRs.

  $ echo -e "(* $CR user1 for user2: Hey, this is a code review comment *)" >> hello

  $ echo -e "(* ${XCR} user1: Fix this. Edit: Done. *)" >> foo/a.txt

  $ echo -e "(* ${CR}-someday user1: Reconsider if/when updating to the new version. *)" >> foo/b.txt

  $ echo -e "(* ${CR}-soon user1: Hey, this is a code review comment *)" >> foo/bar/b.txt

To avoid ignoring CRs that are unintentionally invalid, the tool will
recognized comments that look like CRs, but flag them as invalid.

  $ echo -e "(* ${CR}-user: Hey, I'm trying to use CR, it's cool! *)" >> foo/bar/c.txt

  $ echo -e "(* ${CR} : Hey, this comment look like a CR but it's not quite one. *)" >> foo/bar/d.txt

  $ ocaml-vcs add hello
  $ ocaml-vcs add foo
  $ rev1=$(ocaml-vcs commit -m "CRs")

Now let's grep for the CRs.

A basic [sexp] output is available.

  $ crs grep --sexp
  ((path foo/a.txt) (whole_loc _)
   (header (Ok ((kind XCR) (due Now) (reported_by user1) (for_ ()))))
   (digest_of_condensed_content 262c4b02b87f666df980367786893523)
   (content "XCR user1: Fix this. Edit: Done. "))
  ((path foo/b.txt) (whole_loc _)
   (header (Ok ((kind CR) (due Someday) (reported_by user1) (for_ ()))))
   (digest_of_condensed_content 7559cebcfe10fd5644d85ee54c35b98c)
   (content
    "CR-someday user1: Reconsider if/when updating to the new version. "))
  ((path foo/bar/b.txt) (whole_loc _)
   (header (Ok ((kind CR) (due Soon) (reported_by user1) (for_ ()))))
   (digest_of_condensed_content 3005cc8ff9fb95e8701310f3b15f1673)
   (content "CR-soon user1: Hey, this is a code review comment "))
  ((path foo/bar/c.txt) (whole_loc _)
   (header
    (Error
     ("Invalid CR comment" "CR-user: Hey, I'm trying to use CR, it's cool! ")))
   (digest_of_condensed_content 59de0cbac075472487591f107b23706c)
   (content "CR-user: Hey, I'm trying to use CR, it's cool! "))
  ((path foo/bar/d.txt) (whole_loc _)
   (header
    (Error
     ("Invalid CR comment"
      "CR : Hey, this comment look like a CR but it's not quite one. ")))
   (digest_of_condensed_content c03a43e4e1040fd99f1cd3dbdcc5bd50)
   (content "CR : Hey, this comment look like a CR but it's not quite one. "))
  ((path hello) (whole_loc _)
   (header (Ok ((kind CR) (due Now) (reported_by user1) (for_ (user2)))))
   (digest_of_condensed_content 46184503e2b9027e05e1ac2899a4e8b3)
   (content "CR user1 for user2: Hey, this is a code review comment "))

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

There's also an option to display the results as summary tables.

  $ crs grep --summary
  ┌─────────┬───────┐
  │ type    │ count │
  ├─────────┼───────┤
  │ Invalid │     2 │
  │ CR      │     1 │
  │ XCR     │     1 │
  │ Soon    │     1 │
  │ Someday │     1 │
  └─────────┴───────┘
  
  ┌──────────┬───────┬─────┬──────┬──────┬─────────┬───────┐
  │ reporter │ for   │ CRs │ XCRs │ Soon │ Someday │ Total │
  ├──────────┼───────┼─────┼──────┼──────┼─────────┼───────┤
  │ user1    │       │     │    1 │    1 │       1 │     3 │
  │ user1    │ user2 │   1 │      │      │         │     1 │
  └──────────┴───────┴─────┴──────┴──────┴─────────┴───────┘

Summary tables may not be displayed as sexps.

  $ crs grep --summary --sexp
  Error: The flags [sexp] and [summary] are exclusive.
  Hint: Please choose one.
  [124]
