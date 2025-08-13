# Setup crs for GitHub Actions

When working with GitHub Actions workflows, the recommended way to install crs is using the `setup-crs` action from the [crs-actions](https://github.com/mbarbin/crs-actions) repository.

## Using setup-crs Action

The `setup-crs` action downloads and installs the crs binary from a GitHub release, making it available for subsequent workflow steps.

### Basic Usage

```yaml
- uses: mbarbin/crs-actions/setup-crs@v1.0.0
  with:
    crs-version: 0.0.20250705
```

### Features

- **Optimized for ubuntu-latest**: The action is designed and tested primarily with `ubuntu-latest` runners
- **Build attestation**: Verifies the build attestation when `gh` CLI is available
- **PATH integration**: Installs to a temporary directory and updates the `PATH` automatically

## Version Management

The `crs-version` input is mandatory and requires an exact version number (e.g., `0.0.20250705`). This ensures reproducible builds across all workflow runs.

Each version of the setup-crs action is tested for compatibility with specific crs versions. Check the [crs releases page](https://github.com/mbarbin/crs/releases) to see all available versions, and consult the [compatibility table in the crs-actions repository](https://github.com/mbarbin/crs-actions#compatibility) before upgrading to ensure your action and crs versions are compatible.

**Best practice**: Test crs version upgrades in separate pull requests to isolate any potential issues.

## Example Workflow

Here's a simple example that installs crs and verifies the installation:

<!-- $MDX skip -->
```yaml
name: Setup crs
on:
  push:
    branches: [main]
  pull_request:

jobs:
  setup:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: mbarbin/crs-actions/setup-crs@v1.0.0
        with:
          crs-version: 0.0.20250705

      - name: Verify crs installation
        run: crs --version
```

For complete workflow examples that demonstrate how to use crs with actual GitHub Actions, visit:
- [crs-actions repository](https://github.com/mbarbin/crs-actions) - Documentation for all available actions
- [crs-actions-examples](https://github.com/mbarbin/crs-actions-examples) - Live examples demonstrating available actions in real scenarios

## Troubleshooting

### Common Issues

**Binary not found**: Ensure the setup-crs action completes successfully before using crs commands.

**Version mismatch**: If you encounter CLI flag errors, verify that your action version is compatible with your specified crs version.

**Permission issues**: Some actions require write permissions. Ensure your workflow has appropriate permissions:

```yaml
permissions:
  contents: read
  pull-requests: write
  checks: write
```

## Further Resources

- [crs-actions repository](https://github.com/mbarbin/crs-actions)
- [crs-actions-examples](https://github.com/mbarbin/crs-actions-examples)
- [reviewdog](https://github.com/reviewdog/reviewdog) - Third party tool used by several crs actions
