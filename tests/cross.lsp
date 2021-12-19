;; cross refference

;; dasta ((name1 ref1 ref2 ... refn) (name2 ref1 ref2 ... refn)
(defglobal functions nil)
(defglobal globalvars nil)
(defglobal dynamicvars nil)

(defun cross (fn)
    (let ((instream (open-input-file fn))
          (sexp nil))
        (while (setq sexp (read instream nil nil))
            (analize sexp))
        (close instream))
        (format (standard-output) "---Function---~%")
        (display (reverse functions))
        (format (standard-output) "---Global-var---~%")
        (display (reverse globalvars))
        (format (standard-output) "---Dynamic-var---~%")
        (display (reverse dynamicvars))
        t)

(defun display (x)
    (cond ((null x ) t)
          (t (format (standard-output) "~A~%" (car x))
             (display (cdr x)))))


(defun analize (x)
    (cond ((eq (car x) 'defun) (reg-fun (elt x 1)) (analize-defun (cdr (cdr (cdr x))) (elt x 1)))
          ((eq (car x) 'defglobal) (reg-global (elt x 1)))
          ((eq (car x) 'defdynamic) (reg-dynamic (elt x 1)))))


(defun analize-defun (x fun)
    (cond ((null x) t)
          (t (analize-sexp (car x) fun) (analize-defun (cdr x) fun))))


(defun analize-sexp (x fun)
    (cond ((null x) t)
          ((and (atom x) (assoc x globalvars))
           (add-global-ref fun x) (add-fun-ref x fun))
          ((and (atom x) (assoc x dynamicvars)) 
           (add-dynamic-ref fun x) (add-fun-ref x fun))
          ((atom x) t)
          ((subrp (car x)) (analize-args (cdr x) fun))
          ((eq (car x) 'if) (analize-if (cdr x) fun))
          ((eq (car x) 'cond) (analize-cond (cdr x) fun))
          ((eq (car x) 'let) (analize-let (cdr x) fun))
          ((eq (car x) 'let*) (analize-let (cdr x) fun))
          ((eq (car x) 'quote) t)
          ((eq (car x) 'setq) (analize-sexp (elt x 2) fun))
          ((eq (car x) 'while) (analize-sexp (elt x 1) fun) (analize-progn (cdr (cdr x)) fun))
          ((eq (car x) 'or) (analize-args (cdr x) fun))
          ((eq (car x) 'and) (analize-args (cdr x) fun))
          (t (add-fun-ref (car x) fun) (analize-args (cdr x) fun))))

(defun analize-if (x fun)
    (cond ((= (length x) 3)
           (analize-sexp (elt x 0) fun) (analize-sexp (elt x 1) fun) (analize-sexp (elt x 2) fun))
          (t (analize-sexp (elt x 0) fun) (analize-sexp (elt x 1) fun))))


(defun analize-cond (x fun)
    (cond ((null x) t)
          (t (analize-args (car x) fun) (analize-cond (cdr x) fun))))


(defun analize-let (x fun)
    (analize-cond (elt x 0) fun)
    (analize-progn (cdr x) fun))


(defun analize-progn (x fun)
    (cond ((null x) t)
          (t (analize-sexp (car x) fun)
             (analize-progn (cdr x) fun))))


(defun analize-args (x fun)
    (cond ((null x) t)
          (t (analize-sexp (car x) fun) (analize-args (cdr x) fun))))

(defun reg-fun (x)
    (if (member x functions)
        t
        (setq functions (cons (cons x nil) functions))))

(defun reg-fun1 (x y)
    (setq functions (cons (list x y) functions)))


(defun reg-global (x)
    (if (member x globalvars)
        t 
        (setq globalvars (cons (cons x nil) globalvars))))

(defun reg-dynamic (x)
    (if (member x dynamicvars)
        t 
        (setq dynamicvars (cons (cons x nil) dynamicvars))))


(defun add-fun-ref (x fun)
    (let ((dt (assoc fun functions)))
        (cond ((null dt) (reg-fun1 fun x))
              ((member x dt) t)
              (t (add-ref dt x)))))


(defun add-ref (dt x)
    (cond ((null (cdr dt)) (set-cdr (list x) dt))
          (t (add-ref (cdr dt) x))))


(defun add-global-ref (x var)
    (let ((dt (assoc var globalvars)))
        (cond ((member x dt) t)
              (t (add-ref dt x)))))


(defun add-dynamic-ref (x var)
    (let ((dt (assoc var globalvars)))
        (cond ((member x dt) t)
              (t (add-ref dt x)))))
