;------------------------------------------------------------------------------
; Make operating on buffers more convienient

(setq inhibit-startup-message t)         ; no splash screen
(fset 'yes-or-no-p 'y-or-n-p)            ; use y or n instead of yes or n
(setq require-final-newline t)           ; always end a file with a newline
(setq backup-by-copying-when-mismatch t) ; preserve file's owner and group
(when (fboundp 'global-font-lock-mode)   ; turn on font-lock mode
  (global-font-lock-mode t))
(setq transient-mark-mode t)             ; enable visual feedback on selections
(global-set-key "\C-xg" 'goto-line)      ; bind the goto-line function

; Make scripts executable on Save (saves having to do the chmod every time)
(add-hook 'after-save-hook 'executable-make-buffer-file-executable-if-script-p)
