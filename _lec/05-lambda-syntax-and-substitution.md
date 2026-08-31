---
title: "Lambda syntax and capture-avoiding substitution"
order: 5
permalink: /lec/lambda-syntax-and-substitution/
published: true
toc: true
toc_sticky: true
---

Substitution sounds like textual replacement: replace `x` with another
expression. Binding makes the real operation more careful. We must replace
only free occurrences of `x`, and we must not let a lambda accidentally capture
free variables belonging to the replacement.

Capture-avoiding substitution is the core operation behind beta reduction. It
also gives us a precise way to reason about renaming and variable hygiene in
program transformations.

## Learning objectives

After working through this note, you should be able to:

- recognize the three forms of a lambda-calculus expression;
- distinguish syntax trees from Racket evaluation;
- compute whether a name occurs free in an expression;
- explain why substitution stops beneath a same-named binder;
- identify when substitution would capture a free variable;
- use alpha-renaming to avoid that capture;
- perform one beta contraction by capture-avoiding substitution; and
- state the invariants a correct substitution procedure preserves.

## Lambda-calculus syntax as data

Our language has variables, one-argument lambdas, and one-argument
applications:

```text
Expression ::= Variable
             | (lambda (Variable) Expression)
             | (Expression Expression)
```

We represent an expression with quoted Racket data:

```racket
'x
'(lambda (x) x)
'((lambda (x) x) y)
```

The quotation matters. The third example is a three-level syntax tree supplied
to our program; Racket itself does not apply the represented lambda.

In an application `(operator operand)`, both positions are expressions. In a
lambda `(lambda (x) body)`, only `body` is an expression position. The
parameter `x` is a binder that affects references in `body`.

## Free occurrence as a recursive question

A reference to `target` occurs free in an expression when a traversal can
reach it without passing through a lambda that binds `target`:

```racket
(define (free? target expression)
  (match expression
    [(? symbol? x)
     (eqv? x target)]
    [`(lambda (,(? symbol? parameter)) ,body)
     (and (not (eqv? parameter target))
          (free? target body))]
    [`(,operator ,operand)
     (or (free? target operator)
         (free? target operand))]
    [bad-expression
     (error 'free?
            "not a lambda-calculus expression: ~v"
            bad-expression)]))
```

The lambda clause embodies scope. When `parameter` is the target, that binder
shields its entire body from the surrounding search.

```racket
(free? 'x '(lambda (x) x))       ; => #f
(free? 'x '(lambda (y) x))       ; => #t
(free? 'x '((lambda (x) x) x))   ; => #t
```

The last expression has a bound occurrence of `x` in the operator and a free
occurrence in the operand, so the answer for the whole expression is true.

## What substitution means

Write `[x := replacement] expression` for replacing every occurrence of `x`
that is free in `expression` with `replacement`.

For a variable, there are two cases:

```text
[x := R] x  = R
[x := R] y  = y, when x and y differ
```

For an application, substitute recursively in both pieces:

```text
[x := R] (M N) = ([x := R] M  [x := R] N)
```

The interesting cases arise at lambdas.

### A binder that shields the target

If the lambda itself binds `x`, occurrences of `x` in its body are not free
relative to the whole lambda:

```text
[x := z] (lambda (x) (x y))
= (lambda (x) (x y))
```

Substitution stops at that binder.

### A binder unrelated to the replacement

If the binder is different from `x` and its name is not free in the
replacement, recursion is safe:

```text
[x := z] (lambda (y) (x y))
= (lambda (y) ([x := z] (x y)))
= (lambda (y) (z y))
```

The existing `y` binder cannot capture anything in the replacement `z`.

## The variable-capture problem

Now substitute the free variable `y` for `x`:

```text
[x := y] (lambda (y) x)
```

Naive textual replacement produces:

```racket
'(lambda (y) y)
```

That answer is wrong. The replacement `y` was free before it was inserted, but
the existing lambda now binds it. The transformation has changed what `y`
means; it has **captured** the variable.

A correct substitution preserves the freedom of variables introduced by the
replacement. Before descending under the conflicting lambda, rename its binder
to a name that appears nowhere relevant:

```text
(lambda (y) x)  alpha-renames to  (lambda (fresh) x)
```

Then substitute:

```text
[x := y] (lambda (fresh) x)
= (lambda (fresh) y)
```

The inserted `y` remains free.

## Alpha-renaming

An **alpha-renaming** changes a binder and exactly the references governed by
that binder. It does not change binding structure:

```racket
'(lambda (x) (lambda (z) (x z)))
'(lambda (a) (lambda (b) (a b)))
```

These expressions are alpha-equivalent. But renaming the outer `x` to `z`
without first choosing a fresh name would be unsafe:

```racket
'(lambda (z) (lambda (z) (z z)))
```

The inner `z` now shadows the outer binder, so the binding structure has
changed.

Racket's `gensym` constructs a fresh symbol whose identity differs from every
existing symbol. We can use it when a substitution needs alpha-renaming. Its
printed suffix is deliberately unspecified; the identity, not the spelling,
is what matters.

## Capture-avoiding substitution

The implementation follows the syntax grammar and the cases above:

```racket
(define (substitute replacement target expression)
  (match expression
    [(? symbol? x)
     (if (eqv? x target) replacement x)]

    [`(lambda (,(? symbol? parameter)) ,body)
     (cond
       ;; This binder shields all target occurrences in its body.
       [(eqv? parameter target)
        expression]

       ;; Avoid changing syntax when there is nothing to replace.
       [(not (free? target body))
        expression]

       ;; Descending would capture a free variable in replacement.
       [(free? parameter replacement)
        (define fresh (gensym parameter))
        (define renamed-body
          (substitute fresh parameter body))
        `(lambda (,fresh)
           ,(substitute replacement target renamed-body))]

       ;; The existing binder cannot capture replacement.
       [else
        `(lambda (,parameter)
           ,(substitute replacement target body))])]

    [`(,operator ,operand)
     `(,(substitute replacement target operator)
       ,(substitute replacement target operand))]

    [bad-expression
     (error 'substitute
            "not a lambda-calculus expression: ~v"
            bad-expression)]))
```

In the alpha-renaming branch, substituting `fresh` for `parameter` inside
`body` changes just the references governed by the current lambda. A nested
lambda with the same parameter name shields its own references, exactly as it
should.

## A complete substitution derivation

Consider:

```text
[x := (f y)] (lambda (y) (x (lambda (x) (x y))))
```

The outer parameter `y` occurs free in the replacement `(f y)`, and `x` occurs
free in the outer body. Descending directly would capture the replacement's
`y`, so rename the outer binder to fresh `q`:

```text
(lambda (q) (x (lambda (x) (x q))))
```

Now substitute for the remaining free occurrences of `x`:

```text
[x := (f y)] (lambda (q) (x (lambda (x) (x q))))
= (lambda (q)
    ([x := (f y)] x
     [x := (f y)] (lambda (x) (x q))))
= (lambda (q)
    ((f y)
     (lambda (x) (x q))))
```

The inner lambda binds `x`, so substitution stops beneath it. The inserted `y`
remains free, and the original references governed by the outer `y` binder are
now governed by `q`.

This derivation illustrates three invariants:

1. only free occurrences of the target are replaced;
2. free variables of the replacement remain free after insertion; and
3. unrelated binding relationships are preserved.

## Beta contraction

An application whose operator is a lambda is a **beta redex**:

```racket
'((lambda (x) body) argument)
```

Contracting that redex substitutes the argument expression for free
occurrences of the formal parameter in the body:

```text
((lambda (x) body) argument)
  contracts to
[x := argument] body
```

Here is a function that contracts one redex at the root of an expression:

```racket
(define (beta-contract expression)
  (match expression
    [`((lambda (,(? symbol? parameter)) ,body) ,argument)
     (substitute argument parameter body)]
    [_
     (error 'beta-contract "not a beta redex: ~v" expression)]))
```

For example:

```racket
(beta-contract '((lambda (x) (x z)) (lambda (w) w)))
;; => '((lambda (w) w) z)
```

This function defines one contraction, not a complete evaluation strategy. A
strategy must additionally decide which redex to contract and in what order.

## One runnable development

```racket
#lang racket

(define (free? target expression)
  (match expression
    [(? symbol? x)
     (eqv? x target)]
    [`(lambda (,(? symbol? parameter)) ,body)
     (and (not (eqv? parameter target))
          (free? target body))]
    [`(,operator ,operand)
     (or (free? target operator)
         (free? target operand))]
    [bad-expression
     (error 'free? "not an expression: ~v" bad-expression)]))

(define (substitute replacement target expression)
  (match expression
    [(? symbol? x)
     (if (eqv? x target) replacement x)]
    [`(lambda (,(? symbol? parameter)) ,body)
     (cond
       [(eqv? parameter target)
        expression]
       [(not (free? target body))
        expression]
       [(free? parameter replacement)
        (define fresh (gensym parameter))
        (define renamed-body
          (substitute fresh parameter body))
        `(lambda (,fresh)
           ,(substitute replacement target renamed-body))]
       [else
        `(lambda (,parameter)
           ,(substitute replacement target body))])]
    [`(,operator ,operand)
     `(,(substitute replacement target operator)
       ,(substitute replacement target operand))]
    [bad-expression
     (error 'substitute "not an expression: ~v" bad-expression)]))

(define (beta-contract expression)
  (match expression
    [`((lambda (,(? symbol? parameter)) ,body) ,argument)
     (substitute argument parameter body)]
    [_
     (error 'beta-contract "not a beta redex: ~v" expression)]))

(module+ test
  (require rackunit)

  (check-false (free? 'x '(lambda (x) x)))
  (check-true (free? 'x '((lambda (x) x) x)))
  (check-equal? (substitute 'z 'x '(lambda (y) (x y)))
                '(lambda (y) (z y)))
  (check-equal? (substitute 'z 'x '(lambda (x) (x y)))
                '(lambda (x) (x y)))
  (check-equal?
   (beta-contract '((lambda (x) (x z)) (lambda (w) w)))
   '((lambda (w) w) z))

  ;; The exact fresh name is unspecified, so test its binding structure.
  (define capture-avoiding-result
    (substitute 'y 'x '(lambda (y) (x y))))
  (check-true
   (match capture-avoiding-result
     [`(lambda (,fresh) (y ,use))
      (and (not (eqv? fresh 'y))
           (eqv? fresh use))]
     [_ #f]))
  (check-true (free? 'y capture-avoiding-result)))
```

## The central distinctions

| Concept | What changes? | What must be preserved? |
| --- | --- | --- |
| Alpha-renaming | A binder and its governed references | Binding structure |
| Substitution | Free occurrences of one target | Freedom of inserted variables |
| Beta contraction | One lambda application | Capture-avoiding meaning of substitution |
| Evaluation strategy | Which redex contracts next | The strategy's specified order |

Substitution is a syntax transformation. It does not look up a run-time value,
and contracting one beta redex does not by itself define an evaluator.

## Supervised practice

For each substitution, circle the target's free occurrences and underline any
binder that might capture a variable in the replacement.

1. Compute `[x := z] ((lambda (x) x) (x y))`.
2. Compute `[x := (g y)] (lambda (z) (x z))`.
3. Explain why `[x := z] (lambda (x) (x y))` makes no change.
4. Perform capture-avoiding substitution for
   `[x := y] (lambda (y) (lambda (z) (x z)))` using a fresh name of your
   choice.
5. Find the beta redexes in
   `'((lambda (f) (f a)) ((lambda (x) x) g))`. Do not contract them yet;
   explain why choosing an order is a separate decision.
6. Construct two alpha-equivalent expressions and verify that corresponding
   references still point to corresponding binders after your renaming.

## Common mistakes

- **Performing textual search-and-replace.** Substitution operates on syntax
  with scope, not on character strings.
- **Replacing bound occurrences of the target.** A same-named lambda binder
  shields its body.
- **Checking whether the binder merely occurs in the replacement.** Capture is
  a danger specifically when that binder occurs free in the replacement.
- **Renaming a binder without its references.** Alpha-renaming must preserve
  the declaration-to-reference relationship.
- **Choosing a name already used in the relevant syntax.** A fresh name avoids
  both capture and accidental shadowing.
- **Substituting beneath a target binder before stopping.** That would replace
  occurrences belonging to the wrong declaration.
- **Calling every application a beta redex.** Its operator must syntactically
  be a lambda for `beta-contract` to apply at the root.
- **Confusing contraction with evaluation.** An evaluator still needs a rule
  for selecting and repeatedly contracting redexes.

## Summary

- Lambda-calculus expressions are syntax trees with variables, lambdas, and
  applications.
- Substitution replaces only free occurrences of its target.
- A same-named binder shields its body from substitution.
- A different binder is safe to cross only when it cannot capture a free
  variable from the replacement.
- Alpha-renaming to a fresh name repairs a potential capture.
- Beta contraction is capture-avoiding substitution of an argument into a
  lambda body.
- Correct substitution preserves both the freedom of inserted variables and
  the binding structure of unaffected syntax.

## Self-check questions

1. Why does substitution stop at `(lambda (x) body)` when its target is `x`?
2. Under what two conditions does descending beneath a different binder require
   alpha-renaming?
3. What makes a proposed alpha-renaming unsafe?
4. Why is `(lambda (y) y)` the wrong result for
   `[x := y] (lambda (y) x)`?
5. What guarantee does `gensym` provide that spelling a name such as `temp`
   does not?
6. How does beta contraction use substitution?
7. What additional decision is required to turn beta contraction into an
   evaluation strategy?
