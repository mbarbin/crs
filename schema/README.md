# CRs Configuration Schema

**Audience:** This document is for CRs maintainers and contributors. For user-facing documentation about using the schema, see [doc/docs/reference/crs-actions-config/README.md](../doc/docs/reference/crs-actions-config/README.md).

## Overview

This directory contains the JSON Schema for the CRs configuration file format (`crs-config.schema.json`).

## Distribution Mechanism

The schema is distributed through two channels:

1. **GitHub releases** (primary) - `.github/workflows/release-artifacts.yml` extracts the schema from the opam destdir and uploads it as a release artifact
   - Schema is retrieved from `$OPAM_DESTDIR/share/crs/schema/crs-config.schema.json`
   - Uploaded alongside platform-specific binaries
   - Accessed via versioned URLs like `https://github.com/mbarbin/crs/releases/download/v1.2.3/crs-config.schema.json`
   - This is the primary distribution mechanism that users reference in their configs

2. **Opam installation** (secondary, for offline use if needed) - `schema/dune` installs the file to `share_root` under `crs/schema/`
   - Path in switch: `<opam-prefix>/share/crs/schema/crs-config.schema.json`
   - Available locally for offline validation or tooling that needs direct file access
   - Note: Editors cache schemas after first fetch, so the GitHub release URL works offline once cached

## Version Substitution

The schema uses the `%%VERSION%%` placeholder in the `$id` field to reference the GitHub release URL:

```json
"$id": "https://github.com/mbarbin/crs/releases/download/%%VERSION%%/crs-config.schema.json"
```

This placeholder is automatically substituted during opam installation using opam's built-in variable substitution mechanism, ensuring the schema's `$id` matches the actual release version.

## Maintenance

When adding new configuration fields:

1. Update `crs-config.schema.json` with the new field definition
2. Ensure the schema validates against example configs in `doc/docs/reference/crs-actions-config/`
3. Update user-facing documentation in `doc/docs/reference/crs-actions-config/README.md`
4. Consider whether automatic integration with OCaml types would be beneficial (future work)
