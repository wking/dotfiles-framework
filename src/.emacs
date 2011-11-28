;;;; Trevor's sysadmin .emacs file
; started Sept 13, 2006
; The goal is to set up emacs for personal usage.
; See .emacs-admin for a more general setup

; Lisp comments begin with a ";"

; Emacs Load Path
;(setq load-path (cons "~/.emacs.d/load" load-path))

; Load useful customizations
(load "wtk_common.el")
(load "wtk_centralized_backups.el")
(load "wtk_layout.el")
(load "wtk_epa.el")
(load "wtk_org.el")

; Load querty.el, for switching keyboard mappings.
;(load "querty.el")
