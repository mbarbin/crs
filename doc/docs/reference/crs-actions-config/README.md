# CRs Actions Config

This document provides a complete reference for the `crs-config.json` configuration file used by CRs Actions in GitHub Actions workflows.

## Overview

The configuration file should be placed at `.github/crs-config.json` in your repository root. The file uses JSON5 format, which supports comments and trailing commas.

## Quick Start

Here's a complete working example showing all available configuration options:

<!-- $MDX file=complete-example.json -->
```json
{
  // Enable editor validation and auto-completion (replace with your crs version).
  "$schema": "https://github.com/mbarbin/crs/releases/download/0.0.20251014/crs-config.schema.json",

  // Alice takes over CRs that are otherwise hard to assign.
  default_repo_owner: "alice",

  // The list of users who have elected to being notified via GitHub
  // through the use of `@ + username` mentions in comments.
  user_mentions_allowlist: [
    "alice",
    "bob",
    "charlie",
  ],

  // Configuration for the severity used in GitHub Annotations.
  invalid_crs_annotation_severity: "Warning",
  crs_due_now_annotation_severity: "Info",
}
```

Replace `v1.2.3` with your installed `crs` version (check with `crs --version`). The `$schema` field enables editor validation and auto-completion features (see [Validation](#validation) section below).

## Configuration Reference

### `default_repo_owner`

- **Type:** `string` (optional)
- **Example:** `"alice"`

When not in a pull request context, this username may be used to assign certain kinds of CRs that are otherwise not easy to assign to a particular user. For example, invalid CRs when creating CR annotations for a particular commit outside of a pull request.

If the repository is owned by an individual, this would typically be that user. If the repository is owned by an organization, this may be set to a specific user who would be assigned otherwise unassignable CRs. If it isn't set, such CRs will simply not be assigned to anyone in particular.

### `user_mentions_allowlist`

- **Type:** `array of strings` (optional)
- **Example:** `["alice", "bob", "charlie"]`
- **Default:** `[]` (empty array - no mentions allowed)

List of users who can be mentioned in CR annotations using `@username` mentions. Only users explicitly listed here can be notified through GitHub mentions.

If this field is not provided, it defaults to an empty list, meaning no user mentions are allowed. This is a protection measure to avoid spamming users who do not have ties to the repository or do not wish to be notified via CRs.

Adding users to this list enables notifications for them and helps prevent typos in usernames by restricting mentions to known team members.

### `invalid_crs_annotation_severity`

- **Type:** `string` (optional)
- **Valid values:** `"Error"`, `"Warning"`, `"Info"`
- **Default:** `"Warning"`

Controls the GitHub annotation severity level for invalid CR syntax. This determines how prominently invalid CRs are displayed in GitHub's UI.

### `crs_due_now_annotation_severity`

- **Type:** `string` (optional)
- **Valid values:** `"Error"`, `"Warning"`, `"Info"`
- **Default:** `"Info"`

Controls the GitHub annotation severity level for CRs that are due now (such as in the PR where they were found).

#### About Annotation Severity Levels

The severity levels map to GitHub's annotation levels (see [GitHub's documentation](https://docs.github.com/en/actions/using-workflows/workflow-commands-for-github-actions#setting-an-error-message) for details):

- **Error**: Most prominent display, typically for critical issues
- **Warning**: Medium prominence, suitable for issues that should be addressed
- **Info**: Informational notice messages

## Validation

Configuration files can be validated in two ways: real-time validation in your editor using JSON Schema, or batch validation using the `crs` CLI command.

### Editor Validation with JSON Schema

CRs provides a JSON Schema that enables real-time validation and editor features like auto-completion, inline validation, and hover documentation.

#### Enabling Schema Validation

Add a `$schema` field to your `.github/crs-config.json` that matches your installed `crs` version:

<!-- $MDX skip -->
```json
{
  "$schema": "https://github.com/mbarbin/crs/releases/download/0.0.20251014/crs-config.schema.json",
  "default_repo_owner": "alice",
  "user_mentions_allowlist": ["alice", "bob"]
}
```

Replace `v1.2.3` with your installed `crs` version. Check your version with:

<!-- $MDX skip -->
```bash
$ crs --version
```

**Important:** When you upgrade `crs`, update the version in the `$schema` URL to match. Editors cache schemas, so using `latest` can cause validation issues when the cached schema doesn't match your installed version.

#### Editor Features

Once the `$schema` field is added, editors like VS Code will:

- **Validate** - Show red squiggles for invalid values or unknown fields
- **Auto-complete** - Press Ctrl+Space to see available fields and enum values
- **Hover documentation** - Hover over fields to see their descriptions and valid values
- **Inline hints** - Get suggestions for default values

**Note:** Editors cache the schema locally after the first fetch, so schema validation works offline once cached.

### Command-Line Validation

The `crs` CLI provides a validation command to check your configuration files. The validation checks:
- JSON syntax correctness
- Required fields presence
- Value type correctness
- Enum values validity

#### Basic Validation

To validate your configuration file:

<!-- $MDX skip -->
```bash
crs tools config validate .github/crs-config.json
```

#### Validation Examples

**Valid Minimal Configuration** - At the moment all fields in the config are optional, so an empty json object is a minimal valid configuration:

<!-- $MDX file=valid-minimal.json -->
```json
{}
```

```bash
$ crs tools config validate valid-minimal.json
```

**Valid Full Configuration** - A complete configuration with all optional fields, in regular json:

<!-- $MDX file=valid-full.json -->
```json
{
  "$schema": "https://github.com/mbarbin/crs/releases/download/0.0.20251014/crs-config.schema.json",
  "default_repo_owner": "alice",
  "user_mentions_allowlist": [
    "alice",
    "bob",
    "charlie"
  ],
  "invalid_crs_annotation_severity": "Warning",
  "crs_due_now_annotation_severity": "Info"
}
```

```bash
$ crs tools config validate valid-full.json
```

**Configuration with Selected Fields Only** - Since all fields are optional, you can have a configuration with just specific fields:

<!-- $MDX file=minimal-with-allowlist.json -->
```json
{
  "user_mentions_allowlist": ["alice", "bob"]
}
```

```bash
$ crs tools config validate minimal-with-allowlist.json
```

**Warning: Use of wrapped enum** - Enum values used to be wrapped in the config format. This is still supported for compatibility but now this creates a warning:

<!-- $MDX file=wrapped-enum.json -->
```json
{
  "invalid_crs_annotation_severity": [ "Warning" ]
}
```

```bash
$ crs tools config validate wrapped-enum.json
File "wrapped-enum.json", line 1, characters 0-0:
Warning: The config field name [invalid_crs_annotation_severity] is now
expected to be a json string rather than a list.
Hint: Change it to simply: "Warning"
```

**Invalid: Wrong Type for Field** - Configuration with incorrect type for `user_mentions_allowlist`:

<!-- $MDX file=invalid-wrong-type.json -->
```json
{
  "default_repo_owner": "alice",
  "user_mentions_allowlist": "bob"
}
```

```bash
$ crs tools config validate invalid-wrong-type.json
File "invalid-wrong-type.json", line 1, characters 0-0:
Error: Invalid config.
In: "bob"
User handle list expected to be a list of json strings.
[123]
```

**Invalid: Bad Severity Value** - Configuration with invalid annotation severity:

<!-- $MDX file=invalid-severity.json -->
```json
{
  "default_repo_owner": "alice",
  "invalid_crs_annotation_severity": "Notice"
}
```

```bash
$ crs tools config validate invalid-severity.json
File "invalid-severity.json", line 1, characters 0-0:
Error: Field [invalid_crs_annotation_severity]:
Unsupported annotation severity "Notice".
[123]
```

## Migration Notes

When upgrading crs versions, check the release notes for any changes to the configuration schema, and make sure to validate your config with the new binary. New fields are typically optional and have sensible defaults to maintain backward compatibility.

### Detecting Deprecated Constructs

CRs Actions automatically generates GitHub Annotation warnings when it encounters deprecated configuration patterns in the config. Check your GitHub Actions Summary page after upgrading to identify any configs that need updating — these warnings help catch issues missed during migration or validation.
