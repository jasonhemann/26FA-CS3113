---
title: "letrec, quasiquote, and match"
date: 2026-09-02
permalink: /lec/letrec-quasiquote-match/
published: false
toc: true
toc_sticky: true
---

> **Draft status:** This is an unpublished lecture-note draft. Its explanations
> and examples are still under review.

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
Use a predicate pattern for an atomic case:

```racket
(match value
  [(? symbol? x) `(the-symbol-is ,x)]
  [_ 'not-a-symbol])
```

The pattern `(? symbol? x)` succeeds only when `symbol?` accepts the input and
binds `x` to that input. The wildcard `_` matches anything without binding a
name.

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
    [(? symbol?)
     0]
    [`(lambda (,(? symbol? _parameter)) ,body)
     (add1 (expression-depth body))]
    [`(,operator ,operand)
     (add1 (max (expression-depth operator)
                (expression-depth operand)))]
    [bad-expression
     (error 'expression-depth
            "not a lambda-calculus expression: ~v"
            bad-expression)]))
```

The error case is not part of the language's grammar. It makes the Racket
function reject malformed input instead of failing later with a mysterious
message.

### Worked derivation

Trace this input:

```racket
(expression-depth
 '(lambda (x)
    ((lambda (y) y) x)))
```

The outer input matches the lambda pattern, so its answer is one plus the
depth of its body:

```text
depth(lambda x. ((lambda y. y) x))
= 1 + depth(((lambda y. y) x))
= 1 + (1 + max(depth(lambda y. y), depth(x)))
= 1 + (1 + max(1 + depth(y), 0))
= 1 + (1 + max(1, 0))
= 3
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
    ['()
     '()]
    [`(,first . ,rest)
     `(,first ,first ,@(stutter rest))]))
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
    [`(,first . ,rest)
     `(,first ,first ,@(stutter rest))]))

(define (expression-depth expression)
  (match expression
    [(? symbol?) 0]
    [`(lambda (,(? symbol? _parameter)) ,body)
     (add1 (expression-depth body))]
    [`(,operator ,operand)
     (add1 (max (expression-depth operator)
                (expression-depth operand)))]
    [bad-expression
     (error 'expression-depth
            "not a lambda-calculus expression: ~v"
            bad-expression)]))

(module+ test
  (require rackunit)

  (check-equal? (factorial 5) 120)
  (check-true (even-natural? 10))
  (check-false (even-natural? 7))
  (check-equal? (stutter '(a b c)) '(a a b b c c))
  (check-equal? (expression-depth 'x) 0)
  (check-equal?
   (expression-depth '(lambda (x) ((lambda (y) y) x)))
   3)
  (check-exn
   #rx"not a lambda-calculus expression"
   (lambda () (expression-depth 17))))
```

## The central distinctions

| Form | Primary job | What is active inside? |
| --- | --- | --- |
| `let` | Introduce nonrecursive local bindings | Names are in scope only in the body |
| `letrec` | Introduce recursive local bindings | Scope includes every RHS and the body; early reads fail |
| quote `'...` | Construct entirely literal data | Nothing is evaluated |
| quasiquote `` `... `` | Construct mostly literal data | Unquoted holes are evaluated |
| `match` | Deconstruct data by shape | Pattern variables receive matched pieces |

Quasiquote in a result expression and quasiquote in a `match` pattern use
similar notation for complementary purposes: one builds a shape, while the
other recognizes a shape and names its parts.

## Supervised practice

Work in pairs and write the result of each match or template before running
Racket.

1. Construct `'(if (zero? n) 0 (sub1 n))` with quasiquote, taking the variable
   name from a Racket binding.
2. Given `pieces` equal to `'((f x) (g y))`, construct
   `'(begin (f x) (g y) done)` using unquote-splicing.
3. Define `last-item` with `match`. Give separate patterns for a one-element
   list and a list with at least two elements.
4. Write `application-count`, which counts only application nodes in a valid
   lambda-calculus expression.
5. Define mutually recursive `even-length?` and `odd-length?` helpers over
   lists inside one `letrec`.
6. For each recursive definition, state the invariant and identify the input
   that becomes structurally smaller.

## Common mistakes

- **Expecting a `let` name to be visible in its own right-hand side.** Its scope
  begins in the body.
- **Using `letrec` to force an already-needed value.** Recursive procedure
  bindings work smoothly because lambda bodies are delayed.
- **Forgetting that quote produces data.** `'(+ 1 2)` is a list, not the number
  `3`.
- **Putting a comma outside quasiquote.** Unquote has meaning only within an
  enclosing quasiquote.
- **Confusing `,x` with `,@x`.** The first inserts one value; the second splices
  the elements of a list.
- **Treating a pattern variable as a literal.** In a quasiquote pattern, `,x`
  binds a piece of the input; the literal symbol `x` must remain quoted in the
  pattern.
- **Writing patterns in the wrong order.** An earlier general pattern can make
  a later specific case unreachable.
- **Recursing on binding positions.** In `(lambda (x) body)`, `body` is the
  recursive expression position; the declaration `x` is a symbol to record,
  not a subexpression to traverse.

## Summary

- `let` introduces local bindings whose names are available in its body.
- `letrec` supports local and mutually recursive procedures.
- Quote constructs wholly literal data; quasiquote permits evaluated holes.
- Unquote-splicing inserts all elements of a computed list.
- `match` makes the structural alternatives in a data definition explicit.
- Grammar-directed programs have one successful pattern for each grammar form
  and recurse only on that form's subexpressions.
- The same quasiquote notation helps us recognize and rebuild symbolic syntax.

## Self-check questions

1. Why does the factorial definition fail under `let` but succeed under
   `letrec`?
2. What does a lambda on the right-hand side of `letrec` delay?
3. What values do quote and quasiquote produce?
4. How do unquote and unquote-splicing differ?
5. What does `(? symbol? x)` test, and what does it bind?
6. Why should a one-element-list pattern precede a general pair pattern?
7. How does the grammar tell us where `expression-depth` should recur?
