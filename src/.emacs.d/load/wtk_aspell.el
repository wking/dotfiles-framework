;;; Set up spell-checking with aspell
;; http://aspell.net/man-html/Using-Aspell-with-other-Applications.html
;; http://www.delorie.com/gnu/docs/emacs/emacs_109.html
(setq-default ispell-program-name "aspell")
(global-set-key "\C-xs" 'ispell)
;; http://newsgroups.derkeiler.com/Archive/Comp/comp.emacs/2006-03/msg00005.html
;; http://blog.infion.de/archives/2007/07/09/GNU-Emacs,-aspell-and-the-problem-with-encodings/
(eval-after-load 'ispell
  '(when ispell-aspell-supports-utf8
     (setq ispell-extra-args
           (append ispell-extra-args '("--encoding" "none")))))
