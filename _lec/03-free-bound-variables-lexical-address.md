---
title: "Free and bound variables and lexical address"
date: 2026-09-09
permalink: /lec/free-bound-variables-lexical-address/
published: false
toc: true
toc_sticky: true
---

> **Draft status:** This is an unpublished lecture-note draft. Its explanations
> and examples are still under review.

Variable names do two jobs in source code. A declaration introduces a name,
while a reference uses a name. Lexical scope determines which declaration—if
any—governs each reference. Once that relationship is known, a compiler can
replace bound names with small numeric addresses.

This note develops that analysis as a recursive program over lambda-calculus
syntax.

## Learning objectives

After working through this note, you should be able to:

- distinguish a variable declaration from a variable reference;
- classify a particular reference as free or bound in an expression;
- explain scope and shadowing using the nearest enclosing binder;
- compute free- and bound-occurrence predicates by structural recursion;
- translate bound references to lexical addresses;
- use lexical addresses to recognize alpha-equivalent expressions; and
- state the context invariant maintained by the translation.

## A small language of expressions

We use the untyped lambda calculus as a compact language of binding. It has
exactly three expression forms:

```text
Expression ::= Variable
             | (lambda (Variable) Expression)
             | (Expression Expression)
```

Examples are represented as quoted Racket data:

```racket
'x
'(lambda (x) x)
'((lambda (x) x) y)
```

In `(lambda (x) body)`, `x` is a **declaration** or **binding occurrence**. It
introduces a name whose scope is `body`. Symbols reached as expression leaves
are **reference occurrences**. In this expression:

```racket
'(lambda (x) (x y))
```

the symbol in `(x)` is a declaration, while the `x` and `y` in `(x y)` are
references.

The binding position is not itself a recursive `Expression` position in the
grammar. A syntax traversal records its name and recurs through the body.

## Scope, binding, and shadowing

The **scope** of a lambda declaration is its body. A reference is governed by
the nearest enclosing declaration with the same name.

```racket
'(lambda (x)
   ((lambda (x)
      x)
    x))
```

There are two reference occurrences of `x`:

- the `x` inside the inner lambda refers to the inner declaration;
- the final `x`, outside the inner lambda's body, refers to the outer
  declaration.

The inner declaration **shadows** the outer declaration only within its own
body. Shadowing does not erase or mutate the outer declaration; it makes the
nearer declaration win for references in a smaller region.

This is a static property. We can determine the governing declaration by
examining program text, without evaluating the program.

## Free and bound are properties of occurrences

A reference occurrence is **bound** in an expression when it lies in the scope
of a declaration of the same name. Otherwise, that occurrence is **free** in
the expression.

Consider:

```racket
'((lambda (x) x) x)
```

The first reference to `x` is bound by the lambda. The final reference to `x`
is free. Thus the name `x` occurs both bound and free in the whole expression.
It is imprecise to call the name itself simply “a bound variable” or “a free
variable” without identifying an occurrence or an expression.

Also distinguish “free in this piece of syntax” from “will cause a run-time
error.” A reference can be free in a subexpression while a larger context or
an interpreter environment supplies its value.

## Carrying the enclosing binders

To classify a reference during a top-down traversal, carry a list of the names
bound by enclosing lambdas. Put the nearest binder first:

```text
context ::= list of enclosing binder names, innermost first
```

Entering `(lambda (x) body)` adds `x` to the front of the context before
traversing `body`. At a reference `x`:

- if `x` appears in the context, the occurrence is bound;
- otherwise, the occurrence is free.

Here are executable occurrence predicates:

```racket
(define (in-context? x context)
  (if (memv x context) #t #f))

(define (occurs-free? target expression [context '()])
  (match expression
    [(? symbol? x)
     (and (eqv? x target)
          (not (in-context? x context)))]
    [`(lambda (,(? symbol? parameter)) ,body)
     (occurs-free? target body (cons parameter context))]
    [`(,operator ,operand)
     (or (occurs-free? target operator context)
         (occurs-free? target operand context))]
    [bad-expression
     (error 'occurs-free?
            "not a lambda-calculus expression: ~v"
            bad-expression)]))

(define (occurs-bound? target expression [context '()])
  (match expression
    [(? symbol? x)
     (and (eqv? x target)
          (in-context? x context))]
    [`(lambda (,(? symbol? parameter)) ,body)
     (occurs-bound? target body (cons parameter context))]
    [`(,operator ,operand)
     (or (occurs-bound? target operator context)
         (occurs-bound? target operand context))]
    [bad-expression
     (error 'occurs-bound?
            "not a lambda-calculus expression: ~v"
            bad-expression)]))
```

The application case must inspect both operator and operand. The lambda case
extends the context only for the body.

## Collecting free names

Sometimes we need the set of names with at least one free occurrence rather
than a yes-or-no question about one target. The same context invariant gives
us that analysis:

```racket
(define (free-variables expression [context '()])
  (match expression
    [(? symbol? x)
     (if (in-context? x context) '() (list x))]
    [`(lambda (,(? symbol? parameter)) ,body)
     (free-variables body (cons parameter context))]
    [`(,operator ,operand)
     (remove-duplicates
      (append (free-variables operator context)
              (free-variables operand context)))]
    [bad-expression
     (error 'free-variables
            "not a lambda-calculus expression: ~v"
            bad-expression)]))
```

The order of this result is not semantically important; it represents a set.

## From names to lexical addresses

Names make programs readable, but a bound reference can be identified by how
many enclosing binders we cross to reach its declaration. We use this
zero-based convention:

- address `0` means the nearest enclosing lambda;
- address `1` means one lambda farther out;
- address `2` means two lambdas farther out; and so on.

Free references retain their names. We use explicit tags so a numeric constant
could never be mistaken for an address:

```text
Addressed ::= (free Variable)
            | (bound Natural)
            | (lambda Addressed)
            | (Addressed Addressed)
```

First, find the zero-based position of a name in the context:

```racket
(define (context-position target context)
  (let loop ([names context]
             [position 0])
    (cond
      [(empty? names) #f]
      [(eqv? target (car names)) position]
      [else (loop (cdr names) (add1 position))])))
```

Because the nearest binder is first, the first matching position is exactly
the lexical address. The translation is then grammar-directed:

```racket
(define (lexical-address expression [context '()])
  (match expression
    [(? symbol? x)
     (define position (context-position x context))
     (if (number? position)
         `(bound ,position)
         `(free ,x))]
    [`(lambda (,(? symbol? parameter)) ,body)
     `(lambda ,(lexical-address body (cons parameter context)))]
    [`(,operator ,operand)
     `(,(lexical-address operator context)
       ,(lexical-address operand context))]
    [bad-expression
     (error 'lexical-address
            "not a lambda-calculus expression: ~v"
            bad-expression)]))
```

Binder names disappear from the output. All information needed to reconnect a
bound reference to its declaration remains in its numeric address.

## A complete lexical-address derivation

Translate this expression:

```racket
'(lambda (x)
   (lambda (y)
     (x ((lambda (x) x) y))))
```

At each reference, record the current innermost-first context:

| Reference occurrence | Context | First matching position |
| --- | --- | --- |
| the outer application’s `x` | `(y x)` | `1` |
| the `x` in the innermost lambda | `(x y x)` | `0` |
| the final `y` | `(y x)` | `0` |

Removing binder names and replacing the references gives:

```racket
'(lambda
   (lambda
     ((bound 1)
      ((lambda (bound 0))
       (bound 0)))))
```

The repeated name `x` causes no ambiguity. The innermost reference has address
`0`, so it reaches the new `x` declaration immediately. The earlier reference
has address `1`, so it crosses the `y` binder to reach the outer `x`.

The translation's central invariant is:

> When translating a subexpression, `context` lists exactly its enclosing
> lambda declarations from nearest to farthest. Therefore the first occurrence
> of a name in `context` identifies that reference's governing declaration.

## Alpha-equivalence

Changing a binder's name, together with the references it binds, should not
change the expression's binding structure:

```racket
'(lambda (x) (lambda (y) x))
'(lambda (p) (lambda (q) p))
```

Both translate to:

```racket
'(lambda (lambda (bound 1)))
```

They are **alpha-equivalent**. This expression is different:

```racket
'(lambda (x) (lambda (y) y))
```

because its body becomes `(bound 0)`, not `(bound 1)`.

For this language, with free names preserved, alpha-equivalence can be tested
by comparing lexical-address translations:

```racket
(define (alpha-equivalent? left right)
  (equal? (lexical-address left)
          (lexical-address right)))
```

## One runnable development

```racket
#lang racket

(define (in-context? x context)
  (if (memv x context) #t #f))

(define (occurs-free? target expression [context '()])
  (match expression
    [(? symbol? x)
     (and (eqv? x target)
          (not (in-context? x context)))]
    [`(lambda (,(? symbol? parameter)) ,body)
     (occurs-free? target body (cons parameter context))]
    [`(,operator ,operand)
     (or (occurs-free? target operator context)
         (occurs-free? target operand context))]
    [bad-expression
     (error 'occurs-free? "not an expression: ~v" bad-expression)]))

(define (occurs-bound? target expression [context '()])
  (match expression
    [(? symbol? x)
     (and (eqv? x target)
          (in-context? x context))]
    [`(lambda (,(? symbol? parameter)) ,body)
     (occurs-bound? target body (cons parameter context))]
    [`(,operator ,operand)
     (or (occurs-bound? target operator context)
         (occurs-bound? target operand context))]
    [bad-expression
     (error 'occurs-bound? "not an expression: ~v" bad-expression)]))

(define (free-variables expression [context '()])
  (match expression
    [(? symbol? x)
     (if (in-context? x context) '() (list x))]
    [`(lambda (,(? symbol? parameter)) ,body)
     (free-variables body (cons parameter context))]
    [`(,operator ,operand)
     (remove-duplicates
      (append (free-variables operator context)
              (free-variables operand context)))]
    [bad-expression
     (error 'free-variables "not an expression: ~v" bad-expression)]))

(define (context-position target context)
  (let loop ([names context]
             [position 0])
    (cond
      [(empty? names) #f]
      [(eqv? target (car names)) position]
      [else (loop (cdr names) (add1 position))])))

(define (lexical-address expression [context '()])
  (match expression
    [(? symbol? x)
     (define position (context-position x context))
     (if (number? position)
         `(bound ,position)
         `(free ,x))]
    [`(lambda (,(? symbol? parameter)) ,body)
     `(lambda ,(lexical-address body (cons parameter context)))]
    [`(,operator ,operand)
     `(,(lexical-address operator context)
       ,(lexical-address operand context))]
    [bad-expression
     (error 'lexical-address "not an expression: ~v" bad-expression)]))

(define (alpha-equivalent? left right)
  (equal? (lexical-address left)
          (lexical-address right)))

(module+ test
  (require rackunit)

  (define mixed '((lambda (x) x) x))
  (check-true (occurs-bound? 'x mixed))
  (check-true (occurs-free? 'x mixed))
  (check-equal?
   (free-variables '(lambda (x) ((f x) y)))
   '(f y))
  (check-equal?
   (lexical-address
    '(lambda (x) (lambda (y) (x ((lambda (x) x) y)))))
   '(lambda
      (lambda
        ((bound 1)
         ((lambda (bound 0))
          (bound 0))))))
  (check-true
   (alpha-equivalent?
    '(lambda (x) (lambda (y) x))
    '(lambda (p) (lambda (q) p))))
  (check-false
   (alpha-equivalent?
    '(lambda (x) (lambda (y) x))
    '(lambda (x) (lambda (y) y)))))
```

## The central distinctions

| Concept | Meaning |
| --- | --- |
| Declaration | A binder that introduces a name |
| Reference | An expression occurrence that uses a name |
| Scope | The syntax region governed by a declaration |
| Free occurrence | A reference with no same-named enclosing binder |
| Bound occurrence | A reference governed by a same-named enclosing binder |
| Lexical address | The static distance to that governing binder |

A lexical address records binding structure, not a run-time value and not the
number of procedure calls made during evaluation.

## Supervised practice

For each expression, draw arrows from bound references to declarations before
writing any code.

1. Classify every reference occurrence in
   `'((lambda (x) (x z)) (lambda (z) x))` as free or bound.
2. In `'(lambda (x) ((lambda (x) (x y)) x))`, explain which declaration
   governs each `x` reference.
3. Translate `'(lambda (a) (lambda (b) (b (a c))))` using this note's lexical
   address representation.
4. Invent an alpha-equivalent renaming of that expression and verify that its
   translation is unchanged.
5. Write `bound-variables`, returning the names with at least one bound
   reference occurrence. State whether declaration names with no references
   should appear in your result.
6. Change the context convention so the outermost binder comes first. What
   must change in the address calculation?

## Common mistakes

- **Classifying a name rather than an occurrence.** One name can occur both
  free and bound in one expression.
- **Counting declarations as references.** The parameter in `(lambda (x) e)`
  is a binder; only occurrences reached inside expression positions are
  references.
- **Extending scope outside the body.** A lambda's declaration governs its
  body, not a neighboring operator or operand.
- **Ignoring shadowing.** The nearest same-named binder wins, so context search
  must stop at its first match.
- **Treating every nonmatching name as bound elsewhere.** If no enclosing
  binder matches, that occurrence is free in the expression.
- **Dropping free names from lexical form.** Bound names are recoverable from
  addresses; distinct free names must remain distinguishable.
- **Using run-time call depth as an address.** A lexical address comes from
  static syntactic nesting.

## Summary

- Lambda parameters are declarations; variable expressions are references.
- Lexical scope connects a reference to its nearest same-named enclosing
  declaration.
- A reference with such a declaration is bound; otherwise it is free.
- A traversal can maintain an innermost-first context of enclosing binders.
- A bound reference's position in that context is its lexical address.
- Alpha-equivalent expressions have the same binding structure and therefore
  the same lexical-address representation.

## Self-check questions

1. Which part of `(lambda (x) body)` is the scope of the declaration `x`?
2. Can a name occur both free and bound in one expression? Give the shape of an
   example.
3. Why is the binder context ordered from innermost to outermost?
4. What does address `0` mean under this note's convention?
5. Why do free references retain names in the translated representation?
6. How does shadowing appear in a context that contains the same name twice?
7. Why does lexical-address equality characterize alpha-equivalence here?
