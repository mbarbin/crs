;;; crs-grep.el --- Search and Navigate Inline Code Review Comments (CRs) -*- lexical-binding: t; -*-
;;
;; Copyright 2025 Mathieu Barbin
;;
;; Author: Mathieu Barbin <mathieu.barbin@gmail.com>
;; Maintainer: Mathieu Barbin <mathieu.barbin@gmail.com>
;; URL: https://github.com/mbarbin/crs
;; Keywords: tools
;; Version: 0.0.4
;; Package-Requires: ((emacs "29.1"))
;; SPDX-License-Identifier: GPL-3.0-or-later
;;
;; This file is not part of GNU Emacs.
;;
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.
;;
;;; Commentary:
;;
;; Provides a grep buffer to display CRs found in the current repository.
;;
;;; Code:

;;; Customization group
(defgroup crs-grep nil
  "Search and navigate inline code review comments (CRs) using the `crs` CLI."
  :group 'tools
  :prefix "crs-grep-")

;;; Customizable variable
(defcustom crs-grep-cli "crs"
  "Path to the `crs` CLI executable.
By default, this is set to \"crs\", meaning it will be searched in the `PATH`.
Set this to an absolute path if the executable is not in your `PATH`."
  :type 'string
  :group 'crs-grep)

(defcustom crs-grep-default-filter "now"
  "Default filter for `crs-grep` when opening the CRs buffer.
Should be one of: all, crs, xcrs, now, soon, someday, invalid, summary."
  :type
  '(choice
    (const "all")
    (const "crs")
    (const "xcrs")
    (const "now")
    (const "soon")
    (const "someday")
    (const "invalid")
    (const "summary"))
  :group 'crs-grep)

(defcustom crs-grep-enable-next-error-follow nil
  "If non-nil, enable `next-error-follow-minor-mode' in the CRs buffer by default."
  :type 'boolean
  :group 'crs-grep
  :package-version '("crs-grep" . "0.0.4"))

(defcustom crs-grep-buffer-opening-behavior "split"
  "How to open the CRs buffer when it does not already exist.

If set to \"replace\", the CRs buffer will open in the current window,
replacing the buffer at point.  If set to \"split\", the CRs buffer will open
in a new window (the default behavior).  When the buffer already exists,
its window placement is preserved.  Allowed values are: \"replace\", \"split\"."
  :type
  '(choice
    (const :tag "Replace current buffer" "replace")
    (const :tag "Split window" "split"))
  :group 'crs-grep
  :package-version '("crs-grep" . "0.0.3"))

(defcustom crs-grep-enable-header-line t
  "If non-nil, show a header line in the CRs buffer.

When enabled, the header line in the CRs buffer displays
contextual information such as the currently active CRs filter
and the root path from which the search is run.  This provides
persistent state awareness for the buffer contents."
  :type 'boolean
  :group 'crs-grep
  :package-version '("crs-grep" . "0.0.4"))

(defvar crs-grep-buffer-name "*CRs*"
  "Name of the buffer used to display Code Review Comments (CRs).")

(defvar crs-grep-last-directory nil
  "Stores the last directory where `crs grep` was run.")

(defvar crs-grep-current-filter nil
  "Current filter flag for `crs-grep` CLI.
Always a string, e.g. \"now\", \"all\", etc.")

;; Variables to store repo-root and path-in-repo
(defvar crs-grep-repo-root nil
  "The root directory of the enclosing repository for the current CRs session.")

(defvar crs-grep-path-in-repo nil
  "The path within the repository for the current CRs session.")

(defun crs-grep--parse-json-repo-info (json-string)
  "Parse JSON-STRING output from `crs tools enclosing-repo-info`."
  (json-parse-string json-string :object-type 'alist))

(defun crs-grep--update-repo-info (directory)
  "Update `crs-grep-repo-root` and `crs-grep-path-in-repo` for DIRECTORY."
  (let* ((default-directory directory)
         (output
          (with-temp-buffer
            (let ((exit-code
                   (call-process crs-grep-cli
                                 nil
                                 t
                                 nil
                                 "tools"
                                 "enclosing-repo-info")))
              (if (eq exit-code 0)
                  (buffer-string)
                nil)))))
    (when output
      (let* ((alist (crs-grep--parse-json-repo-info output))
             (repo-root (alist-get "repo_root" alist nil nil #'equal))
             (path-in-repo (alist-get "path_in_repo" alist nil nil #'equal)))
        (setq crs-grep-repo-root repo-root)
        (setq crs-grep-path-in-repo path-in-repo)))))

(defun crs-grep--run-in-directory (directory)
  "Run the `crs grep` command in the given DIRECTORY and update the `*CRs*` buffer."
  (crs-grep--update-repo-info directory)
  (let ((output-buffer (get-buffer-create crs-grep-buffer-name)))
    (with-current-buffer output-buffer
      (let ((default-directory directory)
            (inhibit-read-only t))
        (erase-buffer)
        (let ((exit-code
               (call-process crs-grep-cli
                             nil
                             output-buffer
                             nil
                             "tools"
                             "emacs-grep"
                             "--path-display-mode=absolute"
                             (concat "--" crs-grep-current-filter))))
          (when (fboundp 'ansi-color-apply-on-region)
            (ansi-color-apply-on-region (point-min) (point-max)))
          (if (eq exit-code 0)
              (progn
                (crs-grep-mode)
                (when crs-grep-enable-header-line
                  (setq header-line-format
                        (format "CRs: type \"%s\"   path \"%s\"   repo \"%s\""
                                crs-grep-current-filter
                                crs-grep-path-in-repo
                                crs-grep-repo-root)))
                (when crs-grep-enable-next-error-follow
                  (next-error-follow-minor-mode 1))
                (goto-char (point-min)))
            (message
             "Failed to run `crs grep`. Check the CLI path or repository state.")))))
    (if (get-buffer-window output-buffer)
        (select-window (get-buffer-window output-buffer))
      (cond
       ((string= crs-grep-buffer-opening-behavior "replace")
        (switch-to-buffer output-buffer))
       (t
        (pop-to-buffer output-buffer))))))

;;;###autoload
(defun crs-grep-run ()
  "Run the `crs grep` command and display the results in a special buffer."
  (interactive)
  (let ((current-dir default-directory))
    (setq crs-grep-last-directory current-dir)
    (setq crs-grep-current-filter crs-grep-default-filter)
    (crs-grep--run-in-directory current-dir)))

(defun crs-grep-refresh ()
  "Refresh the CRs buffer by re-running the last `crs grep` command."
  (interactive)
  (if crs-grep-last-directory
      (crs-grep--run-in-directory crs-grep-last-directory)
    (message "No previous directory to refresh from. Run `crs-grep` first.")))

(defun crs-grep-refresh-from-root ()
  "Set the running directory to the repository root and refresh the CRs buffer.
If `crs-grep-repo-root` is nil, shows an error message."
  (interactive)
  (if crs-grep-repo-root
      (progn
        (setq crs-grep-last-directory crs-grep-repo-root)
        (crs-grep--run-in-directory crs-grep-repo-root))
    (message "No repository root available. Try running `crs-grep` first.")))

(defun crs-grep-set-filter (filter-name)
  "Set the CRs type filter to FILTER-NAME (string) and refresh the CRs buffer.
Prompts if called interactively."
  (interactive
   (list
    (completing-read
     "Filter (all, crs, xcrs, now, soon, someday, invalid, summary): "
     '("all" "crs" "xcrs" "now" "soon" "someday" "invalid" "summary")
     nil
     t)))
  (setq crs-grep-current-filter filter-name)
  (crs-grep-refresh))

(defun crs-grep-set-filter-all ()
  "Set the CRs type filter to \"all\" and refresh the CRs buffer.
This will show all CRs types.
Further refreshing the buffer will continue to show all CRs."
  (interactive)
  (crs-grep-set-filter "all"))

(defun crs-grep-set-filter-crs ()
  "Set the CRs type filter to \"crs\" and refresh the CRs buffer.
This will show only CRs of type \"CR\".
Further refreshing the buffer will continue to show \"CR\"s only."
  (interactive)
  (crs-grep-set-filter "crs"))

(defun crs-grep-set-filter-xcrs ()
  "Set the CRs type filter to \"xcrs\" and refresh the CRs buffer.
This will show only CRs of type \"XCR\".
Further refreshing the buffer will continue to show \"XCR\"s only."
  (interactive)
  (crs-grep-set-filter "xcrs"))

(defun crs-grep-set-filter-now ()
  "Set the CRs type filter to \"now\" and refresh the CRs buffer.
This will show only CRs to be worked on \"now\".
Further refreshing the buffer will continue to show CRs \"now\" only."
  (interactive)
  (crs-grep-set-filter "now"))

(defun crs-grep-set-filter-soon ()
  "Set the CRs type filter to \"soon\" and refresh the CRs buffer.
This will show only CRs to be worked on \"soon\".
Further refreshing the buffer will continue to show CRs \"soon\" only."
  (interactive)
  (crs-grep-set-filter "soon"))

(defun crs-grep-set-filter-someday ()
  "Set the CRs type filter to \"someday\" and refresh the CRs buffer.
This will show only CRs to be worked on \"someday\".
Further refreshing the buffer will continue to show CRs \"someday\" only."
  (interactive)
  (crs-grep-set-filter "someday"))

(defun crs-grep-set-filter-invalid ()
  "Set the CRs type filter to \"invalid\" and refresh the CRs buffer.
This will show only invalid CRs.
Further refreshing the buffer will continue to show invalid CRs only."
  (interactive)
  (crs-grep-set-filter "invalid"))

(defun crs-grep-set-filter-summary ()
  "Set the CRs type filter to \"summary\" and refresh the CRs buffer.
This will show only the summary box.
Further refreshing the buffer will continue to show the summary only."
  (interactive)
  (crs-grep-set-filter "summary"))

;;; Mode

(defvar crs-grep-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map "g" 'crs-grep-refresh)
    (define-key map "r" 'crs-grep-refresh-from-root)
    (define-key map "q" 'quit-window)
    (define-key map "c" 'crs-grep-set-filter-crs)
    (define-key map "x" 'crs-grep-set-filter-xcrs)
    (define-key map "w" 'crs-grep-set-filter-now)
    (define-key map "o" 'crs-grep-set-filter-soon)
    (define-key map "d" 'crs-grep-set-filter-someday)
    (define-key map "i" 'crs-grep-set-filter-invalid)
    (define-key map "a" 'crs-grep-set-filter-all)
    (define-key map "s" 'crs-grep-set-filter-summary)
    map)
  "Keymap for `crs-grep-mode`.

Keys:
  g   Refresh CRs buffer (keep current filter)
  r   Set running directory to repository root and refresh (keep current filter)
  a   Show all CRs types (clear filter)
  c   Show only CRs of type \"CR\" (set filter)
  x   Show only CRs of type \"XCR\" (set filter)
  w   Show only CRs to be worked on \"now\" (set filter)
  o   Show only CRs to be worked on \"soon\" (set filter)
  d   Show only CRs to be worked on \"someday\" (set filter)
  i   Show only invalid CRs (set filter)
  s   Show only the summary box (set filter)
  q   Quit")

;;;###autoload
(define-derived-mode
 crs-grep-mode grep-mode "CRs"
 "Major mode for navigating Code Review Comments (CRs).

Keys:
  g   Refresh CRs buffer (keep current filter)
  r   Set running directory to repository root and refresh (keep current filter)
  a   Show all CRs types (clear filter)
  c   Show only CRs of type \"CR\" (set filter)
  x   Show only CRs of type \"XCR\" (set filter)
  w   Show only CRs to be worked on \"now\" (set filter)
  o   Show only CRs to be worked on \"soon\" (set filter)
  d   Show only CRs to be worked on \"someday\" (set filter)
  i   Show only invalid CRs (set filter)
  s   Show only the summary box (set filter)
  q   Quit"
 :keymap crs-grep-mode-map)

(provide 'crs-grep)

;;; crs-grep.el ends here
