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

(defvar crs-grep-buffer-name "*CRs*"
  "Name of the buffer used to display Code Review Comments (CRs).")

(defvar crs-grep-last-directory nil
  "Stores the last directory where `crs grep` was run.")

(defun crs-grep--run-in-directory (directory)
  "Run the `crs grep` command in the given DIRECTORY and update the `*CRs*` buffer."
  (let ((output-buffer (get-buffer-create crs-grep-buffer-name)))
    (with-current-buffer output-buffer
      (let ((default-directory directory)
            (inhibit-read-only t)) ;; Allow modifications temporarily
        (erase-buffer)
        (let ((exit-code
               (call-process crs-grep-cli
                             nil
                             output-buffer
                             nil
                             "tools"
                             "emacs-grep"
                             "--path-display-mode=absolute")))
          (if (eq exit-code 0)
              (progn
                (crs-grep-mode) ;; Activate mode
                (goto-char (point-min))
                (message "CRs loaded successfully."))
            (message
             "Failed to run `crs grep`. Check the CLI path or repository state.")))))
    (pop-to-buffer output-buffer)))

;;;###autoload
(defun crs-grep-run ()
  "Run the `crs grep` command and display the results in a special buffer."
  (interactive)
  (let
      ((current-dir default-directory)) ;; Capture the current working directory
    (setq crs-grep-last-directory current-dir) ;; Save the directory for refresh
    (crs-grep--run-in-directory current-dir)))

(defun crs-grep-refresh ()
  "Refresh the CRs buffer by re-running the last `crs grep` command."
  (interactive)
  (if crs-grep-last-directory
      (crs-grep--run-in-directory crs-grep-last-directory)
    (message "No previous directory to refresh from. Run `crs-grep` first.")))

;;; Mode

(defvar crs-grep-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "g") 'crs-grep-refresh) ;; Refresh the buffer
    (define-key map (kbd "q") 'quit-window) ;; Quit the buffer
    map)
  "Keymap for `crs-grep-mode`.")

;;;###autoload
(define-derived-mode
 crs-grep-mode
 grep-mode
 "CRs"
 "Major mode for navigating Code Review Comments (CRs)."
 :keymap crs-grep-mode-map)

(provide 'crs-grep)

;;; crs-grep.el ends here
