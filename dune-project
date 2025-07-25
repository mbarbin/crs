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
   (and
    (>= 5.2)
    (< 5.4~)))
  (base
   (>= v0.17))
  (cmdlang
   (>= 0.0.9))
  (file-rewriter
   (>= 0.0.3))
  (fpath
   (>= 0.7.3))
  (fpath-base
   (>= 0.3.1))
  (loc
   (>= 0.2.2))
  (pageantty
   (>= 0.0.2))
  (pp
   (>= 2.0.0))
  (pplumbing
   (>= 0.0.14))
  (ppx_compare
   (>= v0.17))
  (ppx_enumerate
   (>= v0.17))
  (ppx_hash
   (>= v0.17))
  (ppx_here
   (>= v0.17))
  (ppx_sexp_conv
   (>= v0.17))
  (ppx_sexp_value
   (>= v0.17))
  (ppx_yojson_conv
   (>= v0.17))
  (ppxlib
   (>= 0.33))
  (print-table
   (>= 0.1.0))
  (re
   (>= 1.12.0))
  (spawn
   (>= v0.17))
  (stdio
   (>= v0.17))
  (volgo
   (>= 0.0.18))
  (volgo-base
   (>= 0.0.18))
  (volgo-git-unix
   (>= 0.0.18))
  (volgo-hg-unix
   (>= 0.0.18))
  (yojson
   (>= 2.1.1))
  (yojson-five
   (>= 2.1.1))))

(package
 (name crs-tests)
 (synopsis "Tests for crs")
 (depends
  (ocaml
   (>= 5.2))
  (ocamlformat
   (= 0.27.0))
  (base
   (>= v0.17))
  (base_quickcheck
   (>= v0.17))
  (cmdlang
   (>= 0.0.9))
  (cmdlang-stdlib-runner
   (>= 0.0.9))
  conf-git
  conf-hg
  (crs
   (= :version))
  (expect_test_helpers_core
   (>= v0.17))
  (file-rewriter
   (>= 0.0.3))
  (fpath
   (>= 0.7.3))
  (fpath-base
   (>= 0.3.1))
  (loc
   (>= 0.2.2))
  (ocaml-protoc
   (>= 3.1))
  (pageantty
   (>= 0.0.2))
  (patdiff
   (>= v0.17))
  (pbrt
   (>= 3.1))
  (pbrt_yojson
   (>= 3.1))
  (pp
   (>= 2.0.0))
  (pplumbing
   (>= 0.0.14))
  (ppx_compare
   (>= v0.17))
  (ppx_enumerate
   (>= v0.17))
  (ppx_expect
   (>= v0.17))
  (ppx_hash
   (>= v0.17))
  (ppx_here
   (>= v0.17))
  (ppx_js_style
   (and
    :with-dev-setup
    (>= v0.17)))
  (ppx_let
   (>= v0.17))
  (ppx_sexp_conv
   (>= v0.17))
  (ppx_sexp_value
   (>= v0.17))
  (ppx_yojson_conv
   (>= v0.17))
  (ppx_yojson_conv_lib
   (>= v0.17))
  (ppxlib
   (>= 0.33))
  (print-table
   (>= 0.1.0))
  (printbox
   (>= 0.12))
  (printbox-md
   (>= 0.12))
  (printbox-text
   (>= 0.12))
  (re
   (>= 1.12.0))
  (spawn
   (>= v0.17))
  (stdio
   (>= v0.17))
  (uutf
   (>= 1.0.4))
  (volgo
   (>= 0.0.18))
  (volgo-base
   (>= 0.0.18))
  (volgo-git-unix
   (>= 0.0.18))
  (volgo-hg-unix
   (>= 0.0.18))
  (volgo-vcs
   (>= 0.0.18))
  (yojson
   (>= 2.1.1))
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
   (= 0.27.0))
  (base
   (>= v0.17))
  (base_quickcheck
   (>= v0.17))
  (bisect_ppx
   (>= 2.8.3))
  (cmdlang
   (>= 0.0.9))
  conf-git
  conf-hg
  (crs
   (= :version))
  (crs-tests
   (= :version))
  (expect_test_helpers_core
   (>= v0.17))
  (file-rewriter
   (>= 0.0.3))
  (fpath
   (>= 0.7.3))
  (fpath-base
   (>= 0.3.1))
  (loc
   (>= 0.2.2))
  (mdx
   (>= 2.4))
  (ocaml-protoc
   (>= 3.1))
  (pageantty
   (>= 0.0.2))
  (patdiff
   (>= v0.17))
  (pbrt
   (>= 3.1))
  (pbrt_yojson
   (>= 3.1))
  (pp
   (>= 2.0.0))
  (pplumbing
   (>= 0.0.14))
  (ppx_compare
   (>= v0.17))
  (ppx_enumerate
   (>= v0.17))
  (ppx_expect
   (>= v0.17))
  (ppx_hash
   (>= v0.17))
  (ppx_here
   (>= v0.17))
  (ppx_js_style
   (>= v0.17))
  (ppx_let
   (>= v0.17))
  (ppx_sexp_conv
   (>= v0.17))
  (ppx_sexp_value
   (>= v0.17))
  (ppx_yojson_conv
   (>= v0.17))
  (ppx_yojson_conv_lib
   (>= v0.17))
  (ppxlib
   (>= 0.33))
  (print-table
   (>= 0.1.0))
  (re
   (>= 1.12.0))
  (spawn
   (>= v0.17))
  (stdio
   (>= v0.17))
  (volgo
   (>= 0.0.18))
  (volgo-base
   (>= 0.0.18))
  (volgo-git-unix
   (>= 0.0.18))
  (volgo-hg-unix
   (>= 0.0.18))
  (volgo-vcs
   (>= 0.0.18))
  (odoc
   (and
    :with-doc
    (>= 2.4.4)))
  (sherlodoc
   (and
    :with-doc
    (>= 0.2)))))
