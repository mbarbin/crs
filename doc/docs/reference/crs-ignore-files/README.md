# CRs Ignore Files

This document provides a reference for the `.crs-ignore` configuration files used by the `crs` executable and libraries to exclude files when searching for CRs in the tree.

> For guidance on when and why to use `.crs-ignore` files, see [When to Use .crs-ignore Files](../../explanation/when-to-use-crs-ignore-files.md).

## Quick Example

Here's an example `.crs-ignore` file:

```
# Our README illustrates how to use CRs
README.md
vendor/** # The vendor/ code has CRs that we don't review
```

## Configuration Files Locations

The `.crs-ignore` files can be located anywhere in the tree. The patterns they contain must be relative to the location of the file itself.

To be effective, the `.crs-ignore` files must be tracked by your vcs. Untracked files won't have any effect, even if they have the expected name.

## File Format

The `.crs-ignore` file format supports:

- **Comments**: Lines starting with `#` are comments and are ignored
- **Inline comments**: Patterns can have trailing comments after `#`
- **Blank lines**: Empty lines are ignored
- **Shell-style glob patterns**: The main content for matching files. One pattern per line expected.

## Supported Patterns

All patterns use shell-style glob syntax. Here are common pattern examples:

| Pattern | Description |
|---------|-------------|
| `README.md` | Exact filename match |
| `*.tmp` | Files with specific extension |
| `test_*.ml` | Files with specific prefix |
| `*_test.py` | Files with specific suffix |
| `vendor/**` | Directory and all contents recursively |
| `build/*` | Direct contents of a directory (not recursive) |

### Pattern Matching Rules

- All patterns are relative to the directory containing the `.crs-ignore` file
- When checking if a file should be ignored, the system walks up from the file's directory to the repository root
- The first matching pattern encountered determines whether the file is ignored
- Deeper `.crs-ignore` files take precedence over ones higher in the directory tree

## Available Commands

The `crs tools crs-ignore` command provides several utilities to work with your ignore configuration:

- `list-ignored-files` - Shows all files that are currently ignored
- `list-included-files` - Shows all files that are included (not ignored)
- `validate` - Validates your `.crs-ignore` files for errors and warnings

## Validation

The `validate` command helps maintain clean and correct `.crs-ignore` configuration:

### Invalid Pattern Detection

Invalid glob patterns will be reported as errors:

```
File ".crs-ignore", line 2, characters 0-8:
2 | [invalid
    ^^^^^^^^
Error: Invalid glob pattern:
[invalid
```

### Unused Pattern Warnings

Patterns that are unused will trigger warnings. This happens when they match no files in your repository, or when they are made redundant by patterns in deeper `.crs-ignore` files that take precedence:

```
File ".crs-ignore", line 1, characters 2-22:
1 |   nonexistent_file.txt # This pattern matches no files
      ^^^^^^^^^^^^^^^^^^^^
Warning: This ignore pattern is unused.
Hint: Remove it from this [.crs-ignore] file.
```

