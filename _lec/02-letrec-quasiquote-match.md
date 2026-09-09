---
title: "letrec, quasiquote, and match"
order: 2
permalink: /lec/letrec-quasiquote-match/
published: true
toc: true
toc_sticky: true
---

Programming-languages work constantly crosses a boundary between **using**
Racket syntax and **representing** syntax as data. Quasiquote makes symbolic
data convenient to construct, while `match` lets a program take that data
apart according to its shape. `letrec` supplies local recursive definitions
when the program doing that traversal should not introduce a global name.

Together, these three tools form much of the working vocabulary for the
interpreters and program transformations ahead.

## Learning objectives

After working through this note, you should be able to:

- explain the scope difference between `let` and `letrec`;
- use `letrec` for local recursion and mutual recursion;
- distinguish quote, quasiquote, unquote, and unquote-splicing;
- read quasiquote expressions as templates with computed holes;
- use `match` to divide symbolic data into structural cases;
- distinguish a pattern variable from a literal symbol in a pattern; and
- derive a recursive function whose cases mirror a symbolic grammar.

## Local bindings with `let`

A `let` expression evaluates its right-hand sides in the surrounding
environment, binds the resulting values to names, and then evaluates its body
in the extended environment:

```racket
(let ([x (+ 2 3)]
      [y (* 4 5)])
  (+ x y))                 ; => 25
```

For a one-binding `let`, this equivalence exposes the essential idea:

```racket
(let ([x expression])
  body)
```

has the same binding behavior as:

```racket
((lambda (x) body) expression)
```

In particular, `x` is in scope in `body`, not in `expression`. This attempt at
a local factorial therefore fails:

```racket
(let ([factorial
       (lambda (n)
         (if (zero? n)
             1
             (* n (factorial (sub1 n)))))])
  (factorial 5))
```

The occurrence of `factorial` in the lambda body is not bound by this `let`.
Although that body will run later, its lexical environment was established
where the lambda was created.

## Recursive bindings with `letrec`

`letrec` makes every bound name lexically visible in every right-hand-side
expression as well as in its final body:

```racket
(letrec ([factorial
          (lambda (n)
            (if (zero? n)
                1
                (* n (factorial (sub1 n)))))])
  (factorial 5))           ; => 120
```

The locations for those names exist before the right-hand sides are evaluated,
but their values are installed only as those evaluations finish. The usual and
easiest-to-reason-about use of `letrec` therefore binds names to lambdas: making
a lambda delays its body, so the recursive lookup happens after initialization.
Trying to read a `letrec` name immediately from a right-hand side, before its
value has been installed, is an error.

### Mutual recursion

The definitions in one `letrec` can refer to one another:

```racket
(define (even-natural? n)
  (letrec ([even-loop
            (lambda (n)
              (if (zero? n)
                  #t
                  (odd-loop (sub1 n))))]
           [odd-loop
            (lambda (n)
              (if (zero? n)
                  #f
                  (even-loop (sub1 n))))])
    (even-loop n)))
```

The invariant alternates with the calls: `even-loop` answers whether the
current natural number is even, and `odd-loop` answers whether it is odd. Each
call passes a smaller natural number to the other procedure.

## Code versus symbolic data

These two expressions look similar but play different roles:

```racket
(+ 2 3)                    ; Racket applies + and produces 5
'(+ 2 3)                   ; quote produces the list '(+ 2 3)
```

Quote suppresses evaluation of the whole datum. It is convenient when every
piece is literal. When most of a list is literal but selected pieces should be
computed, use **quasiquote**:

```racket
`(+ 2 ,(+ 1 2))            ; => '(+ 2 3)
```

The backtick begins a quasiquoted template. A comma introduces an **unquote**
hole whose expression is evaluated:

```racket
(define name 'x)
(define body '(+ x 1))

`(lambda (,name) ,body)
;; => '(lambda (x) (+ x 1))
```

This constructs data; it does not create or run a Racket procedure.

### Unquote-splicing

Ordinary unquote inserts one value as one item. **Unquote-splicing**, written
`,@`, inserts the elements of a computed list into the surrounding list:

```racket
(define middle '(blue green))

`(red ,middle violet)      ; => '(red (blue green) violet)
`(red ,@middle violet)     ; => '(red blue green violet)
```

The distinction matters whenever generated syntax contains a variable number
of forms.

## Structural cases with `match`

`match` compares a value against patterns from top to bottom. The first
successful pattern determines which result expression runs:

```racket
(define (describe xs)
  (match xs
    ['() 'empty]
    [`(,only) `(one-item ,only)]
    [`(,first . ,rest) `(starts-with ,first and-then ,rest)]))
```

Examples:

```racket
(describe '())            ; => 'empty
(describe '(cat))         ; => '(one-item cat)
(describe '(cat dog owl)) ; => '(starts-with cat and-then (dog owl))
```

In a quasiquote pattern:

- unquoted identifiers such as `first` and `rest` are pattern variables that
  receive pieces of the input;
- quoted or otherwise literal portions must appear exactly as written; and
- the dotted form `(,first . ,rest)` exposes the two fields of a pair.

Pattern order can matter. A general pair pattern would also accept a
one-element list, so the more specific one-element pattern appears first.

### Guarding atomic patterns

Symbolic languages often distinguish atomic symbols from structured lists.
Bind the input with a quasiquote pattern and use a guard for the symbol case:

```racket
(match value
  [`,y #:when (symbol? y) `(the-symbol-is ,y)]
  [_ 'not-a-symbol])
```

The pattern `` `,y `` binds `y` to the input. The guard `#:when (symbol? y)`
allows this clause to succeed only when that input is a symbol. The wildcard
`_` matches anything without binding a name.

## A grammar-directed function

Consider this small grammar for lambda-calculus expressions:

```text
Expression ::= Variable
             | (lambda (Variable) Expression)
             | (Expression Expression)
```

A function over these expressions should have exactly three corresponding
cases. Here is one that measures maximum syntactic nesting:

```racket
(define (expression-depth expression)
  (match expression
    [`,y #:when (symbol? y) 0]
    [`(lambda (,x) ,body) (add1 (expression-depth body))]
    [`(,operator ,operand) (add1 (max (expression-depth operator) (expression-depth operand)))]))
```

Each input is a valid expression from the grammar, so these three clauses
cover the inputs we use.

### Worked derivation

Trace this input:

```racket
(expression-depth '(lambda (x) ((lambda (y) y) x)))
```

The outer input matches the lambda pattern, so its answer is one plus the
depth of its body:

```racket
(expression-depth '(lambda (x) ((lambda (y) y) x)))
;; =>
(add1 (expression-depth '((lambda (y) y) x)))
;; =>
(add1 (add1 (max (expression-depth '(lambda (y) y)) (expression-depth 'x))))
;; =>
(add1 (add1 (max (add1 (expression-depth 'y)) 0)))
;; =>
(add1 (add1 (max 1 0)))
;; =>
3
```

The recursive invariant is:

> Each call receives a valid expression and returns the largest number of
> syntax-tree edges on a path from that expression to one of its leaves.

The `match` clauses expose exactly the subexpressions on which that invariant
can be reused.

## Matching and rebuilding

Program transformations often take syntax apart and construct related syntax.
This list example shows both directions without changing languages:

```racket
(define (stutter xs)
  (match xs
    ['() '()]
    [`(,first . ,rest) `(,first ,first ,@(stutter rest))]))
```

For `(stutter '(a b))`, the recursive development is:

```text
(stutter '(a b))
= `(a a ,@(stutter '(b)))
= `(a a ,@'(b b))
= '(a a b b)
```

The quasiquote after the pattern is a constructor. Its `,@` splices the
already-stuttered tail into the new result.

## One runnable development

```racket
#lang racket

(define factorial
  (letrec ([loop
            (lambda (n)
              (if (zero? n)
                  1
                  (* n (loop (sub1 n)))))])
    loop))

(define (even-natural? n)
  (letrec ([even-loop
            (lambda (n)
              (if (zero? n)
                  #t
                  (odd-loop (sub1 n))))]
           [odd-loop
            (lambda (n)
              (if (zero? n)
                  #f
                  (even-loop (sub1 n))))])
    (even-loop n)))

(define (stutter xs)
  (match xs
    ['() '()]
    [`(,first . ,rest) `(,first ,first ,@(stutter rest))]))

(define (expression-depth expression)
  (match expression
    [`,y #:when (symbol? y) 0]
    [`(lambda (,x) ,body) (add1 (expression-depth body))]
    [`(,operator ,operand) (add1 (max (expression-depth operator) (expression-depth operand)))]))

(module+ test
  (require rackunit)

  (check-equal? (factorial 5) 120)
  (check-true (even-natural? 10))
  (check-false (even-natural? 7))
  (check-equal? (stutter '(a b c)) '(a a b b c c))
  (check-equal? (expression-depth 'x) 0)
  (check-equal?
   (expression-depth '(lambda (x) ((lambda (y) y) x)))
   3))
```

## The central distinctions

Quasiquote in a result expression and quasiquote in a `match` pattern use
similar notation for complementary purposes: one builds a shape, while the
other recognizes a shape and names its parts.
