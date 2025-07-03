## 0.0.2025XXXX (unreleased)

### Added

- Add 's' for summary tables in emacs crs-grep-mode (#45, @mbarbin).

### Changed

- A breaking renaming in the terminology (kind => status) (#46, @mbarbin).
- Add buffer line header in emacs crs-grep-mode by default (#44, @mbarbin).

### Fixed

- Fix rendering of empty lines in multilines CRs with comment prefix (@mbarbin).

## 0.0.20250626 (2025-06-26)

### Added

- Add command to print summary of CRs annotations (#41, @mbarbin).
- Add support for CRs annotations and reviewdog diagnostics (#40, @mbarbin).
- Add key binding 'r' in emacs crs-grep-mode to refresh from repo-root (#34, @mbarbin).
- Show running directory and filters in emacs CRs messages (#34, @mbarbin).

### Changed

- `Cr_comment.reindented_content` now takes an optional prefix which default to none (#39, @mbarbin).
- A few breaking renaming changes in the terminology (#38, @mbarbin).

### Fixed

- Remove comment prefix from lines of reindented content (#35, @mbarbin).
- Fix handling of xargs exit code 123 (#33, @mbarbin).

## 0.0.20250620 (2025-06-20)

### Added

- Support for filtering CRs types in emacs crs-grep-mode (#31, @mbarbin).
- Add filtering flags to `crs grep` (`--soon`, `--xcrs`, etc.) (#30, @mbarbin).

### Changed

- Migrate from `Textutils.Ascii_table` to `PrintBox` to reduce dependencies (#28, @mbarbin).

### Removed

- No longer depend on `textutils` and transitively `core_unix` (#28, @mbarbin).

## 0.0.20250618 (2025-06-18)

### Added

- Continue to increase code coverage (#17, #25, @mbarbin).

### Changed

- Include locations in the output of `crs grep --sexp` (#24, @mbarbin).
- Reduce dependencies and replace `re2` by `ocaml-re` (#17, @mbarbin).
- Reduce dependencies and replace `shexp` by `spawn` (#16, @mbarbin).
- Make `crs grep` output in a pager when able (#16, @mbarbin).

### Fixed

- Fix position mismatch in tests shown by `ocaml-ci` (#23, @mbarbin).
- Disable failing build with 5.4 alpha release (#19, @mbarbin).
- Adapt grep implementation for portability to MacOS (#19, @mbarbin).

### Removed

- No longer depend on `re2` (#17, @mbarbin).
- No longer depend on `shexp` (#16, @mbarbin).

## 0.0.20250605 (2025-06-05)

### Added

- Add support for Mercurial repos in the CLI via `volgo-hg-unix` (#15, @mbarbin).

### Changed

- Update from `vcs` to `volgo` library (#14, @mbarbin).

## 0.0.20250515 (2025-05-15)

### Added

- Create a crs grep mode for Emacs to be shipped with the main opam pkg (#13, @mbarbin).
- Improve tests coverage (#8, #11, @mbarbin).
- New flag `crs grep --summary` to display information as summary tables (#8, @mbarbin).

### Changed

- Strip the ending of CR content (#11, @mbarbin).

### Fixed

- Fix reindentation when printing CRs (#11, @mbarbin).
- Dispose of `Shexp_process.Context` in crs parser (6a584f, @mbarbin).

### Removed

- Remove support for 'v' separator in CR comment (#11, @mbarbin).

## 0.0.20250414 (2025-04-14)

This very early draft release is intended for publication to my custom opam-repository. It allows for initial experimentation and ensures that the release cycle and distribution process are functioning correctly.

### Added

- Initialize documentation.
- Initialize project.
