# flymake-pyright.el

A simple flymake backend for pyright.

## Installation

Clone the repo (or just copy `flymake-pyright.el`) to an appropriate location.

``` emacs-lisp
(add-to-list 'load-path "/path/to/directory/containing/flymake-pyright")
(require 'flymake-pyright)
(add-hook 'python-mode-hook #'flymake-pyright-setup-backend)
```

### Using `use-package`

``` emacs-lisp
(use-package flymake-pyright
  :load-path "/path/to/directory/containing/flymake-pyright/"
  :hook
  (python-mode . flymake-pyright-setup-backend))
```

## Configuration

It can be useful to configure some variables on a per-project basis, using `.dir-locals.el` in the project root:

``` emacs-lisp
((python-mode
  . ((flymake-pyright-executable . "/path/to/project/node_modules/.bin/pyright")
     (flymake-pyright-use-poetry . t)  ;; or nil (usage without poetry not yet implemented)
     (flymake-pyright-enabled . t))))
```

### Usage with `eglot`

`eglot` manages your `flymake` backends, so you'll need to instruct it not to:

``` emacs-lisp
(setq eglot-stay-out-of '(flymake))
```

Then, you'll need to manually add the `eglot` `flymake` backend:

``` emacs-lisp
(add-hook 'eglot--managed-mode-hook
          (lambda ()
            (add-hook 'flymake-diagnostic-functions 'eglot-flymake-backend nil t)))
```

Finally, you may want to disable the `python-flymake` backend, now that `eglot` isn't taking care of that:

``` emacs-lisp
(defun remove-flymake-python-backend ()
  (remove-hook 'flymake-diagnostic-functions #'python-flymake t))
(add-hook 'python-mode-hook #'remove-flymake-python-backend 100)
```
