;;; init-lsp.el --- Sets up LSP -*- lexical-binding: t -*-
;;; Commentary:
;;;  Config for LSP
;;; Code:

(use-package lsp-mode
  :diminish
  :commands (lsp-enable-which-key-integration
             lsp-format-buffer
             lsp-organize-imports
             lsp-install-server)
  :custom-face
  (lsp-headerline-breadcrumb-path-error-face
   ((t :underline (:style wave :color ,(face-foreground 'error))
       :inherit lsp-headerline-breadcrumb-path-face)))
  (lsp-headerline-breadcrumb-path-warning-face
   ((t :underline (:style wave :color ,(face-foreground 'warning))
       :inherit lsp-headerline-breadcrumb-path-face)))
  (lsp-headerline-breadcrumb-path-info-face
   ((t :underline (:style wave :color ,(face-foreground 'success))
       :inherit lsp-headerline-breadcrumb-path-face)))
  (lsp-headerline-breadcrumb-path-hint-face
   ((t :underline (:style wave :color ,(face-foreground 'success))
       :inherit lsp-headerline-breadcrumb-path-face)))

  (lsp-headerline-breadcrumb-symbols-error-face
   ((t :inherit lsp-headerline-breadcrumb-symbols-face
       :underline (:style wave :color ,(face-foreground 'error)))))
  (lsp-headerline-breadcrumb-symbols-warning-face
   ((t :inherit lsp-headerline-breadcrumb-symbols-face
       :underline (:style wave :color ,(face-foreground 'warning)))))
  (lsp-headerline-breadcrumb-symbols-info-face
   ((t :inherit lsp-headerline-breadcrumb-symbols-face
       :underline (:style wave :color ,(face-foreground 'success)))))
  (lsp-headerline-breadcrumb-symbols-hint-face
   ((t :inherit lsp-headerline-breadcrumb-symbols-face
       :underline (:style wave :color ,(face-foreground 'success)))))

  :hook ((prog-mode . (lambda ()
                        (unless (derived-mode-p 'emacs-lisp-mode 'lisp-mode)
                          (lsp-deferred))))
         (lsp-mode . (lambda ()
                       ;; Integrate `which-key'
                       (lsp-enable-which-key-integration)

                       ;; Format and organize imports
		       (add-hook 'before-save-hook #'lsp-format-buffer t t)
                       (add-hook 'before-save-hook #'lsp-organize-imports t t))))
  :bind (:map lsp-mode-map
	      ("C-c C-d" . lsp-describe-thing-at-point)
	      ([remap xref-find-definitions] . lsp-find-definition)
	      ([remap xref-find-references] . lsp-find-references))
  :init
  (add-to-list 'exec-path "~/elixir_ls")
  ;; @see https://emacs-lsp.github.io/lsp-mode/page/performance
  (setq read-process-output-max (* 1024 1024)) ;; 1MB

  (setq lsp-keymap-prefix "C-c l"
        lsp-keep-workspace-alive nil
        lsp-signature-auto-activate nil
        lsp-modeline-code-actions-enable nil
        lsp-modeline-diagnostics-enable nil
        lsp-modeline-workspace-status-enable nil

        lsp-enable-file-watchers nil
        lsp-enable-folding t
        lsp-enable-symbol-highlighting t
        lsp-enable-text-document-color nil
	lsp-enable-snippet t

        lsp-enable-indentation t
        lsp-enable-on-type-formatting t)

  :config
  (with-no-warnings
    (defun my-lsp--init-if-visible (func &rest args)
      "Not enabling lsp in `git-timemachine-mode'."
      (unless (bound-and-true-p git-timemachine-mode)
        (apply func args)))
    (advice-add #'lsp--init-if-visible :around #'my-lsp--init-if-visible))

  (defun lsp-update-server ()
    "Update LSP server."
    (interactive)
    ;; Equals to `C-u M-x lsp-install-server'
    (lsp-install-server t)))

(use-package lsp-ui
  :custom-face
  (lsp-ui-sideline-code-action ((t (:inherit warning))))
  :bind (("C-c u" . lsp-ui-imenu)
         :map lsp-ui-mode-map
         ("M-RET" . lsp-ui-sideline-apply-code-actions))
  :hook (lsp-mode . lsp-ui-mode)
  :init (setq lsp-ui-sideline-show-diagnostics nil
              lsp-ui-sideline-ignore-duplicate t
              lsp-ui-doc-position 'at-point
              lsp-ui-doc-border (face-foreground 'font-lock-comment-face)
              lsp-ui-imenu-colors `(,(face-foreground 'font-lock-keyword-face)
                                    ,(face-foreground 'font-lock-string-face)
                                    ,(face-foreground 'font-lock-constant-face)
                                    ,(face-foreground 'font-lock-variable-name-face)))
  :config
  ;; Reset `lsp-ui-doc-background' after loading theme
  (add-hook 'after-load-theme-hook
            (lambda ()
              (setq lsp-ui-doc-border (face-foreground 'font-lock-comment-face))
              (set-face-background 'lsp-ui-doc-background (face-background 'tooltip)))))

(cl-defmacro lsp-org-babel-enable (lang)
  "Support LANG in org source code block."
  (cl-check-type lang stringp)
  (let* ((edit-pre (intern (format "org-babel-edit-prep:%s" lang)))
	 (intern-pre (intern (format "lsp--%s" (symbol-name edit-pre)))))
    `(progn
       (defun ,intern-pre (info)
	 (let ((file-name (->> info caddr (alist-get :file))))
	   (unless file-name
	     (user-error "LSP:: specify `:file' property to enable"))

	   (setq buffer-file-name file-name)
	   (and (fboundp 'lsp-deferred) (lsp-deferred))))

       (if (fboundp ',edit-pre)
	   (advice-add ',edit-pre :after ',intern-pre)
	 (progn
	   (defun ,edit-pre (info)
	     (,intern-pre info))
	   (put ',edit-pre 'function-documentation
		(format "Prepare local buffer environment for org source block (%s)."
			(upcase ,lang))))))))

(defvar org-babel-lang-list
  '("ruby" "js" "css" "sass" "C" "rust" "elixir" "erlang" "haskell"))
(add-to-list 'org-babel-lang-list "shell")
(dolist (lang org-babel-lang-list)
  (eval `(lsp-org-babel-enable ,lang)))

(provide 'init-lsp)
;;; init-lsp ends here
