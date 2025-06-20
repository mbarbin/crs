# Contributing to crs-grep Emacs Mode

Thank you for your interest in improving the `crs-grep` Emacs integration!

## Guidelines

- Some useful resources for Emacs Lisp:
  - [GNU Emacs Lisp Coding Conventions](https://www.gnu.org/software/emacs/manual/html_node/elisp/Coding-Conventions.html)
  - [Writing GNU Emacs Extensions](https://www.gnu.org/software/emacs/manual/html_node/eintr/index.html)
  - [EmacsWiki: Elisp Style Guide](https://www.emacswiki.org/emacs/ElispStyleGuide)

## Linting with eldev

Some useful [eldev](https://github.com/doublep/eldev) commands for development:

- **Lint the code:**
```sh
$ eldev lint
```

```sh
$ eldev doctor
```

## Formatting

We use the `elisp-autofmt` package to automatically format the Emacs Lisp files.

From within emacs, run:

```sh
(elisp-autofmt-buffer) ; Auto-format the current buffer.
```

---

For any questions or suggestions, please open an issue or pull request. Happy hacking!
