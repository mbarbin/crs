# crs

[![CI Status](https://github.com/mbarbin/crs/workflows/ci/badge.svg)](https://github.com/mbarbin/crs/actions/workflows/ci.yml)
[![Coverage Status](https://coveralls.io/repos/github/mbarbin/crs/badge.svg?branch=main)](https://coveralls.io/github/mbarbin/crs?branch=main)
[![Deploy Doc Status](https://github.com/mbarbin/crs/workflows/deploy-doc/badge.svg)](https://github.com/mbarbin/crs/actions/workflows/deploy-doc.yml)
[![OCaml-CI Build Status](https://img.shields.io/endpoint?url=https://ocaml.ci.dev/badge/mbarbin/crs/main&logo=ocaml)](https://ocaml.ci.dev/github/mbarbin/crs)

## Introduction

Welcome to **crs**, a project that provides libraries and a command-line interface to help manage code review comments embedded directly in source code using a specialized syntax.

### A Quick Example of a Code Review Comment (CR)

Code review comments, or **CRs** (pronounced "C"-"R"-z), are a way to embed actionable feedback directly into source code. A CR starts with the letters `CR`, followed by the name of the reporting user, a colon, and the comment text. For example, here’s a CR left by *alice*:

```txt
CR alice: Add a quick example of a CR comment in the project's home page!
```

CRs can also be assigned to a specific user. To do this, include the `for` keyword followed by the assignee's name. For example:

```txt
CR alice for bob: Add a quick example of a CR comment in the project's home page!
```

Once the assignee, *bob*, addresses the comment, it can be marked as resolved by converting it into an `XCR` (resolved CR). Typically, a resolution note is added as part of the update:

```txt
XCR alice for bob: Add a quick example of a CR comment in the project's home page!

bob: Great idea! Done - see my changes to `README.md`.
```

After the CR is resolved, it’s reassigned back to the original reporter, *alice*, who can decide whether to remove the comment entirely or revert it back to a CR to continue the discussion.

This simple syntax makes it easy to track, assign, and resolve code review comments directly within your codebase.

CRs are embedded into the source code using the comment syntax of the language in which they appear. For example, in OCaml, a complete CR would look like this:

```ocaml
(* CR alice: Add a quick example of a CR comment in the project's home page! *)
```

## Project Goals

The primary goal of **crs** is to make it easy to locate, parse, and manipulate these comments. It offers ergonomic tools for tasks such as systematically updating comments across multiple files, changing their priority, marking them as resolved, modifying reporter or assignee information, and more.

This tool is designed to be flexible and can be used during development or integrated into your CI pipeline. For example, you can use **crs** to ensure no unresolved comments remain before merging a pull request or releasing a new version of your software.

Beyond its standalone functionality, **crs** is intended to serve as a sharable building block for more comprehensive code review systems and collaborative workflows.

## Documentation

Published [here](https://mbarbin.github.io/crs).

## Current State

:construction: *crs* is currently under construction and should be considered experimental and unstable. During the early `0.0.X` stages of development, the interfaces and behavior are subject to breaking changes. Feedback from adventurous users is welcome to help shape future versions.

## Get Involved

If you're interested in this project and would like to engage in discussions or provide feedback, please feel free to open an issue or start a discussion in the GitHub space of the project.

Thank you for your interest in crs!

## Acknowledgements

### Iron and Jane Street

We would like to express our gratitude to **Jane Street** for releasing their internal code review system, [Iron](https://github.com/janestreet/iron), as open source in 2016-2017. *Iron* introduced an innovative approach to embedding code review comments directly into source code, which has inspired the development of the *crs* project.

The *crs* project builds upon ideas from *Iron*, particularly its syntax for embedded code review comments. Our work is based on an older version of *Iron* (`v0.9.114.44+47`, revision `dfb106cb82abf5d16e548d4ee4f419d0994d3644`), and we have adapted this concept to suit a potentially broad range of use cases and audiences.

In addition to drawing inspiration from *Iron*, we have been able to re-use some of the code released with *Iron* as a starting point for the *crs* project, in accordance with the terms of the [Apache 2.0 License](http://www.apache.org/licenses/LICENSE-2.0). This provided a valuable boost to get started, and we are thankful for the value this contribution has brought to our work.

It is also important to note that *crs* and *Iron* are independent projects with no specific ties. *Iron* may have evolved significantly since the version we referenced, and we make no guarantees or claims about its current state or future direction. On the other hand, *crs* is designed to expand on foundational ideas from *Iron* to make them accessible and usable in a wide variety of contexts, beyond the scope of the original project.

We deeply appreciate Jane Street’s contribution to the open source community and their willingness to share *Iron*, which has provided a valuable starting point for exploring and advancing these ideas.

### Other

- We would like to acknowledge the [Diátaxis framework](https://diataxis.fr/) for technical documentation, which we use as inspiration to structure our doc.
