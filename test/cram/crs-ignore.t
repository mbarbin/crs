Test the .crs-ignore functionality.

  $ volgo-vcs init -q .
  $ volgo-vcs set-user-config --user.name "Test User" --user.email "test@example.com"

To make sure the CRs are not mistaken for actual cr comments in this
file, we make use of some trick.

  $ export CR="CR"
  $ export XCR="XCR"

Create a repository structure with files and .crs-ignore files:

  $ mkdir -p subdir
  $ mkdir -p vendor
  $ mkdir -p vendor/foo

  $ printf "# Root .crs-ignore file\n" > .crs-ignore
  $ printf "README.md\n" >> .crs-ignore
  $ printf "vendor/**\n" >> .crs-ignore

  $ printf "# Subdir .crs-ignore file\n" > subdir/.crs-ignore
  $ printf "test_*.ml\n" >> subdir/.crs-ignore

Create test files:

  $ printf "(* $CR user1: Hey this is a CR *)\n" > README.md
  $ printf "(* $CR user1: Hey this is a CR *)\n" > foo.ml
  $ printf "(* $CR user1: Hey this is a CR *)\n" > subdir/foo.ml
  $ printf "(* $CR user1: Hey this is a CR *)\n" > subdir/test_foo.ml
  $ printf "(* $CR user1: Hey this is a CR *)\n" > vendor/bar.ml
  $ printf "(* $CR user1: Hey this is a CR *)\n" > vendor/foo/foo.ml

Add files to VCS so they're tracked:

  $ volgo-vcs add .
  $ volgo-vcs commit -q -m "Add test files"

List tracked files.

  $ volgo-vcs ls-files
  .crs-ignore
  README.md
  foo.ml
  subdir/.crs-ignore
  subdir/foo.ml
  subdir/test_foo.ml
  vendor/bar.ml
  vendor/foo/foo.ml

Test the crs-ignore validate command:

  $ crs tools crs-ignore validate

Test the list-included-files command:

  $ crs tools crs-ignore list-included-files
  .crs-ignore
  foo.ml
  subdir/.crs-ignore
  subdir/foo.ml

The list can be restricted below a subdirectory:

  $ crs tools crs-ignore list-included-files --below subdir
  subdir/.crs-ignore
  subdir/foo.ml

Test the list-ignored-files command:

  $ crs tools crs-ignore list-ignored-files
  README.md
  subdir/test_foo.ml
  vendor/bar.ml
  vendor/foo/foo.ml

The list can be restricted below a subdirectory:

  $ crs tools crs-ignore list-ignored-files --below subdir
  subdir/test_foo.ml

Verify explicitly that the test_foo.ml file is ignored:

  $ crs tools crs-ignore list-ignored-files --below subdir | grep test_foo.ml
  subdir/test_foo.ml

Verify that the crs-ignore files are taken into account by the grep commands.

  $ crs grep
  File "foo.ml", line 1, characters 0-32:
    CR user1: Hey this is a CR
  
  File "subdir/foo.ml", line 1, characters 0-32:
    CR user1: Hey this is a CR

  $ crs grep --below vendor

  $ crs tools emacs-grep
  ./foo.ml:1:
    CR user1: Hey this is a CR
  
  ./subdir/foo.ml:1:
    CR user1: Hey this is a CR

Test error and warning handling with invalid glob patterns:

  $ printf "[invalid\n" >> .crs-ignore
  $ crs tools crs-ignore validate
  File "$TESTCASE_ROOT/.crs-ignore", line 4, characters 0-8:
  4 | [invalid
      ^^^^^^^^
  Error: Invalid glob pattern:
  [invalid
  [123]

Test that the command can emit GitHub Annotations.

  $ crs tools crs-ignore validate .crs-ignore --emit-github-annotations=true
  File "$TESTCASE_ROOT/.crs-ignore", line 4, characters 0-8:
  4 | [invalid
      ^^^^^^^^
  Error: Invalid glob pattern:
  [invalid
  ::error file=$TESTCASE_ROOT/.crs-ignore,line=4,col=1,endLine=4,endColumn=9,title=crs::Invalid glob%0Apattern:%0A[invalid
  [123]

When listing files or grepping, invalid patterns are shown as warning only.

  $ crs grep --summary
  File "$TESTCASE_ROOT/.crs-ignore", line 4, characters 0-8:
  4 | [invalid
      ^^^^^^^^
  Warning: Invalid glob pattern:
  [invalid
  ┌─────────┬───────┐
  │ CR Type │ Count │
  ├─────────┼───────┤
  │ CR      │     2 │
  └─────────┴───────┘
  
  ┌──────────┬─────┬───────┐
  │ Reporter │ CRs │ Total │
  ├──────────┼─────┼───────┤
  │ user1    │   2 │     2 │
  └──────────┴─────┴───────┘

  $ crs tools crs-ignore list-ignored-files
  File "$TESTCASE_ROOT/.crs-ignore", line 4, characters 0-8:
  4 | [invalid
      ^^^^^^^^
  Warning: Invalid glob pattern:
  [invalid
  README.md
  subdir/test_foo.ml
  vendor/bar.ml
  vendor/foo/foo.ml

The validation also implements warning for unused patterns, to make it easier to
cleanup stale entries in the ignore files. We also exercise here the support for
inline comments and proper location tracking in the presence of surrounding
whitespaces.

  $ printf "  foo # Hello inline comment \n" > .crs-ignore
  $ crs tools crs-ignore validate
  File "$TESTCASE_ROOT/.crs-ignore", line 1, characters 2-5:
  1 |   foo # Hello inline comment 
        ^^^
  Warning: This ignore pattern is unused.
  Hint: Remove it from this [.crs-ignore] file.

Note that the files are applied from the deepest path found, and walking up. In
practice this means that some entries may be shadowed by deeper ones.

  $ printf "subdir/test_foo.ml\n" > .crs-ignore
  $ crs tools crs-ignore validate
  File "$TESTCASE_ROOT/.crs-ignore", line 1, characters 0-18:
  1 | subdir/test_foo.ml
      ^^^^^^^^^^^^^^^^^^
  Warning: This ignore pattern is unused.
  Hint: Remove it from this [.crs-ignore] file.

However, if we were to select that file in isolation, there would be no warning
because there is an actual match.

  $ crs tools crs-ignore validate .crs-ignore

Clean up the invalid patterns:

  $ git reset --hard --quiet
  $ crs tools crs-ignore validate
