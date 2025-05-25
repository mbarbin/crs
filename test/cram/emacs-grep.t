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

  $ echo -e "(* $CR user1 for user2: Hey, this is a code review comment *)" >> hello

  $ echo -e "(* ${XCR} user1: Fix this. Edit: Done. *)" >> foo/a.txt

  $ echo -e "/* $CR user1 for user3: Hey, this is a code review comment */" >> foo/foo.c

  $ echo -e "(* ${CR}-someday user1: Reconsider if/when updating to the new version. *)" >> foo/b.txt

  $ echo -e "(* ${CR}-soon user1: Hey, this is a code review comment *)" >> foo/bar/b.txt

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

When launched from a subdir, to facilate the integration, we can display the
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
