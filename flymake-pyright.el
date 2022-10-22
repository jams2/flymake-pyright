;;; flymake-pyright.el --- flymake backend for pyright -*- lexical-binding: t -*-

(defvar-local flymake-pyright--current-process nil)
(defvar-local flymake-pyright-enabled nil)
(defvar-local flymake-pyright-executable "node_modules/.bin/pyright")
(defvar-local flymake-pyright-args nil)
(defvar-local flymake-pyright-use-poetry nil)

(defun flymake-pyright-get-command (file-name)
  (cond (flymake-pyright-use-poetry
	 (append (list "poetry" "run" flymake-pyright-executable)
		 flymake-pyright-args
		 (list file-name)))
	(t (error "Not implemented"))))

(defun flymake-pyright-make-process-sentinel (report-fn source-buf)
  (lambda (proc why)
    (when (or (string-prefix-p "finished" why)
	      (string-prefix-p "failed with code" why)
	      (string-prefix-p "exited abnormally" why))
      (with-current-buffer (process-buffer proc)
	(goto-char (point-min))
	(let ((re "^[[:space:]]+\\([^:]+\\):\\([0-9]+\\):\\([0-9]+\\) - \\([^:]+:.+$\\)")
	      (diagnostics nil))
	  (while (re-search-forward re nil t)
	    (let* ((msg (match-string 4))
		   (line (string-to-number (match-string 2)))
		   (col (string-to-number (match-string 3)))
		   (bounds (flymake-diag-region source-buf line col))
		   (beg (car bounds))
		   (end (cdr bounds))
		   ;; string-match alters match-data, so do this after getting other values
		   (type (if (string-match "^error" msg)
			     :error
			   :warning))
		   (diagnostic (flymake-make-diagnostic source-buf beg end type msg)))
	      (setq diagnostics (cons `(,line . ,diagnostic) diagnostics))))
	  (setq diagnostics (sort diagnostics (lambda (p q) (< (car q) (car p)))))
	  (setq flymake-pyright--current-process nil)
	  (funcall report-fn (mapcar #'cdr diagnostics)))))))

(defun flymake-pyright (report-fn &rest _)
  (when flymake-pyright-enabled
    (let ((source-buf (current-buffer))
	  (file-name (buffer-file-name))
	  (output-buffer (get-buffer-create "*pyright-output*"))
	  (error-buffer (get-buffer-create "*pyright-errors*")))
      (dolist (buf `(,output-buffer ,error-buffer))
	(with-current-buffer buf (erase-buffer)))
      (when flymake-pyright--current-process
	(interrupt-process flymake-pyright--current-process))
      (setq flymake-pyright--current-process
	    (make-process
	     :name "pyright"
	     :command (flymake-pyright-get-command file-name)
	     :buffer output-buffer
	     :stderr error-buffer
	     :sentinel (flymake-pyright-make-process-sentinel report-fn source-buf))))))

(defun flymake-pyright-setup-backend ()
  (add-hook 'flymake-diagnostic-functions #'flymake-pyright -100 t))

(provide 'flymake-pyright)
