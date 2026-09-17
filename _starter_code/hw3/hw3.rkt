#lang racket
(require rackunit)

;; Gradescope loads this file as a module. Replace each "not implemented"
;; expression with your solution, but keep the filename, required names,
;; and any given argument lists unchanged.

(provide (all-defined-out))

#| Assignment 3: Environments and Interpreters |#

;; Inverting the adage that a data type is just a simple programming
;; language, we take the position that a programming language is,
;; semantically, just a complex data type; evaluation of a program is
;; just another operation in the data type.
;;
;; -- Mitch Wand

#| ===== Assignment Guidelines ===== |#

;; In addition to the standard Assignment Guidelines
;; (https://hemann.pl/26FA-CS3113/hw/), follow the
;; assignment-specific artifact and review requirements below.
;;
;; Recall that in recent lectures, we've learned how to write an
;; interpreter that takes a Racket expression and returns the
;; expression's value. We have also learned to make this interpreter
;; representation independent with respect to environments, and we
;; have written two different representations of the helpers
;; extend-env, apply-env, and empty-env.
;;
;; In the first part of this assignment you will implement the three
;; interpreters I presented in lecture.

;; For the 2nd and 3rd interpreters you must also define two sets of
;; environment helpers: one that uses functional (higher-order)
;; representation of environments, and one that uses data-structural
;; representation of environments.

;; Your data structure representations should be the tagged list
;; representation demonstrated in class.

;; You must name your interpreters and helpers for each of the first
;; three problems respectively by the following naming
;; conventions. These below names may differ sligtly from the names I
;; used in lecture.
;;
;; Your first three interpreters must all handle the following forms:
;; numbers, booleans, variables, lambda-abstraction, application,
;; zero?, sub1, *, +, if, and let.
;; Addition accepts any number of arguments, as in Racket.

;; In the second part you will implement a fourth interpreter, this
;; time an interpreter for a new language.

;; For this assignment your solutions must be compositional or you
;; will lose credit.  E.g. although we could rewrite the expression
;; (let ([x e]) body) as ((lambda (x) body) e), you must not use
;; lambda in this way for your interpreter's line for let
;; expressions. Instead, you must implement let in its own right.

#| ===== Individual code review ===== |#

;; Assignment 3 has two separately graded items: the submitted artifact
;; and an individual code review lasting about ten minutes. The shared
;; pass, understanding, quality, penalty-unit, and course-pass policy is
;; in the syllabus:
;; https://hemann.pl/26FA-CS3113/syllabus/#assignment-3-and-assignment-9-code-reviews
;;
;; Book a review appointment through the CSAS 3113 code-review booking
;; page: https://hemann.pl/book/csas-3113-code-review/
;;
;; The booking page is the current source for available appointment
;; dates and times.
;;
;; You must pass the Assignment 3 code review no later than Friday,
;; October 9, 2026, at 5:00 p.m. Eastern. Approved accommodations or
;; documented exceptional circumstances may receive the adjusted
;; deadline described in the syllabus.
;;
;; Be prepared to trace and explain your code on the whiteboard from
;; memory. Do not bring or consult a copy of your code.
;;
;; Be prepared to discuss the evaluation rules in your interpreters,
;; compositional treatment of let, functional and data-structural
;; environment representations, the environment interface and
;; representation independence
;;
;; Assignment 3 maps the syllabus's passing quality ratings to points as
;; follows:
;;
;;   Convincing:   4/4
;;   Solid:        3/4
;;   Minimum pass: 2/4
;;
;; Its accumulated penalty units cap a successful review as follows:
;;
;;   Penalty units   Maximum score
;;   0               4/4
;;   1               3/4
;;   2 or more       2/4
;;
;; The recorded score is the lower of the holistic quality score and
;; this cap. The cap floor does not itself establish a pass.

#| ===== Interpreters and environments ===== |#

#|

1. Define value-of, an interpreter whose environment is represented
directly as a Racket function from variable names to values. The
environment argument supplied to value-of is already such a function.

|#

(define (value-of expr env)
  (error 'value-of "not implemented"))

(test-equal?
 "A nearly-sufficient test-case of your program's functionality"
 (value-of
  '(((lambda (f)
       (lambda (n) (if (zero? n) 1 (* n ((f f) (sub1 n))))))
     (lambda (f)
       (lambda (n) (if (zero? n) 1 (* n ((f f) (sub1 n)))))))
    5)
  (lambda (y) (error 'value-of "unbound variable ~a" y)))
 120)

(test-equal?
 "A nearly-sufficient test-case of your program's functionality with addition"
 (value-of
  '(((lambda (f)
       (lambda (n) (if (zero? n) 1 (+ n ((f f) (sub1 n))))))
     (lambda (f)
       (lambda (n) (if (zero? n) 1 (+ n ((f f) (sub1 n)))))))
    5)
  (lambda (y) (error 'value-of "unbound variable ~a" y)))
 16)

#|

2. Define value-of-fn. We walked through the steps of implementing
this in lecture, at least for the basic forms. From a software
engineering point-of-view, you can see this process as follows. In the
above, we hard-coded our implementation of "environment", tightly
coupling the client code (value-of) to the implementation of
environments. Now, we will correct that mistake by engineering an
interface: `apply-env-fn`, `extend-env-fn`, and `empty-env-fn`
collectively make up the interface for environments. By replacing
those hard-coded implementations of environments with calls to these
"help functions" we will construct an interface against which we can
program, correctly separating the client code that uses environment
from the implementation that provides environment across the
interface. This interpreter must use only empty-env-fn, extend-env-fn,
and apply-env-fn to create, extend, and inspect environments.
Implement those three operations with a functional, higher-order
representation of environments.

These helpers collectively form the environment interface. The
interpreter is so to say the client of that interface and must not
depend on the representation behind it.

|#

(define (empty-env-fn)
  (error 'empty-env-fn "not implemented"))

(define (extend-env-fn x a env)
  (error 'extend-env-fn "not implemented"))

(define (apply-env-fn env y)
  (error 'apply-env-fn "not implemented"))

(define (value-of-fn expr env)
  (error 'value-of-fn "not implemented"))


#|

3. Define value-of-ds. We walked through the steps of implementing
this in lecture, at least for the basic forms. We can also see this
step from a software engineering point-of-view as follows. In the
above, we shimmed in an interface to separate our client code that
uses environment and our implementation code that provides
environment, across an interface that is the three functions
`apply-env-fn`, `extend-env-fn`, and `empty-env-fn`. In this step, we
will now demonstrate to ourselves that this was a well-defined
interface, that is, that our interface is not "leaky." We will
re-implement environment, using an entirely different representation
behind-the-scenes. Since our client (the interpreter) is programming
against the interface, though, the client code won't have to change at
all*.

With this switch to a representation of environments as data
structures, we notice another neat thing. We changed our environment
went from a higher-order, functional representation in the last part
of the assignment to now, a first-order data structure
representation. And we can match against our environment like you
would any old data definition.


* Okay, so we're in point of fact changing both the interpreter client
code and the "helper" interface functions from -fn to -ds, but this is
just so that you can have the different versions of this interpreter in
the same file for us to test.

|#

(define (empty-env-ds)
  (error 'empty-env-ds "not implemented"))

(define (extend-env-ds x a env)
  (error 'extend-env-ds "not implemented"))

(define (apply-env-ds env y)
  (error 'apply-env-ds "not implemented"))

(define (value-of-ds expr env)
  (error 'value-of-ds "not implemented"))


#| ===== A new syntax ===== |#

#|

4. Implement an interpreter fo-eulav. Let the below examples guide
you. I only require you to implement those forms I use in those
examples.

|#

(define (fo-eulav expr env)
  (error 'fo-eulav "not implemented"))

(test-equal?
 "Ppa"
 (fo-eulav '(5 (x (x) adbmal)) (lambda (y) (error 'fo-eulav "unbound variable ~s" y)))
 5)
(test-equal?
 "Stnemugra sa Snoitcnuf"
 (fo-eulav '(((x 1bus) (x) adbmal) ((5 f) (f) adbmal)) (lambda (y) (error 'fo-eulav "unbound variable ~s" y)))
 4)
(test-equal?
 "Tcaf"
 (fo-eulav
  '(5
    (((((((n 1bus) (f f)) n *) 1 (n ?orez) fi)
       (n) adbmal)
      (f) adbmal)
     ((((((n 1bus) (f f)) n *) 1 (n ?orez) fi)
       (n) adbmal)
      (f) adbmal)))
  (lambda (y) (error 'fo-eulav "unbound variable ~s" y)))
 120)

(test-equal?
 "Mus"
 (fo-eulav
  '(5
    (((((((n 1bus) (f f)) n +) 1 (n ?orez) fi)
       (n) adbmal)
      (f) adbmal)
     ((((((n 1bus) (f f)) n +) 1 (n ?orez) fi)
       (n) adbmal)
      (f) adbmal)))
  (lambda (y) (error 'fo-eulav "unbound variable ~s" y)))
 16)

#| ===== Lexical addresses ===== |#

;; Consider the following interpreter for a deBruijnized version of
;; the lambda-calculus (i.e. lambda-calculus expressions using lexical
;; addresses addresses instead of variables). Notice this interpreter
;; is representation-independent with respect to environments. There
;; are a few other slight variations in the syntax of the
;; language. These are of no particular consequence.

(define (value-of-lex expr env)
  (match expr
    [`(const ,expr) expr]
    [`(mult ,x1 ,x2) (* (value-of-lex x1 env) (value-of-lex x2 env))]
    [`(plus ,x1 ,x2) (+ (value-of-lex x1 env) (value-of-lex x2 env))]
    [`(zero ,x) (zero? (value-of-lex x env))]
    [`(sub1 ,body) (sub1 (value-of-lex body env))]
    [`(if ,t ,c ,a) (if (value-of-lex t env) (value-of-lex c env) (value-of-lex a env))]
    [`(var ,num) (apply-env-lex env num)]
    [`(lambda ,body) (lambda (a) (value-of-lex body (extend-env-lex a env)))]
    [`(,rator ,rand) ((value-of-lex rator env) (value-of-lex rand env))]))

(define (empty-env-lex)
  '())

#|

5. Without using lambda or the implicit lambda in an "MIT-define",
define apply-env-lex and extend-env-lex. A correct solution is very
short.

|#

(define extend-env-lex "not implemented")

(define apply-env-lex "not implemented")

(test-equal?
 "This test shows we're using a data-structure representation of environments."
 (value-of-lex '((lambda (var 0)) (const 5)) (empty-env-lex))
 5)

#| Just Dessert |#

#|

6. Go back and extend your interpreter value-of to support set! and
begin2, where begin2 is a variant of Racket's begin that takes exactly
two arguments, and set! mutates variables.

|#


;; 7.
;; The lambda calculus can be used to define a representation of
;; natural numbers, called Church numerals, and arithmetic over
;; them. For instance, c5 is the definition of the Church numeral for
;; 5. This is often described as "representing a number by its
;; fold". What they mean by this is: think of any given number not a
;; piece of data, but in terms of "the interface it implements." What
;; does a number *do* for you? It tells you how many times to iterate
;; some behavior.



(define c0 (lambda (s) (lambda (z) z)))
(define c5 (lambda (s) (lambda (z) (s (s (s (s (s z))))))))

(test-equal?
 "Church 5 acts like 5"
 ((c5 add1) 0)
 5)

(test-equal?
 "Church 0 acts like 0"
 ((c0 add1) 0)
 0)

;; The following is a definition for Church plus, which performs
;; addition over Church numerals.

(define c+
  (lambda (m)
    (lambda (n)
      (lambda (s)
        (lambda (z)
          ((m s) ((n s) z)))))))


(define c10 ((c+ c5) c5))

(test-equal?
 "Church addition acts like addition on Church numerals"
 ((c10 add1) 0)
 10)

;; One way to understand the definition of c+ is that it, when
;; provided two Church numerals, returns a function that, when
;; provided a meaning for add1 and a meaning for zero, uses provides
;; to m the meaning for add1 and, instead of the meaning for zero,
;; provides it the meaning for its second argument. m is the sort of
;; thing that will count up m times, so the resulting function is the
;; meaning of m + n.

#|

7. Your task, however, is to implement csub1, Church predecessor. You
should also provide tests. The Church predecessor of Church zero is
zero, as we haven't a notion of negative numbers. This was a difficult
problem, but it's fun, so don't Google it. If you think it might help
though, consider taking a [trip to the
dentist](http://link.springer.com/chapter/10.1007%2FBFb0062850).

|#
