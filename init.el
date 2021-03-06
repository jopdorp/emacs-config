(require 'package)
(package-initialize)
(setq package-archives #'(("gnu" . "https://elpa.gnu.org/packages/")
			  ("marmalade" . "https://marmalade-repo.org/packages/")
			  ("melpa" . "https://melpa.org/packages/")))

(load "server")
(unless (server-running-p) (server-start))
(global-linum-mode 1)
(show-paren-mode 1)
(delete-selection-mode 1)

(global-set-key (kbd "C-c I") #'find-user-init-file)
(global-set-key (kbd "M-a") #'compile)
(global-set-key "\C-z" #'undo)
(global-set-key "\C-s" #'save-buffer)
(global-set-key "\C-v" #'yank)
(global-set-key (kbd "M-<up>") #'move-line-up)
(global-set-key (kbd "C-/") #'comment-or-uncomment-region-or-line)
(global-set-key (kbd "M-<down>") #'move-line-down)
(global-set-key "\C-f" #'isearch-forward)
(define-key isearch-mode-map "\C-f" #'isearch-repeat-forward)
(global-set-key "\C-r" #'query-replace-from-start)
(global-set-key (kbd "M-<up>") #'move-text-up)
(global-set-key (kbd "M-<down>") #'move-text-down)
(global-set-key "\C-d" "\C-a\C- \C-n\M-w\C-y\C-p")
(global-set-key (kbd "C-<right>") #'move-end-of-line)
(global-set-key (kbd "C-<left>") #'move-beginning-of-line)
(global-set-key "\C-cr" #'my-query-replace-all)
(global-set-key "\C-k"  #'kill-whole-line)
(global-set-key "\C-k"  #'kill-whole-line)
(global-set-key (kbd "<mouse-4>") #'previous-buffer)
(global-set-key (kbd "<mouse-5>") #'next-buffer)
(global-set-key [f12] #'indent-buffer)


(defun switch-to-minibuffer-window ()
  "switch to minibuffer window (if active)"
  (interactive)
  (when (active-minibuffer-window)
    (select-frame-set-input-focus (window-frame (active-minibuffer-window)))
    (select-window (active-minibuffer-window))))

(defun comment-or-uncomment-region-or-line ()
  "Comments or uncomments the region or the current line if there's no active region."
  (interactive)
  (let (beg end)
    (if (region-active-p)
        (setq beg (region-beginning) end (region-end))
      (setq beg (line-beginning-position) end (line-end-position)))
    (comment-or-uncomment-region beg end)
    (next-line)))

;; query replace all from buffer start
(fset #'query-replace-from-start #'query-replace)
(advice-add #'query-replace-from-start
            :around
            #'(lambda(oldfun &rest args)
		"Query replace the whole buffer."
		;; set start pos
		(unless (nth 3 args)
                  (setf (nth 3 args)
			(if (region-active-p)
                            (region-beginning)
                          (point-min))))
		(unless (nth 4 args)
                  (setf (nth 4 args)
			(if (region-active-p)
                            (region-end)
                          (point-max))))
		(apply oldfun args)))

(defadvice isearch-repeat (after isearch-no-fail activate)
  (unless isearch-success
    (ad-disable-advice #'isearch-repeat #'after #'isearch-no-fail)
    (ad-activate #'isearch-repeat)
    (isearch-repeat (if isearch-forward #'forward))
    (ad-enable-advice #'isearch-repeat #'after #'isearch-no-fail)
    (ad-activate #'isearch-repeat)))

(defadvice isearch-mode
    (around isearch-mode-default-string
	    (forward &optional regexp op-fun recursive-edit word-p) activate)
  (if (and transient-mark-mode mark-active (not (eq (mark) (point))))
      (progn
        (isearch-update-ring (buffer-substring-no-properties (mark) (point)))
        (deactivate-mark)
        ad-do-it
        (if (not forward)
            (isearch-repeat-backward)
          (goto-char (mark))
          (isearch-repeat-forward)))
    ad-do-it))

(defun find-user-init-file ()
  "Edit the `user-init-file', in another window."
  (interactive)
  (find-file user-init-file))

(defun move-text-internal (arg)
  (cond
   ((and mark-active transient-mark-mode)
    (if (> (point) (mark))
        (exchange-point-and-mark))
    (let ((column (current-column))
          (text (delete-and-extract-region (point) (mark))))
      (forward-line arg)
      (move-to-column column t)
      (set-mark (point))
      (insert text)
      (exchange-point-and-mark)
      (setq deactivate-mark nil)))
   (t
    (beginning-of-line)
    (when (or (> arg 0) (not (bobp)))
      (forward-line)
      (when (or (< arg 0) (not (eobp)))
        (transpose-lines arg))
      (forward-line -1)))))

(defun move-text-down (arg)
  "Move region (transient-mark-mode active) or current line
  arg lines down."
  (interactive "*p")
  (move-text-internal arg))

(defun move-text-up (arg)
  "Move region (transient-mark-mode active) or current line
  arg lines up."
  (interactive "*p")
  (move-text-internal (- arg)))

(defun indent-buffer ()
  (interactive)
  (save-excursion
    (indent-region (point-min) (point-max) nil)))


(load-file "~/.emacs.d/verilog-mode.el")
(autoload #'verilog-mode "verilog-mode" "Verilog mode" t)
(add-to-list #'auto-mode-alist #'("\\.[ds]?vh?\\'" . verilog-mode))

(setq verilog-indent-level             4
      verilog-indent-level-module      4
      verilog-indent-level-declaration 4
      verilog-indent-level-behavioral  4
      verilog-indent-level-directive   4
      verilog-case-indent              4
      verilog-auto-newline             nil
      verilog-auto-indent-on-newline   t
      verilog-tab-always-indent        t
      verilog-auto-endcomments         t
      verilog-minimum-comment-distance 40
      verilog-indent-begin-after-if    t
      verilog-auto-lineup              nil
      verilog-linter                   "iverilog -g2012")
