(require 'ert)
(require 'cl)
(require 'namespaces)


(defmacro check (desc &rest body)
  "Wrap ert-deftest with a simpler interface for testing namespaces."
  (declare (indent 1))
  `(ert-deftest
       ,(intern (replace-regexp-in-string "[ .]" "-" desc)) ()
     ;; Rebind namespace-private tables for tests.
     (let ((__ns/hashes->symbols-table (copy-hash-table __ns/hashes->symbols-table))
           (__ns/symbols->hashes-table (copy-hash-table __ns/symbols->hashes-table))
           (__ns/exports-table         (copy-hash-table __ns/exports-table)))
       (@using test ,@body))))


;;; namespace

(check "namespace declaration should update current namespace"
  (namespace foo)
  (should (equal 'foo *ns*)))


;;; @using

(check "@using should rebind the current namespace"
  (@using foo (should (equal 'foo *ns*))))


(check "@using should reset *ns* on exit"
  (@using foo nil)
  (should (equal 'test *ns*)))


;;; @sym

(check "@sym should return the underlying symbol for a namespaced symbol"
  (def x)
  (should (string-prefix-p "__ns/namespaced_sym" (symbol-name (@sym x)))))


(check "@sym should return nil when underlying symbol does not exist"
  (should-not (@sym undefined)))


;;; def, @

(check "should be able to define and read namespaced var"
  (def var 'expected)
  (should (equal 'expected (@ var))))


(check "should be able to set namespaced var"
  (def var)
  (@set var 'expected)
  (should (equal 'expected (@ var))))


(check "should get error when getting the value of an undefined var"
  (should-error (eval `(@ fail))))


;;; defn, @call

(check "should be able to define and call namespaced fn"
  (defn x () 'expected)
  (should (equal 'expected (@call x))))


(check "defn should tolerate body form in docstring position"
  (defn x () "expected")
  (should (equal "expected" (@call x))))


(check "defn should be callable with arguments"
  (defn sqr (i) (* i i))
  (should (equal 9 (@call sqr 3))))


(check "should get error when calling an undefined fn"
  (should-error (eval `(@call fail))))


;;; Encapsulation

(check "should get error when accessing another namespace's private var using unqualified symbol"
  (def private)
  (namespace foo)
  (should-error (eval `(@ private))))


(check "should get error when accessing another namespace's private var using qualified symbol"
  (namespace foo)
  (def private)
  (namespace bar)
  (should-error (eval `(@ foo/private))))


(check "should get error when accessing another namespace's private fn using unqualified symbol"
  (defn private ())
  (namespace foo)
  (should-error (eval `(@call private))))


(check "should get error when accessing another namespace's private fn using qualified symbol"
  (namespace foo)
  (defn private ())
  (namespace bar)
  (should-error (eval `(@call foo/private))))


(check "should get error when accessing unimported public var using unqualified symbol"
  (namespace foo :export [ public ])
  (def public)
  (namespace bar)
  (should-error (eval `(@ public))))


(check "should get error when setting unimported public var using unqualified symbol"
  (namespace foo :export [ public ])
  (def public)
  (namespace bar)
  (should-error (eval `(@set public nil))))


(check "should get error when calling unimported public fn using unqualified symbol"
  (namespace foo :export [ public ])
  (defn public ())
  (namespace bar)
  (should-error (eval `(@call public))))


;;; Import/Export

(check "should be able to access imported public var using unqualified symbol"
  (namespace foo :export [ public ])
  (def public 'expected)
  (namespace bar :import [ foo ] )
  (should (equal 'expected (@ public))))


(check "should be able to set imported public var using unqualified symbol"
  (namespace foo :export [ public ])
  (def public nil)
  (namespace bar :import [ foo ])
  (@set public 'expected)
  (should (equal 'expected (@ public))))


(check "should be able to access public var using qualified symbol"
  (namespace foo :export [ public ])
  (def public 'expected)
  (namespace bar)
  (should (equal 'expected (eval `(@ foo/public)))))


(check "should be able to set public var using qualified symbol"
  (namespace foo :export [ public ])
  (def public nil)
  (namespace bar)
  (@set foo/public 'expected)
  (should (equal 'expected (@ foo/public))))


(check "should be able to call imported public fn using unqualified symbol"
  (namespace foo :export [ public ])
  (defn public () 'expected)
  (namespace bar :import [ foo ])
  (should (equal 'expected (@call public))))


(check "should be able to call public fn using qualified symbol"
  (namespace foo :export [ public ])
  (defn public () 'expected)
  (namespace bar)
  (should (equal 'expected (@call foo/public))))


;; Local Variables:
;; no-byte-compile: t
;; End: