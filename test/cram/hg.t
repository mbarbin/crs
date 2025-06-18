First we need to setup a repo in a way that satisfies the test environment. This
includes specifics required by the GitHub Actions environment.

  $ hg init 2> /dev/null

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

  $ volgo-vcs add hello
  $ rev0=$(volgo-vcs commit -m "Initial commit")

If we grep from there, there is no CR in the tree.

  $ crs grep --sexp

  $ crs grep --summary

Now let's add some CRs.

  $ printf "(* $CR user1 for user2: Hey, this is a code review comment *)\n" >> hello

  $ volgo-vcs add hello
  $ rev1=$(volgo-vcs commit -m "CRs")

Now let's grep for the CRs.

  $ crs grep
  File "hello", line 2, characters 0-60:
    CR user1 for user2: Hey, this is a code review comment
