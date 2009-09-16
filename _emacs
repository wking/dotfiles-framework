;;;; Trevor's sysadmin .emacs file
; started Sept 13, 2006
; The goal is to set up emacs for personal usage.
; See .emacs-admin for a more general setup

; Lisp comments begin with a ";"

;------------------------------------------------------------------------------
; Make operating on buffers more convienient

(setq inhibit-startup-message t)         ; no splash screen
(fset 'yes-or-no-p 'y-or-n-p)	         ; use y or n instead of yes or n
(setq require-final-newline t)	         ; always end a file with a newline
(setq backup-by-copying-when-mismatch t) ; preserve file's owner and group
(when (fboundp 'global-font-lock-mode)   ; turn on font-lock mode
  (global-font-lock-mode t))
(setq transient-mark-mode t)             ; enable visual feedback on selections
(global-set-key "\C-xg" 'goto-line)      ; bind the goto-line function

; Make scripts executable on Save (saves having to do the chmod every time)
;(add-hook 'after-save-hook 'executable-make-buffer-file-executable-if-script-p)

;------------------------------------------------------------------------------
; Set up a more organized version control
;
; Backups are saved to ~/.backup, and autosaves to ~/.autosave If
; ~/.backup doesn't exist it is created.  If ~/.autosave doesn't exist
; it is created, the standard autosave procedure is followed.
;
; following J.T. Halbert at http://www.math.umd.edu/~halbert/dotemacs.html
; and the Emacs manual at
; http://www.gnu.org/software/emacs/manual/html_node/emacs/Backup-Names.html

(setq backup-directory-alist (quote ((".*" . "~/.backup"))))
(defconst use-backup-dir t)	    ; Use backup directory

; From http://www.delorie.com/gnu/docs/emacs/emacs_125.html
; Emacs records interrupted sessions for later recovery in files named
; `~/.emacs.d/auto-save-list/.saves-pid-hostname'. The
; `~/.emacs.d/auto-save-list/.saves-' portion of these names comes
; from the value of auto-save-list-file-prefix.
(setq auto-save-list-file-prefix "~/.auto-save-list/.saves-")

; redefining the make-auto-save-file-name function in order to get
; autosave files sent to a single directory.  Note that this function
; looks first to determine if you have a ~/.autosave/ directory.  If
; you do not it proceeds with the standard auto-save procedure.
(defun make-auto-save-file-name ()
  "Return file name to use for auto-saves of current buffer.."
  (if buffer-file-name
      (if (file-exists-p "~/.autosave/")
          (concat (expand-file-name "~/.autosave/") "#"
                  (replace-regexp-in-string "/" "!" buffer-file-name)
                  "#")
         (concat
          (file-name-directory buffer-file-name)
          "#"
          (file-name-nondirectory buffer-file-name)
          "#"))
    (expand-file-name
     (concat "#%" (buffer-name) "#"))))

;------------------------------------------------------------------------------
; Personal tweaks

; Setup bundled EasyPG (encryption with gpg)
; from minor emacs wizardry
; http://emacs.wordpress.com/2008/07/18/keeping-your-secrets-secret/
(require 'epa)
;(epa-file-enable)
; end EasyPG

; setup org-mode
; http://orgmode.org/manual/Activation.html
; The following lines are always needed.  Choose your own keys.
(add-to-list 'auto-mode-alist '("\\.org\\'" . org-mode))
(global-set-key "\C-cl" 'org-store-link)
(global-set-key "\C-ca" 'org-agenda)
(global-set-key "\C-cb" 'org-iswitchb)

(setq browse-url-browser-function 'browse-url-firefox) ; loki hack

(defun org-time-stamp-now ()
  "Insert the current timestamp in org-mode, without recourse to the calendar."
  (interactive)
  (org-insert-time-stamp (current-time) 'with-hm 'inactive))
(global-set-key "\C-cn" 'org-time-stamp-now)
; end org-mode

; Emacs Load Path
;(setq load-path (cons "~/.emacs.d/load" load-path))
; Load querty.el, for switching keyboard mappings.
;(load "querty.el")

;(custom-set-variables
  ;; custom-set-variables was added by Custom.
  ;; If you edit it by hand, you could mess it up, so be careful.
  ;; Your init file should contain only one such instance.
  ;; If there is more than one, they won't work right.
; '(safe-local-variable-values (quote ((noweb-code-mode . c-mode)))))
;(custom-set-faces
  ;; custom-set-faces was added by Custom.
  ;; If you edit it by hand, you could mess it up, so be careful.
  ;; Your init file should contain only one such instance.
  ;; If there is more than one, they won't work right.
; )
