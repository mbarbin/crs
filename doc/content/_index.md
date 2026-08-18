+++
title = "A tool for managing inline review comments embedded in source code"
template = "index.html"
sort_by = "weight"
+++

Welcome to **crs**, a project that provides libraries and a command-line
interface to help manage inline review comments embedded directly in source
code using a specialized syntax.

The primary goal of **crs** is to make it easy to locate, parse, and
manipulate these comments. It offers ergonomic tools for tasks such as
systematically updating comments across multiple files, changing their
priority, marking them as resolved, modifying reporter or assignee
information, and more.

This tool is designed to be flexible and can be used during development or
integrated into your CI pipeline. For example, you can use **crs** to ensure
no unresolved comments remain before merging a pull request or releasing a
new version of your software.

Beyond its standalone functionality, **crs** is intended to serve as a
sharable building block for more comprehensive code review systems and
collaborative workflows.
