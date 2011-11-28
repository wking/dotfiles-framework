;------------------------------------------------------------------------------
; Set up a more organized version control
;
; Backups are saved to ~/.emacs.d/.backup, and autosaves to
; ~/.emacs.d/.autosave.  If ~/.emacs.d/.backup doesn't exist it is
; created.  If ~/.emacs.d/.autosave doesn't exist it is created, the
; standard autosave procedure is followed.
;
; following J.T. Halbert at http://www.math.umd.edu/~halbert/dotemacs.html
; and the Emacs manual at
; http://www.gnu.org/software/emacs/manual/html_node/emacs/Backup-Names.html

(setq backup-directory-alist (quote ((".*" . "~/.emacs.d/.backup"))))
(defconst use-backup-dir t)            ; Use backup directory

; From http://www.delorie.com/gnu/docs/emacs/emacs_125.html
; Emacs records interrupted sessions for later recovery in files named
; `~/.emacs.d/auto-save-list/.saves-pid-hostname'. The
; `~/.emacs.d/auto-save-list/.saves-' portion of these names comes
; from the value of auto-save-list-file-prefix.
(setq auto-save-list-file-prefix "~/.emacs.d/.auto-save-list/.saves-")
