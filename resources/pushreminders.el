;;; pushreminders.el --- Org mode reminders sent to your phone via pushover -*- lexical-binding: t -*-

;; Author: Laurent Charignon
;; Maintainer: Laurent Charignon
;; Version: 0.1
;; Package-Requires: ((emacs "25"))
;; Keywords: pushover, tools

;; This file is not part of GNU Emacs

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Org mode reminders sent to your phone via pushover
;;
;; Example of running this on buffer save
;; (defconst reminder-file "/home/laurent/reminders.org"
;;  "file with my org mode reminders")
;;
;; (defun sync-reminders ()
;;   (when (string= buffer-file-name reminder-file) (pushreminders-sync-reminders)))
;;
;; (add-hook 'after-save-hook #'sync-reminders)
;;
;;; Code:
(require 'json)
(require 'org)
(require 'cl-lib)

(defgroup pushreminders nil
  "Org mode reminders sent to your phone via pushover"
  :group 'tools)

(defcustom pushreminders-reminders-file "/home/laurent/Documents/reminders.json"
  "File to store the reminders."
  :group 'pushreminders
  :type 'string)

(defcustom pushreminders-host "http://localhost:3000"
  "Host with the pushover proxy."
  :group 'pushreminders
  :type 'string)

;; TODO Support already entered timestamp
(defun pushreminders-format-date (d)
  "Takes D an active timestamp and make it inactive with a timestamp of 10:00.
\(pushreminders-format-date <2019-02-13 Wed>\) => [2019-02-13 Wed 10:00]"
  (replace-regexp-in-string "<\\(.*\\)>" "[\\1 10:00]" d))

(defun pushreminders-add-reminder-at-point()
  "Add a reminder at point.
Need to be on a scheduled entry"
  (interactive)
  (let* ((scheduled-date (org-element-property :raw-value (org-element-property :scheduled (org-element-at-point))))
         (reminder-date (pushreminders-format-date scheduled-date)))
    (org-entry-put nil "REMINDER_DATE" reminder-date)
    (org-entry-put nil "REMINDER_TARGET" "laurent")))

(defun pushreminders-is-valid-reminder (x)
  "Return t if X an org element is a valid reminder."
  (and (org-element-property :REMINDER_TARGET x)
       (org-element-property :REMINDER_DATE x)))

(defun pushreminders-to-alist (x)
  "Given an org element X representing a reminders, return it as an ALIST."
  (let* ((title     (org-element-property :raw-value x))
         (target    (org-element-property :REMINDER_TARGET x))
         (date      (substring (org-element-property :REMINDER_DATE x) 1 -1))
         (timezone  "America/Los_Angeles")
         (msg       (or (org-element-property :REMINDER_MESSAGE x) title)))
    `((title . ,title)
      (target . ,target)
      (date . ,date)
      (timezone . ,timezone)
      (message . ,msg))))

(defun pushreminders-reminders-current-buffer ()
  "Return the list of reminders in the current buffer."
  (let* ((headlines (org-element-map (org-element-parse-buffer) 'headline #'identity))
         (reminders (cl-remove-if-not #'pushreminders-is-valid-reminder headlines)))
    (cl-mapcar #'pushreminders-to-alist reminders)))

(defun pushreminders-write-reminders (fn)
  "Write reminders of the current buffer to FN as JSON."
  (let ((json-str (json-encode (pushreminders-reminders-current-buffer))))
    (with-temp-buffer
      (insert json-str)
      (json-pretty-print-buffer)
      (write-file fn))))

(defun pushreminders-sync-reminders ()
  "Sync reminders in current buffer to the server."
  (interactive)
  (message "Exporting reminders")
  (pushreminders-write-reminders pushreminders-reminders-file)
  (message "Copy reminders on server")
  (shell-command-to-string
   (format "curl %s" pushreminders-host))
  (message "Synced reminders"))

(provide 'pushreminders)
;;; pushreminders.el ends here
