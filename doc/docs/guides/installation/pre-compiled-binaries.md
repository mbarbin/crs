# Pre-compiled Binaries

Pre-compiled binaries are available from the [crs releases page](https://github.com/mbarbin/crs/releases).

## Available Architectures

- Linux x86_64
- macOS ARM64

:::info
 If your architecture is not listed, you'll need to use the [opam installation method](./README.md#from-the-public-opam-repository) or [build from source](./README.md#build-from-sources).
:::

## Installation

Download the binary for your platform from the releases page, rename it to `crs`, make it executable, and place it in your PATH.

## Verifying Build Provenance

You can verify that binaries were built from the official source using GitHub's build attestation. This requires gh CLI (see https://cli.github.com/):

<!-- $MDX skip -->
```bash
gh attestation verify crs-0.0.20250705-linux-x86_64 \
  --owner mbarbin \
  --signer-repo mbarbin/crs
```

This confirms the binary was built by GitHub Actions from the official crs repository.

## Troubleshooting

### macOS Security Warning

macOS may warn that the binary is from an "unidentified developer" because it's not notarized by Apple.

To allow the binary:
- **System Settings**: Go to Privacy & Security, click "Allow Anyway" for crs
- **Command line**: Run `xattr -d com.apple.quarantine crs`
- **Finder**: Right-click the binary, select "Open", then click "Open" in the dialog

:::info
Only bypass these warnings after verifying the binary's provenance.
:::

## See Also

- [Binary Distribution](../../explanation/binary-distribution.md) - Design decisions behind our crs binaries distribution
- [Setup crs for GitHub Actions](./setup-crs-for-github-actions.md)
