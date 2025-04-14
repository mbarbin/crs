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

Now let's add some CRs.

  $ echo -e "(* $CR user1: Hey, this is a code review comment *)" >> hello

  $ echo -e "(* ${XCR} user1: Fix this. Edit: Done. *)" >> foo/a.txt

  $ echo -e "(* ${CR}-soon user1: Hey, this is a code review comment *)" >> foo/bar/b.txt

And grep for them.

A basic [sexp] output is available.

  $ crs grep --sexp
  ((path foo/a.txt) (whole_loc _)
   (header (Ok ((kind XCR) (due Now) (reported_by user1) (for_ ()))))
   (digest_of_condensed_content 262c4b02b87f666df980367786893523)
   (content "XCR user1: Fix this. Edit: Done. "))
  ((path foo/bar/b.txt) (whole_loc _)
   (header (Ok ((kind CR) (due Soon) (reported_by user1) (for_ ()))))
   (digest_of_condensed_content 3005cc8ff9fb95e8701310f3b15f1673)
   (content "CR-soon user1: Hey, this is a code review comment "))
  ((path hello) (whole_loc _)
   (header (Ok ((kind CR) (due Now) (reported_by user1) (for_ ()))))
   (digest_of_condensed_content 1c65b0067541949bf40979567396b403)
   (content "CR user1: Hey, this is a code review comment "))

The default is to print them, visually separated. Here we tweak the output to
avoid risking having actual CRs in this file.

  $ crs grep | sed -e 's/ CR/ $CR/g' -e 's/ XCR/ $XCR/g'
  File "foo/a.txt", line 2, characters 3-41:
    $XCR user1: Fix this. Edit: Done. 
  
  File "foo/bar/b.txt", line 2, characters 3-58:
    $CR-soon user1: Hey, this is a code review comment 
  
  File "hello", line 2, characters 3-53:
    $CR user1: Hey, this is a code review comment 

You may restrict the search to a subdirectory only.

  $ crs grep --below ./foo/bar
  File "foo/bar/b.txt", line 2, characters 3-58:
    CR-soon user1: Hey, this is a code review comment 
