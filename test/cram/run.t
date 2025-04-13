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

  $ ocaml-vcs add hello
  $ rev0=$(ocaml-vcs commit -m "Initial commit")

Making sure the branch name is deterministic.

  $ ocaml-vcs rename-current-branch main

If we grep from there, there is no CR in the tree.

  $ crs grep --sexp

Now let's add some CRs.

  $ echo -e "(* $CR user1: Hey, this is a code review comment *)" >> hello

  $ crs grep --sexp
  ((path hello) (whole_loc _)
   (header (Ok ((kind CR) (due Now) (reported_by user1) (for_ ()))))
   (digest_of_condensed_content 1c65b0067541949bf40979567396b403)
   (content "CR user1: Hey, this is a code review comment "))
