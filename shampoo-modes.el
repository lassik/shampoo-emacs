;;; shampoo-modes.el --- Shampoo Emacs major modes
;;
;; Copyright (C) 2010 - 2012 Dmitry Matveev <me@dmitrymatveev.co.uk>
;;
;; This software is released under terms of the MIT license,
;; please refer to the LICENSE file for details.

(require 'cl)
(require 'shampoo-state)

(define-derived-mode shampoo-working-mode
  text-mode "Shampoo mode for the working buffer"
  (make-local-variable 'buflocal-fsm))

(define-derived-mode shampoo-list-mode
  text-mode "Shampoo generic mode for list buffers"
  (setq buffer-read-only t)
  (make-local-variable 'set-current-item)
  (make-local-variable 'produce-request)
  (make-local-variable 'pre-insert-hook)
  (make-local-variable 'dependent-buffer)
  (make-local-variable 'update-source-buffer)
  (make-local-variable 'force-update-buffer)
  (make-local-variable 'code-compile)
  (setq force-update-buffer nil
        code-compile 'shampoo-compile-method))

(defun shampoo-update-current-side ()
  (save-excursion
    (set-buffer (get-buffer "*shampoo-categories*"))
    (setq header-line-format
          (format "%s side" (shampoo-side)))))

(defun shampoo-open-from-list ()
  (interactive)
  (let ((this-line (shampoo-this-line)))
    (when (not (equal this-line ""))
      (when (boundp 'set-current-item)
        (funcall set-current-item this-line))
      (shampoo-send-message
       (funcall produce-request this-line)))))

(defun shampoo-toggle-side ()
  (interactive)
  (with-~shampoo~
   (let ((current-side (shampoo-current-side ~shampoo~)))
     (setf (shampoo-current-side ~shampo~)
           (if (eq current-side :instance) :class :instance))))
  (shampoo-update-current-side)
  (save-excursion
    (set-buffer (get-buffer "*shampoo-classes*"))
    (shampoo-send-message
     (funcall produce-request (shampoo-this-line)))
    (funcall update-source-buffer)))

(defun shampoo-clear-buffer-with-dependent ()
  (let ((buffer-read-only nil))
    (erase-buffer)
    (when (boundp 'depd-buffer)
      (shampoo-clear-buffer-by-name-with-dependent depd-buffer))))

(defun shampoo-clear-buffer-by-name-with-dependent (buffer-name)
  (save-excursion
    (set-buffer (get-buffer buffer-name))
    (shampoo-clear-buffer-with-dependent)))

(defun shampoo-list-on-select ()
  (interactive)
  (setq *shampoo-code-compile* code-compile)
  (when (boundp 'dependent-buffer)
    (shampoo-open-from-list))
  (when (boundp 'update-source-buffer)
    (funcall update-source-buffer)))

(define-key shampoo-list-mode-map [return]   'shampoo-list-on-select)
(define-key shampoo-list-mode-map "\C-c\C-t" 'shampoo-toggle-side)

(defun shampoo-namespaces-set-current-item (item)
  (with-~shampoo~
   (setf (shampoo-current-namespace ~shampoo~) item)))

(defun shampoo-namespaces-produce-request (item)
  (shampoo-make-classes-rq :id 1 :ns item))

(defun shampoo-namespaces-update-source-buffer ()
  (let ((attrs (make-hash-table)))
    (puthash 'superclass "Object" attrs)
    (puthash 'class "NameOfSubclass" attrs)
    (shampoo-handle-class-response
     (make-shampoo-response :attrs attrs :data '()))))

(define-derived-mode shampoo-namespaces-list-mode
  shampoo-list-mode "Shampoo namespaces"
  (setq set-current-item     'shampoo-namespaces-set-current-item
        produce-request      'shampoo-namespaces-produce-request
        dependent-buffer     "*shampoo-classes*"
        force-update-buffer  t
        update-source-buffer 'shampoo-namespaces-update-source-buffer
        code-compile         'shampoo-compile-class))

(defun shampoo-classes-set-current-item (item)
  (with-~shampoo~
   (setf (shampoo-current-class ~shampoo~) item)))

(defun shampoo-classes-produce-request (item)
  (shampoo-make-cats-rq
   :id 1
   :ns (shampoo-get-current-namespace)
   :class item
   :side (shampoo-side)))

(defun shampoo-classes-update-source-buffer ()
  (shampoo-send-message
   (shampoo-make-class-rq
    :id 1
    :ns (shampoo-get-current-namespace)
    :class (shampoo-get-current-class)
    :side (shampoo-side))))

(define-derived-mode shampoo-classes-list-mode
  shampoo-list-mode "Shampoo classes"
  (setq set-current-item     'shampoo-classes-set-current-item
        produce-request      'shampoo-classes-produce-request
        dependent-buffer     "*shampoo-categories*"
        update-source-buffer 'shampoo-classes-update-source-buffer
        code-compile         'shampoo-compile-class))

(defun shampoo-cats-produce-request (item)
  (shampoo-make-methods-rq
   :id 1
   :ns (shampoo-get-current-namespace)
   :class (shampoo-get-current-class)
   :category item
   :side (shampoo-side)))

(defun shampoo-cats-update-source-buffer ()
  (save-excursion
    (set-buffer (get-buffer "*shampoo-code*"))
    (setq header-line-format (shampoo-make-header))
    (erase-buffer)
    (with-~shampoo~
     (insert
      (shampoo-dialect-specific-message-template
       (shampoo-current-smalltalk ~shampoo~))))))

(defun shampoo-cats-pre-insert-hook ()
  (insert "*")
  (newline))

(define-derived-mode shampoo-cats-list-mode
  shampoo-list-mode "Shampoo categories"
  (setq produce-request      'shampoo-cats-produce-request
        dependent-buffer     "*shampoo-methods*"
        update-source-buffer 'shampoo-cats-update-source-buffer
        pre-insert-hook      'shampoo-cats-pre-insert-hook))

(defun shampoo-methods-set-current-item (item)
  (with-~shampoo~
   (setf (shampoo-current-method ~shampoo~) item)))

(defun shampoo-methods-produce-request (item)
  (shampoo-make-method-rq
   :id 1
   :ns (shampoo-get-current-namespace)
   :class (shampoo-get-current-class)
   :method item
   :side (shampoo-side)))

(define-derived-mode shampoo-methods-list-mode
  shampoo-list-mode "Shampoo methods"
  (setq set-current-item 'shampoo-methods-set-current-item
        produce-request  'shampoo-methods-produce-request
        update-source-buffer 'shampoo-open-from-list))

(defun shampoo-open-from-buffer-helper (buffer-name)
  (when buffer-name
    (save-excursion
      (set-buffer (get-buffer buffer-name))
      (lambda (a b) (funcall 'produce-request)))))

(define-derived-mode shampoo-code-mode
  text-mode "Shampoo code")

(defun shampoo-compile-code ()
  (interactive)
  (when *shampoo-code-compile*
    (funcall *shampoo-code-compile*)))

(define-key shampoo-code-mode-map "\C-c\C-c" 'shampoo-compile-code)
(define-key shampoo-code-mode-map "\C-c\C-t" 'shampoo-toggle-side)

(provide 'shampoo-modes)

;;; shampoo-modes.el ends here.
