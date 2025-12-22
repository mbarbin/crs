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
   (>= v0.17))
  (cmdlang
   (>= 0.0.9))
  (cmdlang-cmdliner-err-runner
   (>= 0.0.16))
  (dyn
   (>= 3.17))
  (file-rewriter
   (>= 0.0.3))
  (fpath
   (>= 0.7.3))
  (fpath-sexp0
   (>= 0.4.0))
  (loc
   (>= 0.3.2))
  (ordering
   (>= 3.17))
  (pageantty
   (>= 0.0.2))
  (pp
   (>= 2.0.0))
  (pplumbing-err
   (>= 0.0.16))
  (pplumbing-pp-tty
   (>= 0.0.16))
  (print-table
   (>= 0.1.0))
  (re
   (>= 1.12.0))
  (sexplib0
   (>= v0.17))
  (spawn
   (>= v0.17))
  (volgo
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
  (base
   (>= v0.17))
  (cmdlang
   (>= 0.0.9))
  (cmdlang-cmdliner-err-runner
   (>= 0.0.16))
  (cmdlang-stdlib-runner
   (>= 0.0.9))
  conf-git
  conf-hg
  (crs
   (= :version))
  (file-rewriter
   (>= 0.0.3))
  (fpath
   (>= 0.7.3))
  (fpath-sexp0
   (>= 0.4.0))
  (loc
   (>= 0.3.2))
  (pageantty
   (>= 0.0.2))
  (patdiff
   (>= v0.17))
  (pp
   (>= 2.0.0))
  (pplumbing-err
   (>= 0.0.16))
  (pplumbing-pp-tty
   (>= 0.0.16))
  (ppx_expect
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
  (uutf
   (>= 1.0.4))
  (volgo
   (>= 0.0.18))
  (volgo-git-unix
   (>= 0.0.18))
  (volgo-hg-unix
   (>= 0.0.18))
  (volgo-vcs
   (>= 0.0.18))
  (yojson
   (>= 2.1.1))))

(package
 (name crs-dev)
 (synopsis "Package to regroup dev targets, documentation, and more")
 (allow_empty)
 (depends
  (ocaml
   (>= 5.2))
  (ocamlformat
   (= 0.28.1))
  (bisect_ppx
   (>= 2.8.3))
  (crs
   (= :version))
  (crs-tests
   (= :version))
  (mdx
   (>= 2.4))
  (ppx_js_style
   (>= v0.17))
  (ppxlib
   (>= 0.33))
  (odoc
   (>= 2.4.4))
  (sherlodoc
   (>= 0.2))))
