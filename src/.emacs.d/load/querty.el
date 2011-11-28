;------------------------------------------------------------;
; qwerty.el
;
; For people who are used to more efficient keyboard layouts.
;
; version 1.1
;
; * Now includes `M-x dvorak' to switch to a Dvorak keyboard layout.
;
; Written by Neil Jerram <nj104_AT_cus.cam.ac.uk>,
; Monday 14 December 1992.
; Copyright (C) 1993 Neil Jerram.

;;; This program is free software; you can redistribute it and/or modify
;;; it under the terms of the GNU General Public License as published by
;;; the Free Software Foundation; either version 1, or (at your option)
;;; any later version.
;;;
;;; This program is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; The GNU General Public License is available by anonymous ftp from
;;; prep.ai.mit.edu in pub/gnu/COPYING.  Alternately, you can write to
;;; the Free Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139,
;;; USA.

; This trivial piece of Emacs Lisp was inspired by Stephen Jay Gould's
; essay "The Panda's Thumb of Technology" in his book "Bully for
; Brontosaurus".  In this essay, he explains how the intrinsically
; inefficient QWERTY keyboard layout (all the most common keys are in
; weak finger positions) is a hangover from the days when typists
; needed to be slowed down so that the (hidden) mechanics of the
; typewriter didn't get jammed.  Maybe if enough people come to use
; Emacs and realise the advantages of different keyboard layouts, the
; days of QWERTY could be numbered.

; EXAMPLE: French keyboards often have A and Q swapped around
; (in comparison with English keyboards).  So a French person
; unused to the English layout (and vice-versa) could re-program
; his/her keyboard by typing `M-x anti-qwerty RET aq RET qa RET'.

; I would be very interested to hear about alternative keyboard
; layouts that anyone may use, preferably with their definitions
; with respect to the usual QWERTY layout.

; Public functions

(defun qwerty ()

  "Qwerty keyboard layout."

  (interactive)
  (setq keyboard-translate-table nil)
  (message "Default keyboard restored."))

(defun dvorak ()

  "Dvorak keyboard layout:
-------------------------------------------------------------------------
| Esc| 1  | 2  | 3  | 4  | 5  | 6  | 7  | 8  | 9  | 0  | [  | ]  |  <-  |
-------------------------------------------------------------------------
| Tab | /  | ,  | .  | p  | y  | f  | g  | c  | r  | l  | ;  | =  |     |
------------------------------------------------------------------- |   |
| Ctrl | a  | o  | e  | u  | i  | d  | h  | t  | n  | s  | -  |   <-    |
-------------------------------------------------------------------------
| Shift  | '  | q  | j  | k  | x  | b  | m  | w  | v  | z  | Shift |
---------------------------------------------------------------------
"
  (interactive)
  (anti-qwerty "/,.pyfgcrl;=aoeuidhtns-'qjkxbmwvz?<>PYFGCRL:+AOEUIDHTNS_QJKXBMWVZ[]{}\""
	              "qwertyuiop[]asdfghjkl;'zxcvbnm,./QWERTYUIOP{}ASDFGHJKL:\"XCVBNM<>?-=_+Z"))

(defun anti-qwerty (old new &optional ctrl unsafe)

  "Remaps the keyboard according to OLD and NEW strings.  OLD should
include all the keys that the user wants to change, typed in the
default keyboard system (usually qwerty).  NEW is what the user would
like to be typing in order to produce the contents of OLD on the
screen.

  The third (optional prefix) argument CTRL, if non-nil, means that
any transformations on letters that occur should be duplicated in the
related control characters: in other words, if `a' becomes `z', then
`C-a' should become `C-z'.

  Before implementing any changes the function first checks that the
mapping implied by OLD and NEW is one to one, in other words no two
keyboard keys may map to the same character and a single keyboard key
may not be given two different mappings.  If any such errors are
discovered in the mapping, no changes to the keyboard are made.

  As an additional safeguard, this function binds the keystroke `M-\'
to the restoring function `qwerty'.  If the fourth (optional) argument
UNSAFE is non-nil, this binding is suppressed."

  (interactive "sQWERTY expression: \nsNew system expression: \nP")
  (let ((o-n-map (if (qwerty-translation-safe-p old new)
		          0
		      (sit-for 1)))
	(n-o-map (if (qwerty-translation-safe-p new old)
		          0
		      (sit-for 1)))
	llp)
    (if (and (numberp o-n-map)
	          (numberp n-o-map))
	(progn
	    (setq llp (and (letters-to-letters-p old new)
			    (letters-to-letters-p new old)))
	      (un-qwerty old new llp ctrl)
	        (or unsafe
		          (progn (global-set-key "\e\\" 'qwerty)
				      (local-unset-key "\e\\"))
			        t)
		  (message 
		      (concat "Keyboard changed.  "
			         (if unsafe
				            "Type `M-x qwerty' to restore default."
				        "Type `M-\\' or `M-x qwerty' to restore default."))))
      (error "! Expressions given are not a one to one mapping"))))

; Private functions

(defun un-qwerty (old new llp ctrl)
  (let* ((the-table (make-string 128 0))
	  (ml (min (length old)
		     (length new)))
	   (old (substring old 0 ml))
	    (new (substring new 0 ml))
	     (i 0)
	      co cn)
    (while (< i ml)
      (setq co (aref old i)
	        cn (aref new i))
      (if (and (< co 128) (< cn 128)); Reject Meta characters.
	  (if (= (aref the-table cn) 0); No unnecessary repeats.
	            (progn
		      (if (not llp)
			      (aset the-table cn co)
			  (aset the-table (upcase cn) (upcase co))
			    (aset the-table (downcase cn) (downcase co)))
		      (setq co (- (upcase co) 64))
		      (if (or (not ctrl) (not llp) (< co 0) (> co 31))
			      nil
			  (aset the-table (- (upcase cn) 64) co)))))
      (setq i (1+ i)))
    (setq i 0)
    (while (< i 128)
      (if (= (aref the-table i) 0)
	    (aset the-table i i))
      (setq i (1+ i)))
    (setq keyboard-translate-table the-table)))

(defun qwerty-translation-safe-p (old new)
  "Returns nil if the mapping from OLD to NEW is not one to one."
  (let* ((mapping-length (min (length old)
			            (length new)))
	  (old (substring old 0 mapping-length))
	   (new (substring new 0 mapping-length))
	    (i 0)
	     (errors 0)
	      (case-fold-search nil)
	       j co cn match)
    (while (< i mapping-length)
      (setq co (aref old i)
	        cn (aref new i)
		    j (1+ i))
      (while (setq match
		      (string-match (regexp-quote (char-to-string co))
				     (substring old j)))
	(if (/= cn (aref (substring new j) match))
	        (setq errors (1+ errors)))
	(setq j (+ j match 1)))
      (setq i (1+ i)))
    (if (= errors 0)
	t
      (message "\"%s\" -> \"%s\" : %d %s" old new errors
	              (if (> errors 1) "errors" "error"))
      nil)))

(defun letters-to-letters-p (old new)
  "Returns t if all letters in OLD are mapped to letters in NEW."
  (let* ((mapping-length (min (length old)
			            (length new)))
	  (old (substring old 0 mapping-length))
	   (new (substring new 0 mapping-length))
	    (i 0)
	     (llp t)
	      (case-fold-search nil)
	       co cn)
    (while (< i mapping-length)
      (setq co (upcase (aref old i))
	        cn (upcase (aref new i))
		    j (1+ i))
      (and (>= co ?A)
	      (<= co ?Z)
	         (or (< cn ?A)
		            (> cn ?Z))
		    (setq llp nil))
      (setq i (1+ i)))
    llp))

;------------------------------------------------------------;
