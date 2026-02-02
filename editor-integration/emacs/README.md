# crs-grep

`crs-grep` is an Emacs package for searching and navigating inline Code Review Comments (CRs) found in your current repository directly from within your editor.

Early releases of `crs-grep` aim to provide a minimal but usable tool for working with CRs. It currently has very few features and some limitations, but it serves as a starting point. Feedback from adventurous users is encouraged to help shape future versions!

## Features

- A simple mode derived from `grep-mode` that shells out to the `crs` CLI.
- Displays CRs found in your repository in a dedicated buffer.
- Navigate through CRs using the usual `grep-mode` keybindings.
- Visiting a CR automatically opens the corresponding file and location.

## Installation

The mode relies on the `crs` CLI being installed and available in your PATH or configured via the `crs-grep-cli` variable.

For now, the mode is shipped alongside the `crs` CLI from the Opam package named `crs`. It gets installed under `${share_root}/emacs/site-lisp`.

For example, if you have a `5.3.0` Opam switch, the path should look like this:

```sh
$HOME/.opam/5.3.0/share/emacs/site-lisp
```

If you are already a Dune and Opam user, you likely already have the below path listed in your `load-path`, as this is where the `dune.el` mode is distributed. If needed add the following to your Emacs configuration:


```emacs-lisp
(add-to-list 'load-path "/path/to/your/home/.opam/5.3.0/share/emacs/site-lisp")
```

### With require

Once the installation directory is listed in your `load-path`, you can load the package with:

```emacs-lisp
(require 'crs-grep)
```

To launch it, run the `crs-grep-run` function from a file or directory in your repository.

You can also bind this from your config, for example:

```emacs-lisp
(global-set-key (kbd "C-c r g") 'crs-grep-run)
```

### With use-package

If you use use-package, you can configure `crs-grep` like this:

```emacs-lisp
(use-package crs-grep
  :load-path "/path/to/your/home/.opam/5.3.0/share/emacs/site-lisp"
  :config
  ;; Optional: Add any additional configuration here
  (global-set-key (kbd "C-c r g") 'crs-grep-run))
```

### MELPA?

At this stage, `crs-grep` is in its early development phase, and we currently have no plans to publish it on MELPA.

## Feedback

We welcome feedback from adventurous users! If you encounter issues, have feature requests, or want to contribute, please open an issue or submit a pull request on GitHub.

Your input will help improve crs-grep and guide its development toward a more feature-rich and robust tool.

---
Thank you for trying crs-grep!
