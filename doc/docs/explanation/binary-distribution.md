# Binary Distribution

This document explains the design decisions behind how crs binaries are distributed through GitHub releases.

## Why Pre-compiled Binaries?

We provide pre-compiled binaries primarily to support GitHub Actions CRs workflows. While OCaml developers can install crs through opam, GitHub Actions workflows benefit from:

1. **Fast installation**: Downloading a pre-compiled binary takes seconds versus minutes for compilation
2. **No build dependencies**: No need to set up OCaml, opam, or dune in CI environments
3. **Consistency across runs**: The same binary is reused across multiple workflow runs and steps

## Build Provenance vs Binary Signing

We currently use GitHub's built-in build attestation feature rather than traditional binary signing. Our reasoning:

### GitHub Build Attestation

GitHub's build provenance feature provides cryptographic proof that binaries were:
- Built by GitHub Actions (not uploaded manually)
- Built from specific source code commits
- Built using transparent, auditable workflows

For our use case, this approach seemed practical:

1. **No key management burden**: We don't need to manage signing keys or certificates
2. **Transparent build process**: The workflow that produces binaries is public and auditable
3. **Native GitHub integration**: Verification uses the `gh` CLI that's pre-installed in GitHub Actions and widely available for local development

### Why Not Traditional Signing?

Traditional signing approaches are certainly valid and widely used. For our use case—binaries primarily consumed by GitHub Actions workflows—build attestation provides auditable proof of how binaries were built, which can be a desirable property when downloading and running binaries in CI environments.

We acknowledge that this approach may not satisfy the security requirements of all projects, and that's perfectly fine. Different projects have different needs. If you have thoughts on this approach, we're open to discussion! Feel free to open an issue to share your perspective.

## Unstripped Binaries

Our binaries are currently not stripped. We haven't thoroughly evaluated the actual impact of stripping on OCaml binaries' error reporting, backtraces, or ability to use debugging tools like the OCaml debugger, so we've defaulted to keeping them unstripped for now. The trade-off is larger file sizes versus potentially better debugging capabilities. If you have specific knowledge about the impact of stripping on OCaml binaries, we'd welcome your input on this decision.

## Architecture Support

We chose to support architectures based on GitHub Actions usage patterns: Linux x86_64 (the default for GitHub-hosted runners) and macOS ARM64 (supporting modern Apple development machines). These also cover the most common development environments, while less common setups can use the opam installation method. See the [installation guide](../guides/installation/pre-compiled-binaries.md#available-architectures) for the current list of supported architectures. If you need support for other architectures, please let us know!

## Related Documentation

- [Pre-compiled Binaries Guide](../guides/installation/pre-compiled-binaries.md) - How to download and verify binaries
- [Setup crs for GitHub Actions](../guides/installation/setup-crs-for-github-actions.md) - Using binaries in CI
- [Installation Guide](../guides/installation/README.md) - All installation methods
