In this test we monitor the use case of a repo that is running CR workflows and
in particular what happens when the PR is opened by the dependabot workflow.

First we need to setup a repo in a way that satisfies the test environment. This
includes specifics required by the GitHub Actions environment.

  $ volgo-vcs init -q .
  $ volgo-vcs set-user-config --user.name "Test User" --user.email "test@example.com"

To make sure the CRs are not mistaken for actual CR comments in this
file, we make use of some tricks.

  $ export CR="CR"
  $ export XCR="XCR"

Let's add some files to the tree.

  $ cat > hello << EOF
  > Hello World
  > EOF

  $ cat hello
  Hello World

  $ volgo-vcs add hello
  $ rev0=$(volgo-vcs commit -m "Initial commit")

Making sure the branch name is deterministic.

  $ volgo-vcs rename-current-branch main

Now let's add some CRs.

  $ printf "(* $CR user1: There is an issue with the deps. *)\n" >> hello

  $ volgo-vcs add hello
  $ rev1=$(volgo-vcs commit -m "CRs")

Annotating the CRs works as expected:

  $ crs tools github annotate-crs
  ::notice file=hello,line=2,col=1,endLine=2,endColumn=49,title=CR::This CR is unassigned (no default repo owner configured).

When the workflow is run in PRs opened by the dependabot workflow, the name of
the PR author is supplied by the workflow job as follows:

  $ crs tools github annotate-crs \
  >   --review-mode=pull-request \
  >   --pull-request-author="dependabot[bot]" > output 2>&1
  [124]

  $ grep 'crs: ' output
  crs: option '--pull-request-author': "dependabot[bot]": invalid user_handle

As seen above, this type of user handle is not supported at the moment. This
limitation is monitored by this test, with improvements left as future work.

See also: [https://github.com/mbarbin/crs/issues/82].
