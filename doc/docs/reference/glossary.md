# Glossary

## Core Terms

**CR**: A code review comment embedded in source code. The abbreviation stands for "Code Review" or "Change Request". The 's' in "CRs" simply indicates the plural form (several such comments). CRs are temporary comments that capture actionable feedback during code review.

**XCR**: A resolved code review comment. The 'X' prefix indicates the CR has been addressed but remains in the code pending acknowledgment from the reporter.

**crs**: The command-line tool for managing CRs. Written in lowercase, `crs` is the CLI that helps locate, parse, and manipulate CR comments embedded in source code.

## Components of a CR

**Reporter**: The person who creates a CR comment (e.g., `alice` in `CR alice: Fix this`).

**Recipient**: An optional explicit assignee for a CR (e.g., `bob` in `CR alice for bob: Please update`). When omitted, the CR is implicitly assigned to the change owner.

**Header**: The structured metadata line of a CR that includes status, reporter, optional recipient, and optional qualifier.

**Content**: The actual text of the CR comment, including the header and excluding comment markers.

**Status**: Indicates whether a CR is resolved or unresolved:
- `CR`: Unresolved comment requiring action
- `XCR`: Resolved comment awaiting acknowledgment

**Qualifier**: Optional indication for when a CR should be addressed:
- No qualifier: Should be addressed now
- `soon`: Should be addressed soon (e.g., `CR-soon`)
- `someday`: Can be addressed in the future (e.g., `CR-someday`)

## Configuration

**crs-config.json**: The configuration file for `crs` in GitHub Actions workflows. Located at `.github/crs-config.json` in the repository root.

**Annotation**: A GitHub UI element that highlights issues directly in pull requests. The `crs` tool can create annotations for invalid CRs or CRs due for resolution.

## Workflow terms

**Change Owner**: The person responsible for implementing changes in a branch or pull request. CRs without explicit recipients are assigned to the change owner by default.

## File and Location Terms

**Path in Repo**: The file path relative to the repository root where a CR is located.

## Related Tools

**Reviewdog**: A third party tool used by some CRs Actions to post CRs as GitHub pull request comments.
