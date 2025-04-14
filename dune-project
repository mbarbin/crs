(lang dune 3.17)

(name crs)

(generate_opam_files)

(license "LGPL-3.0-or-later WITH LGPL-3.0-linking-exception")

(authors "Mathieu Barbin")

(maintainers "Mathieu Barbin <opensource@mbarbin.org>")

(source
 (github mbarbin/crs))

(documentation "https://mbarbin.github.io/crs/")

(using mdx 0.4)

(implicit_transitive_deps false)

(package
 (name crs)
 (synopsis
  "A tool for managing code review comments embedded in source code")
 (depends
  (ocaml
   (>= 5.2))
  (base
   (and
    (>= v0.17)
    (< v0.18)))
  (cmdlang
   (>= 0.0.9))
  (file-rewriter
   (>= 0.0.3))
  (fpath
   (>= 0.7.3))
  (fpath-base
   (>= 0.2.2))
  (loc
   (>= 0.2.2))
  (pp
   (>= 2.0.0))
  (pplumbing
   (>= 0.0.9))
  (ppx_compare
   (and
    (>= v0.17)
    (< v0.18)))
  (ppx_enumerate
   (and
    (>= v0.17)
    (< v0.18)))
  (ppx_hash
   (and
    (>= v0.17)
    (< v0.18)))
  (ppx_here
   (and
    (>= v0.17)
    (< v0.18)))
  (ppx_let
   (and
    (>= v0.17)
    (< v0.18)))
  (ppx_sexp_conv
   (and
    (>= v0.17)
    (< v0.18)))
  (ppx_sexp_value
   (and
    (>= v0.17)
    (< v0.18)))
  (ppxlib
   (>= 0.33))
  (re2
   (and
    (>= v0.17)
    (< v0.18)))
  (shexp
   (and
    (>= v0.17)
    (< v0.18)))
  (stdio
   (and
    (>= v0.17)
    (< v0.18)))
  (textutils
   (and
    (>= v0.17)
    (< v0.18)))
  (vcs
   (>= 0.0.11))
  (vcs-base
   (>= 0.0.11))
  (vcs-git-blocking
   (>= 0.0.11))))

(package
 (name crs-tests)
 (synopsis "Tests for crs")
 (depends
  (ocaml
   (>= 5.2))
  (ocamlformat
   (and
    :with-dev-setup
    (= 0.27.0)))
  (base
   (and
    (>= v0.17)
    (< v0.18)))
  (cmdlang
   (>= 0.0.9))
  (crs
   (= :version))
  (expect_test_helpers_core
   (and
    (>= v0.17)
    (< v0.18)))
  (file-rewriter
   (>= 0.0.3))
  (fpath
   (>= 0.7.3))
  (fpath-base
   (>= 0.2.2))
  (loc
   (>= 0.2.2))
  (patdiff
   (and
    (>= v0.17)
    (< v0.18)))
  (pp
   (>= 2.0.0))
  (pplumbing
   (>= 0.0.9))
  (ppx_compare
   (and
    (>= v0.17)
    (< v0.18)))
  (ppx_enumerate
   (and
    (>= v0.17)
    (< v0.18)))
  (ppx_expect
   (and
    (>= v0.17)
    (< v0.18)))
  (ppx_hash
   (and
    (>= v0.17)
    (< v0.18)))
  (ppx_here
   (and
    (>= v0.17)
    (< v0.18)))
  (ppx_js_style
   (and
    :with-dev-setup
    (>= v0.17)
    (< v0.18)))
  (ppx_let
   (and
    (>= v0.17)
    (< v0.18)))
  (ppx_sexp_conv
   (and
    (>= v0.17)
    (< v0.18)))
  (ppx_sexp_value
   (and
    (>= v0.17)
    (< v0.18)))
  (ppxlib
   (>= 0.33))
  (re2
   (and
    (>= v0.17)
    (< v0.18)))
  (shexp
   (and
    (>= v0.17)
    (< v0.18)))
  (stdio
   (and
    (>= v0.17)
    (< v0.18)))
  (textutils
   (and
    (>= v0.17)
    (< v0.18)))
  (vcs
   (>= 0.0.11))
  (vcs-base
   (>= 0.0.11))
  (vcs-cli
   (>= 0.0.11))
  (vcs-git-blocking
   (>= 0.0.11))
  (sherlodoc
   (and
    :with-doc
    (>= 0.2)))))

(package
 (name crs-dev)
 (synopsis
  "Package to regroup dev targets for the project, documentation, and more")
 (allow_empty) ; In case the package is wip or attached to stanzas that dune doesn't see.
 (depends
  (ocaml
   (>= 5.2))
  (ocamlformat
   (and
    :with-dev-setup
    (= 0.27.0)))
  (base
   (and
    (>= v0.17)
    (< v0.18)))
  (bisect_ppx
   (and
    :with-dev-setup
    (>= 2.8.3)))
  (cmdlang
   (>= 0.0.9))
  (crs
   (= :version))
  (crs-tests
   (= :version))
  (expect_test_helpers_core
   (and
    (>= v0.17)
    (< v0.18)))
  (file-rewriter
   (>= 0.0.3))
  (fpath
   (>= 0.7.3))
  (fpath-base
   (>= 0.2.2))
  (loc
   (>= 0.2.2))
  (mdx
   (>= 2.4))
  (patdiff
   (and
    (>= v0.17)
    (< v0.18)))
  (pp
   (>= 2.0.0))
  (pplumbing
   (>= 0.0.9))
  (ppx_compare
   (and
    (>= v0.17)
    (< v0.18)))
  (ppx_enumerate
   (and
    (>= v0.17)
    (< v0.18)))
  (ppx_expect
   (and
    (>= v0.17)
    (< v0.18)))
  (ppx_hash
   (and
    (>= v0.17)
    (< v0.18)))
  (ppx_here
   (and
    (>= v0.17)
    (< v0.18)))
  (ppx_js_style
   (and
    :with-dev-setup
    (>= v0.17)
    (< v0.18)))
  (ppx_let
   (and
    (>= v0.17)
    (< v0.18)))
  (ppx_sexp_conv
   (and
    (>= v0.17)
    (< v0.18)))
  (ppx_sexp_value
   (and
    (>= v0.17)
    (< v0.18)))
  (ppxlib
   (>= 0.33))
  (re2
   (and
    (>= v0.17)
    (< v0.18)))
  (shexp
   (and
    (>= v0.17)
    (< v0.18)))
  (stdio
   (and
    (>= v0.17)
    (< v0.18)))
  (textutils
   (and
    (>= v0.17)
    (< v0.18)))
  (vcs
   (>= 0.0.11))
  (vcs-base
   (>= 0.0.11))
  (vcs-cli
   (>= 0.0.11))
  (vcs-git-blocking
   (>= 0.0.11))
  (odoc
   (and
    :with-doc
    (>= 2.4.4)))
  (sherlodoc
   (and
    :with-doc
    (>= 0.2)))))
