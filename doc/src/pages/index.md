<h1 align="center">
  <p align="center">A Tool for Managing Inline Review Comments Embedded in Source Code</p>
</h1>

<p align="center">
  <a href="https://github.com/mbarbin/crs/actions/workflows/ci.yml"><img src="https://github.com/mbarbin/crs/workflows/ci/badge.svg" alt="CI Status"/></a>
  <a href="https://coveralls.io/github/mbarbin/crs?branch=main"><img src="https://coveralls.io/repos/github/mbarbin/crs/badge.svg?branch=main" alt="Coverage Status"/></a>
  <a href="https://github.com/mbarbin/crs/actions/workflows/deploy-doc.yml"><img src="https://github.com/mbarbin/crs/workflows/deploy-doc/badge.svg" alt="Deploy Doc Status"/></a>
</p>

Welcome to **crs**, a project that provides libraries and a command-line interface to help manage inline review comments embedded directly in source code using a specialized syntax.

The primary goal of **crs** is to make it easy to locate, parse, and manipulate these comments. It offers ergonomic tools for tasks such as systematically updating comments across multiple files, changing their priority, marking them as resolved, modifying reporter or assignee information, and more.

This tool is designed to be flexible and can be used during development or integrated into your CI pipeline. For example, you can use **crs** to ensure no unresolved comments remain before merging a pull request or releasing a new version of your software.

Beyond its standalone functionality, **crs** is intended to serve as a sharable building block for more comprehensive code review systems and collaborative workflows.
