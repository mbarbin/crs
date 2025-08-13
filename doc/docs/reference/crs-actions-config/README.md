# CRs Actions Config

This document provides a complete reference for the `crs-config.json` configuration file used by CRs Actions in GitHub Actions workflows.

## Configuration File Location

The configuration file should be placed at `.github/crs-config.json` in your repository root.

## Configuration Schema

The file uses JSON5 format, which supports comments and trailing commas.

### Complete Example

<!-- $MDX file=complete-example.json -->
```json
{
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

You can validate a configuration file using the *crs* cli like this:

```bash
$ crs tools config validate complete-example.json
```

The command silently exit 0 when the config is valid, or otherwise complains on *stderr* and a non zero exit code (examples below).

## Fields Reference

### `default_repo_owner`

- **Type:** `string` (optional)
- **Example:** `"alice"`

When not in a pull request context, this username may be used to assign certain kinds of CRs that are otherwise not easy to assign to a particular user. For example, invalid CRs when creating CR annotations for a particular commit outside of a pull request.

If the repository is owned by an individual, this would typically be that user. If the repository is owned by an organization, this may be set to a specific user who would be assigned otherwise unassignable CRs. If it isn't set, such CRs will simply not be assigned to anyone in particular.

### `user_mentions_allowlist`

- **Type:** `array of strings` (optional)
- **Example:** `["alice", "bob", "charlie"]`
- **Default** same as supplying an empty array (no user enabled).

Enables a specific list of users to be notified in annotation comments when notifications are requested. This is a protection measure to avoid spamming users that do not have ties to a repository in particular, or simply do not wish to be notified via CRs.

When specified, only users in this allowlist can be mentioned in CR annotations. This helps prevent typos in usernames and ensures CRs are only assigned to valid team members.

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

## GitHub Annotation Severity Levels

The severity levels map to GitHub's annotation levels. See [GitHub's documentation on annotation levels](https://docs.github.com/en/actions/using-workflows/workflow-commands-for-github-actions#setting-an-error-message) for details on how these are displayed in the UI.

- **Error**: Most prominent display, typically for critical issues
- **Warning**: Medium prominence, suitable for issues that should be addressed (default for `invalid_crs_annotation_severity`)
- **Info**: Informational notice messages (default for `crs_due_now_annotation_severity`)

## Validation

The `crs` CLI provides a validation command to check your configuration files. The validation checks:
- JSON syntax correctness
- Required fields presence
- Value type correctness
- Enum values validity

### Basic Validation

To validate your configuration file:

<!-- $MDX skip -->
```bash
crs tools config validate .github/crs-config.json
```

### Validation Examples

#### Valid Minimal Configuration

At the moment all fields in the config are optional, so an empty json object is a minimal valid configuration:

<!-- $MDX file=valid-minimal.json -->
```json
{}
```

```bash
$ crs tools config validate valid-minimal.json
```

#### Valid Full Configuration

A complete configuration with all optional fields, in regular json:

<!-- $MDX file=valid-full.json -->
```json
{
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

#### Configuration with Selected Fields Only

Since all fields are optional, you can have a configuration with just specific fields:

<!-- $MDX file=minimal-with-allowlist.json -->
```json
{
  "user_mentions_allowlist": ["alice", "bob"]
}
```

```bash
$ crs tools config validate minimal-with-allowlist.json
```

### Invalid Config Examples

#### Warning: Use of wrapped enum

Enum values used to be wrapped in the config format. This is still supported for compatibility but now this creates a warning:

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

#### Invalid: Wrong Type for Field

Configuration with incorrect type for `user_mentions_allowlist`:

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
list_of_yojson: list needed
[123]
```

#### Invalid: Bad Severity Value

Configuration with invalid annotation severity:

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
