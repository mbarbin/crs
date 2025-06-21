;;; crs-grep.el --- Search and Navigate Code Review Comments (CRs) -*- lexical-binding: t; -*-
;;
;; Copyright 2025 Mathieu Barbin
;;
;; Author: Mathieu Barbin <mathieu.barbin@gmail.com>
;; Maintainer: Mathieu Barbin <mathieu.barbin@gmail.com>
;; URL: https://github.com/mbarbin/crs
;; Keywords: tools
;; Version: 0.0.1
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
  "Navigate and search Code Review Comments (CRs) using the `crs` CLI."
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
Should be one of: all, crs, xcrs, now, soon, someday, invalid."
  :type
  '(choice
    (const "all")
    (const "crs")
    (const "xcrs")
    (const "now")
    (const "soon")
    (const "someday")
    (const "invalid"))
  :group 'crs-grep)

(defvar crs-grep-buffer-name "*CRs*"
  "Name of the buffer used to display Code Review Comments (CRs).")

(defvar crs-grep-last-directory nil
  "Stores the last directory where `crs grep` was run.")

(defvar crs-grep-current-filter nil
  "Current filter flag for `crs-grep` CLI.
Always a string, e.g. \"now\", \"all\", etc.")

(defun crs-grep--run-in-directory (directory)
  "Run the `crs grep` command in the given DIRECTORY and update the `*CRs*` buffer."
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
          (if (eq exit-code 0)
              (progn
                (crs-grep-mode)
                (goto-char (point-min))
                (message
                 (format "CRs loaded successfully (%s)."
                         crs-grep-current-filter)))
            (message
             "Failed to run `crs grep`. Check the CLI path or repository state.")))))
    (pop-to-buffer output-buffer)))

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

(defun crs-grep-set-filter (filter-name)
  "Set the CRs type filter to FILTER-NAME (string) and refresh the CRs buffer.
Prompts if called interactively."
  (interactive (list
                (completing-read
                 "Filter (all, crs, xcrs, now, soon, someday, invalid): "
                 '("all" "crs" "xcrs" "now" "soon" "someday" "invalid")
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

;;; Mode

(defvar crs-grep-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map "g" 'crs-grep-refresh)
    (define-key map "q" 'quit-window)
    (define-key map "c" 'crs-grep-set-filter-crs)
    (define-key map "x" 'crs-grep-set-filter-xcrs)
    (define-key map "w" 'crs-grep-set-filter-now)
    (define-key map "o" 'crs-grep-set-filter-soon)
    (define-key map "d" 'crs-grep-set-filter-someday)
    (define-key map "i" 'crs-grep-set-filter-invalid)
    (define-key map "a" 'crs-grep-set-filter-all)
    map)
  "Keymap for `crs-grep-mode`.

Keys:
  g   Refresh CRs buffer (keep current filter)
  a   Show all CRs types (clear filter)
  c   Show only CRs of type \"CR\" (set filter)
  x   Show only CRs of type \"XCR\" (set filter)
  w   Show only CRs to be worked on \"now\" (set filter)
  o   Show only CRs to be worked on \"soon\" (set filter)
  d   Show only CRs to be worked on \"someday\" (set filter)
  i   Show only invalid CRs (set filter)
  q   Quit")

;;;###autoload
(define-derived-mode
 crs-grep-mode grep-mode "CRs"
 "Major mode for navigating Code Review Comments (CRs).

Keys:
  g   Refresh CRs buffer (keep current filter)
  a   Show all CRs types (clear filter)
  c   Show only CRs of type \"CR\" (set filter)
  x   Show only CRs of type \"XCR\" (set filter)
  w   Show only CRs to be worked on \"now\" (set filter)
  o   Show only CRs to be worked on \"soon\" (set filter)
  d   Show only CRs to be worked on \"someday\" (set filter)
  i   Show only invalid CRs (set filter)
  q   Quit"
 :keymap crs-grep-mode-map)

(provide 'crs-grep)

;;; crs-grep.el ends here
