---
slug: introducing-crs
title: Introducing crs
authors: [mbarbin]
tags: [ci]
---

[Iron](https://github.com/janestreet/iron), a code review system developed by Jane Street, supports embedding code review annotations directly into source code using special comments called "CRs."

Inspired by this concept, I decided to build a standalone and lightweight tool for managing CRs embedded in source code. I've started [this project](https://github.com/mbarbin/crs), which primarily consists of libraries and a command-line interface named *crs* (the name checks out!).

<!-- truncate -->

As part of my own coding workflow, I often write CRs, even when working solo — similar to leaving "TODO" markers for yourself.

```text
CR mbarbin: Write a short post introducing the project.
```

So far, this has been my primary use case for the tool. I envision that beyond its standalone functionality, *crs* could serve as a sharable building block for more comprehensive review systems and collaborative workflows.

This is work in progress. If you think you might find it useful, your insights and suggestions would be very welcome as I am developing this tool.

Thanks for your interest!
