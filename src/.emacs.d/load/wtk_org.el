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
