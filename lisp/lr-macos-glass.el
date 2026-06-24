;;; lr-macos-glass.el --- Ghostty-like macOS glass frame -*- lexical-binding: t; -*-

(when (eq system-type 'darwin)
  (defvar salih/ns-transparent-titlebar t)
  (defvar salih/glass-style 'macos-glass-regular)
  (defvar salih/alpha-background 0.01)
  (defvar salih/ns-background-blur 0)
  (defvar salih/ns-alpha-elements '(ns-alpha-all))
  (defvar salih/ns-glass-material 'regular)
  (defvar salih/ns-glass-tint-opacity 0.05)
  (defvar salih/ns-glass-saturation 1.4)
  (defvar salih/ns-glass-inactive-opacity 0.05)
  (defvar salih/ns-glass-corner-radius 2)
  (defvar salih/glass-fallback-alpha-background 0.70)
  (defvar salih/glass-fallback-background-blur 30)

  (defconst salih/glass-presets
    '((macos-glass-regular
       :material regular
       :alpha 0.01
       :blur 0
       :tint-opacity 0.05
       :saturation 1.4
       :inactive-opacity 0.05
       :corner-radius 2
       :fallback-alpha 0.70
       :fallback-blur 30)
      (macos-glass-clear
       :material clear
       :alpha 0.01
       :blur 0
       :tint-opacity 0.01
       :saturation 1.2
       :inactive-opacity nil
       :corner-radius 0
       :fallback-alpha 0.58
       :fallback-blur 40)))

  (defun salih/--plist-get (plist prop)
    (cadr (memq prop plist)))

  (defun salih/--glass-preset (style)
    (or (alist-get style salih/glass-presets)
        (user-error "Unknown glass style: %s" style)))

  (defun salih/--apply-glass-style-values (style)
    (let ((preset (salih/--glass-preset style)))
      (setq salih/glass-style style
            salih/ns-glass-material (salih/--plist-get preset :material)
            salih/alpha-background (salih/--plist-get preset :alpha)
            salih/ns-background-blur (salih/--plist-get preset :blur)
            salih/ns-alpha-elements '(ns-alpha-all)
            salih/ns-glass-tint-opacity (salih/--plist-get preset :tint-opacity)
            salih/ns-glass-saturation (salih/--plist-get preset :saturation)
            salih/ns-glass-inactive-opacity
            (salih/--plist-get preset :inactive-opacity)
            salih/ns-glass-corner-radius (salih/--plist-get preset :corner-radius)
            salih/glass-fallback-alpha-background
            (salih/--plist-get preset :fallback-alpha)
            salih/glass-fallback-background-blur
            (salih/--plist-get preset :fallback-blur))))

  (defun salih/--emacs-binary-has-string-p (needle)
    (let ((binary (or (car command-line-args)
                      (expand-file-name invocation-name invocation-directory))))
      (and binary
           (file-executable-p binary)
           (executable-find "strings")
           (with-temp-buffer
             (and (zerop (call-process "strings" nil t nil binary))
                  (progn
                    (goto-char (point-min))
                    (search-forward needle nil t)))))))

  (defun salih/--native-glass-build-p ()
    (salih/--emacs-binary-has-string-p "ns-glass-material"))

  (defun salih/--effective-alpha-background ()
    (if (salih/--native-glass-build-p)
        salih/alpha-background
      salih/glass-fallback-alpha-background))

  (defun salih/--effective-background-blur ()
    (if (salih/--native-glass-build-p)
        salih/ns-background-blur
      salih/glass-fallback-background-blur))

  (defun salih/--native-glass-frame-parameters ()
    (when (salih/--native-glass-build-p)
      `((ns-glass-material . ,salih/ns-glass-material)
        (ns-glass-tint-opacity . ,salih/ns-glass-tint-opacity)
        (ns-glass-saturation . ,salih/ns-glass-saturation)
        (ns-glass-inactive-opacity . ,salih/ns-glass-inactive-opacity)
        (ns-glass-corner-radius . ,salih/ns-glass-corner-radius))))

  (defun salih/--glass-frame-parameters ()
    (append
     `((ns-transparent-titlebar . ,salih/ns-transparent-titlebar)
       (alpha-background . ,(salih/--effective-alpha-background))
       (ns-background-blur . ,(salih/--effective-background-blur))
       (ns-alpha-elements . ,salih/ns-alpha-elements))
     (salih/--native-glass-frame-parameters)))

  (defun salih/--apply-glass (&optional frame)
    (with-selected-frame (or frame (selected-frame))
      (dolist (parameter (salih/--glass-frame-parameters))
        (set-frame-parameter nil (car parameter) (cdr parameter)))))

  (defun salih/set-glass-style (style)
    (interactive
     (list (intern
            (completing-read
             "Glass style: "
             (mapcar (lambda (preset) (symbol-name (car preset)))
                     salih/glass-presets)
             nil t nil nil (symbol-name salih/glass-style)))))
    (salih/--apply-glass-style-values style)
    (modify-all-frames-parameters (salih/--glass-frame-parameters)))

  (salih/--apply-glass-style-values salih/glass-style)
  (dolist (parameter (salih/--glass-frame-parameters))
    (add-to-list 'default-frame-alist parameter))
  (add-hook 'after-make-frame-functions #'salih/--apply-glass)
  (unless (daemonp)
    (add-hook 'window-setup-hook #'salih/--apply-glass))
  (when (display-graphic-p)
    (salih/--apply-glass)))

(provide 'lr-macos-glass)
