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

If we grep from there, there is no CR in the tree.

  $ crs tools emacs-grep

Now let's add some CRs.

  $ printf "(* $CR user1 for user2: Hey, this is a code review comment *)\n" >> hello

  $ printf "(* ${XCR} user1: Fix this. Edit: Done. *)\n" >> foo/a.txt

  $ printf "/* $CR user1 for user3: Hey, this is a code review comment */\n" >> foo/foo.c

  $ printf "(* ${CR}-someday user1: Reconsider if/when updating to the new version. *)\n" >> foo/b.txt

  $ printf "(* ${CR}-soon user1: Hey, this is a code review comment *)\n" >> foo/bar/b.txt

  $ volgo-vcs add hello
  $ volgo-vcs add foo
  $ rev1=$(volgo-vcs commit -m "CRs")

Now let's grep for the CRs.

For an easier integration with emacs `grep-mode`, the location are displayed
using a special syntax.

  $ crs tools emacs-grep
  ./foo/a.txt:2:
    XCR user1: Fix this. Edit: Done.
  
  ./foo/b.txt:1:
    CR-someday user1: Reconsider if/when updating to the new version.
  
  ./foo/bar/b.txt:2:
    CR-soon user1: Hey, this is a code review comment
  
  ./foo/foo.c:1:
    CR user1 for user3: Hey, this is a code review comment
  
  ./hello:2:
    CR user1 for user2: Hey, this is a code review comment

The emacs grep command supports filtering flags.

  $ crs tools emacs-grep --xcrs
  ./foo/a.txt:2:
    XCR user1: Fix this. Edit: Done.

When launched from a subdir, to facilitate the integration, we can display the
path relative to that subdir from where the command is run.

  $ (cd foo ; crs tools emacs-grep)
  ./a.txt:2:
    XCR user1: Fix this. Edit: Done.
  
  ./b.txt:1:
    CR-someday user1: Reconsider if/when updating to the new version.
  
  ./bar/b.txt:2:
    CR-soon user1: Hey, this is a code review comment
  
  ./foo.c:1:
    CR user1 for user3: Hey, this is a code review comment

It is however also possible to display the path using some other styles.

  $ (cd foo ; crs tools emacs-grep --path-display-mode=relative-to-repo-root)
  ./foo/a.txt:2:
    XCR user1: Fix this. Edit: Done.
  
  ./foo/b.txt:1:
    CR-someday user1: Reconsider if/when updating to the new version.
  
  ./foo/bar/b.txt:2:
    CR-soon user1: Hey, this is a code review comment
  
  ./foo/foo.c:1:
    CR user1 for user3: Hey, this is a code review comment

We do not exercise here the display of absolute path because it would make this
test unstable, however this rendering option is available.

The emacs grep command supports showing summary tables.

  $ crs tools emacs-grep --summary
  ┌─────────┬───────┐
  │ CR Type │ Count │
  ├─────────┼───────┤
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

This option may be combined with other filters when calling from the command
line, however when used through emacs, the filter applied is always "all".

  $ crs tools emacs-grep --summary --xcrs
  ┌─────────┬───────┐
  │ CR Type │ Count │
  ├─────────┼───────┤
  │ XCR     │     1 │
  └─────────┴───────┘
  
  ┌──────────┬──────┬───────┐
  │ Reporter │ XCRs │ Total │
  ├──────────┼──────┼───────┤
  │ user1    │    1 │     1 │
  └──────────┴──────┴───────┘
