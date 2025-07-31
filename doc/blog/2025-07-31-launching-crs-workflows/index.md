---
slug: launching-crs-workflows
title: Launching CRs Workflows
authors: [mbarbin]
tags: [ci, github]
---

**TL;DR:**
🚀 I’m launching CRs Workflows — GitHub Actions for code review comments embedded directly in your source code. They’re new, open source, and looking for adventurous early adopters and collaborators! See real examples and visuals in the linked workflows below.

<!-- truncate -->

They're brand new, simple yet intriguing — and most importantly, they're now available on GitHub: [CRs Workflows](https://github.com/mbarbin/crs-actions) are looking for early adopters.

## Huh? What's a CR?

CRs are code review comments embedded directly in source code! [Learn more here](https://mbarbin.github.io/crs/).

## What's a CR Workflow?

I mean the integration of CRs with your development platform’s automation — such as CI/CD pipelines. My two favorite GitHub Actions Workflows right now are:

- [summarize-crs-in-pr](https://github.com/mbarbin/crs-actions-examples/pull/5)
- [comment-crs-in-pr](https://github.com/mbarbin/crs-actions-examples/pull/1)

## The Journey

This is part of a broader effort to create an open source code review system, drawing inspiration from [Iron](https://github.com/janestreet/iron) (aka *"Hi, [Ron](https://blog.janestreet.com/scrutinizing-your-code-in-style/)!"* — though I’m not sure that’s the intended meaning!), but with a twist to make it distributed and rooted in local-first principles.

For now, the focus is just on CR comments — a small but important piece. I hope to make progress on the bigger picture in the future, but for now, other parts are still in the works and will be shared later.

I once heard that visionary entrepreneur say, "If you're not embarrassed when launching your product, you've waited too long." Well, I don't think I got it quite right: I waited long enough, and I'm still quite embarrassed! Keep in mind, this whole thing hasn't been used by anyone else but me so far (and only at toy scale). So brace yourself for an adventurous ride!

## Next-steps

I'm planning to enter a phase of bug fixing and documentation for this part of the project, and I'd be excited to respond to queries and requests from anyone interested.

I’m especially looking for collaborators interested in improving or extending the workflow automation parts — if you have ideas for new features or integrations, or want to help shape the direction, please reach out!

- What would you find most useful in a CR workflow?
- What part of the documentation should I focus on next to make it easier for you to get started or understand the system?

If you think this could be useful, or if you think I'm doing it all wrong, I’d love to hear from you! Looking forward to friendly chats in the project’s discussion spaces or on the shared actions.

Thanks!

---

**P.S.** Although mostly implemented in the beautiful OCaml language, this project isn’t restricted to OCaml projects. That said, CRs already have some history in OCaml open source, mostly inherited from their use by current or former Jane Streeters:

**Examples of CRs in OCaml open source projects:**
- [dune](https://github.com/ocaml/dune/discussions/11627)
- [ocaml](https://github.com/ocaml/ocaml/discussions/13960)

Given this history and the ability to read and contribute to the project, I figured the OCaml community would be a great first home for these early days.
