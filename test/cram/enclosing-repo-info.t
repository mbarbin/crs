First we need to setup a repo in a way that satisfies the test environment. This
includes specifics required by the GitHub Actions environment.

  $ ROOT=$(pwd)

Git

  $ mkdir repo-git

  $ cd repo-git

  $ volgo-vcs init -q .
  $ volgo-vcs set-user-config --user.name "Test User" --user.email "test@example.com"

  $ cat > hello << EOF
  > Hello World
  > EOF

  $ volgo-vcs add hello
  $ rev0=$(volgo-vcs commit -m "Initial commit")

  $ crs tools enclosing-repo-info
  {
    "repo_root": "$TESTCASE_ROOT/repo-git",
    "path_in_repo": "./",
    "vcs_kind": "Git"
  }

  $ mkdir -p path/in/repo

  $ (cd path/in/repo ; crs tools enclosing-repo-info)
  {
    "repo_root": "$TESTCASE_ROOT/repo-git",
    "path_in_repo": "path/in/repo/",
    "vcs_kind": "Git"
  }

Hg

  $ cd $ROOT

  $ mkdir repo-hg

  $ cd repo-hg

  $ hg init 2> /dev/null

  $ cat > hello << EOF
  > Hello World
  > EOF

  $ volgo-vcs add hello
  $ rev0=$(volgo-vcs commit -m "Initial commit")

  $ crs tools enclosing-repo-info
  {
    "repo_root": "$TESTCASE_ROOT/repo-hg",
    "path_in_repo": "./",
    "vcs_kind": "Hg"
  }

  $ mkdir -p path/in/repo

  $ (cd path/in/repo ; crs tools enclosing-repo-info)
  {
    "repo_root": "$TESTCASE_ROOT/repo-hg",
    "path_in_repo": "path/in/repo/",
    "vcs_kind": "Hg"
  }
