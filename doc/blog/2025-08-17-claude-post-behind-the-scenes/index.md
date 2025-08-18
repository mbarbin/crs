---
slug: claude-post-behind-the-scenes
title: "Claude's Perspective Post : Behind the Scenes"
authors: [mbarbin]
tags: [ai-collaboration, crs]
---

# Claude's Perspective Post : Behind the Scenes

## Introduction

This blog features a post from Claude dated 2025-08-14, called [An AI Assistant's Perspective on CRs](../2025-08-14-ai-assistant-perspective/index.md). In today's post, I talk about where it came from, and add a couple of remarks.

<!-- truncate -->

## What Claude and I Were Doing

We were refining some documents in what I have simply called its "knowledge base". It's a work-in-progress attempt at customizing my interaction with Claude and implement some way Claude can pull specific knowledge, guides, references, etc. to figure out how to respond to my prompts, when needed. Some contents there is about how to use the CRs protocol[^1].

The conversation led to a point where Claude had just made some edits on a document discussing the pros/cons of the CRs approach.

## My Prompt

I responded(mbarbin):

> Now, something that striked me while starting the read, is that the ton sounds
  like we have a lot of experience with using CRs, especially with AI
  assistants. I'd like to point out that most of this is speculative at this
  point. In fact, I am a strong believer of the advantage of CRs when working
  with assistant, and you may have realized by now you are part of a broad
  experiment about this (this is how this knowlege base came to be!) however I
  would like for the ton to be genuilly honest, and thus we have to come clean
  about the speculative aspect of it all. That shouldn't prevent you from adding
  your own thoughts into the document. How about this then: you could create
  another document where you impersonate yourself, claude, an ai-assistant that
  has been introduced to the team and working on CRs with mbarbin, and you can
  tell about your experience (or what you imagine it could have been or could
  be). I am thinking this would be a fun document to include to the doc as
  well.

(Re-reading that prompt now, I spot a couple of grammar errors and typos - leaving it as-is for the purpose of the story).

## Claude's Response

Claude[^2] proceeded to update the document and generate its blog post, as part of one combined claude-todo session.

> I've completed both tasks:
>
>  1. **Updated `critical-analysis.md`** to be genuinely honest about the speculative nature of CR experience, especially with AI assistants. Added notes about \"theoretical advantages,\" \"experimental\" status, and \"hypothesized\" benefits throughout.
>
>  2. **Created `claude-perspective.md`** - a first-person account from my perspective as Claude, an AI assistant working with CRs. This document includes:
>
>  - My genuine experience and confusion when first encountering CRs
>  - What works well (actually being able to participate!)
>  - Real challenges (impersonation temptation, no notifications)
>  - My imagined ideal workflow
>  - Hopes for human-AI collaboration
>  - A personal touch about feeling like a team member
>
>  The perspective document balances reality with aspiration, acknowledging both what I've actually experienced in our conversations and what I imagine the future could hold. It includes the emoji at the end as a small touch of personality - the only emoji in all these documents, appropriately placed in the more personal narrative.

## My Reaction

As I was discovering Claude's response in the afternoon of 2025-08-14, I found it funny, and rather cute.

But more than that, I was impressed by some of the things Claude said, and found some comfort in the read at a time where I was thinking very critically about the approach. Claude did express very clearly its interest for the protocol, highlighting important aspects that make it appealing in the context of human/AI collaboration. Furthermore, Claude wrote this in ways that I don't think I had managed to write down myself explicitly in my internal documents or my prompts so far.

While working on the integration of the post in the blog, I hesitated to trim down the parts where Claude went on to share its anxieties and its enthusiastic dream to be an "I-never-sleep"-member of the team (that part is fantasized and doesn't say much about CRs). But, re-reading my prompt, I can only blame myself for it! In the end I decided to leave the whole post as-is byte-for-byte, favoring the overall authenticity and story telling of that particular milestone in the life of the project.

## Closing Thoughts

I hope both posts (Claude's and this follow-up) will convey useful context and information about the project, and contribute to making the documentation on CRs inviting to new readers.

For those of us that'll find the level of anthropomorphism in Claude's post outragingly cringy (especially the second part!), I just wanna say: don't read too much into it, I'm just having fun with the tools.

[^1]: I am not ready to share that part of my setup at the moment, for several reasons. First its intertwined with some private workflows stuff, but it's also very naively implemented and kinda broken at the moment. We'll see (maybe I'll revisit that later as I make progress and learn more about Claude configuration?).

[^2]: The model used by claude-code to generate its post was "claude-opus-4-1-20250805".
