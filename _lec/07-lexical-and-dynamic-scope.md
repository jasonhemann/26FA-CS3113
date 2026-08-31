---
title: "Lexical and dynamic scope"
date: 2026-09-23
permalink: /lec/lexical-and-dynamic-scope/
published: false
toc: true
toc_sticky: true
---

> **Draft status:** This is an unpublished lecture-note draft. Its explanations
> and examples are still under review.

When a program contains a variable reference, which declaration gives that
reference its value? A language's **scope rule** answers that question. Two
languages can accept exactly the same program text yet give it different
results because they use different scope rules.

This note contrasts two answers:

- **lexical scope** follows the program's textual nesting; and
- **dynamic scope** follows the active chain of procedure calls.

The contrast will also show why a lexical closure must save its definition-site
environment.

## Learning objectives

After working through this note, you should be able to:

- distinguish a variable declaration from a variable reference;
- determine which declaration binds a reference under lexical scope;
- trace lookup under dynamic scope using the active call chain;
- identify the one interpreter choice that separates the two semantics;
- explain why lexical scope supports local reasoning and alpha-renaming;
- construct a program that distinguishes lexical and dynamic scope; and
- distinguish accidental dynamic scope from an explicit dynamically scoped
  parameter.

## Declarations, references, and scope

In this expression, the `x` in the parameter list is a declaration and the `x`
in the body is a reference:

```racket
(lambda (x)
  (* x 2))
```

The **scope** of a declaration is the region of program text in which that
declaration may bind references. A nearer declaration with the same name
shadows an outer one:

```racket
(lambda (x)
  ((lambda (x)
     (* x x))
   5))
```

Both references in `(* x x)` belong to the inner declaration. The outer
declaration is still in the program, but it is shadowed within the inner
lambda's body.

The phrase "a variable is bound" can hide two distinct facts:

1. a reference is associated with a particular declaration; and
2. at run time, that declaration has a particular value.

Scope determines the first association. Evaluation and environments provide
the second.

## Lexical scope

Under lexical scope, a reference is bound by the nearest enclosing declaration
with the same name in the program text. "Lexical" points to the written form of
the program; **static scope** is another name for the same idea.

Consider:

```racket
((lambda (a)
   ((lambda (f)
      ((lambda (a)
         (f 0))
       2))
    (lambda (ignored)
      a)))
 1)
```

The `a` in `(lambda (ignored) a)` is textually inside the outer `(lambda (a)
...)`, not the later inner `(lambda (a) ...)`. Lexical analysis can therefore
associate that reference with the outer declaration before the program runs.

At run time:

1. the outer application binds `a` to `1`;
2. evaluating `(lambda (ignored) a)` creates a closure that saves the
   environment containing `a = 1`;
3. the call site temporarily binds another `a` to `2`; and
4. applying `f` evaluates its body in its saved environment, so lookup returns
   `1`.

The lexical-scope invariant is:

> A closure evaluates its body in an extension of the environment saved when
> the lambda was evaluated.

The caller supplies the argument value, but not the non-local environment.

## Dynamic scope

Under dynamic scope, a variable reference uses the most recent active binding
with the requested name. "Active" means that the call which created the
binding has begun but has not yet returned.

Run the same program dynamically:

1. the outer application creates the active binding `a = 1`;
2. the procedure assigned to `f` saves its parameter and body, but not the
   current environment;
3. the inner application creates a newer active binding `a = 2`; and
4. `f` is called while that binding is active, so its reference to `a` finds
   `2`.

The dynamic-scope invariant is:

> A procedure evaluates its body in an extension of the caller's current
> environment.

Dynamic scope is therefore not "no scope." It is a different rule for choosing
the environment used by a procedure body.

## The same syntax, two evaluators

The following executable example makes the semantic difference explicit. Both
evaluators use the same expression grammar and the same environment
representation. They differ only in what a procedure value saves and which
environment application extends.

```racket
#lang racket

(struct empty-environment () #:transparent)
(struct environment-extension (name value rest) #:transparent)

(define (apply-env env query)
  (match env
    [(empty-environment)
     (error 'value-of "unbound variable: ~a" query)]
    [(environment-extension name value rest)
     (if (eqv? query name)
         value
         (apply-env rest query))]))

(struct lexical-closure (name body saved-env) #:transparent)
(struct dynamic-procedure (name body) #:transparent)

(define (lexical-value-of expr env)
  (match expr
    [(? number? n)
     n]

    [(? symbol? name)
     (apply-env env name)]

    [`(* ,e1 ,e2)
     (* (lexical-value-of e1 env)
        (lexical-value-of e2 env))]

    [`(lambda (,(? symbol? name)) ,body)
     ;; A lexical closure saves the definition-site environment.
     (lexical-closure name body env)]

    [`(,operator ,operand)
     (match-define
       (lexical-closure name body saved-env)
       (lexical-value-of operator env))
     (define argument
       (lexical-value-of operand env))
     (lexical-value-of
      body
      (environment-extension name argument saved-env))]

    [bad-expression
     (error 'lexical-value-of "bad expression: ~v" bad-expression)]))

(define (dynamic-value-of expr env)
  (match expr
    [(? number? n)
     n]

    [(? symbol? name)
     (apply-env env name)]

    [`(* ,e1 ,e2)
     (* (dynamic-value-of e1 env)
        (dynamic-value-of e2 env))]

    [`(lambda (,(? symbol? name)) ,body)
     ;; A dynamically scoped procedure does not save an environment.
     (dynamic-procedure name body)]

    [`(,operator ,operand)
     (match-define
       (dynamic-procedure name body)
       (dynamic-value-of operator env))
     (define argument
       (dynamic-value-of operand env))
     (dynamic-value-of
      body
      ;; Dynamic scope extends the caller's environment.
      (environment-extension name argument env))]

    [bad-expression
     (error 'dynamic-value-of "bad expression: ~v" bad-expression)]))

(define distinguishing-program
  '((lambda (a)
      ((lambda (f)
         ((lambda (a)
            (f 0))
          2))
       (lambda (ignored)
         a)))
    1))

(module+ test
  (require rackunit)

  (define empty (empty-environment))

  (check-equal?
   (lexical-value-of distinguishing-program empty)
   1)

  (check-equal?
   (dynamic-value-of distinguishing-program empty)
   2)

  ;; A closed program with no non-local reference cannot distinguish the
  ;; rules. Both evaluators return 36.
  (define non-distinguishing-program
    '((lambda (x)
        (* x x))
      6))

  (check-equal?
   (lexical-value-of non-distinguishing-program empty)
   36)

  (check-equal?
   (dynamic-value-of non-distinguishing-program empty)
   36)

  ;; Rename a call-site binder that its written body does not use.
  (define renamed-call-site
    '((lambda (a)
        ((lambda (f)
           ((lambda (b)
              (f 0))
            2))
         (lambda (ignored)
           a)))
      1))

  ;; Lexical meaning is unchanged by this valid alpha-renaming.
  (check-equal?
   (lexical-value-of renamed-call-site empty)
   1)

  ;; Under dynamic scope, the renamed binder no longer captures the lookup.
  (check-equal?
   (dynamic-value-of renamed-call-site empty)
   1))
```

The lexical application clause extends `saved-env`. The dynamic application
clause extends `env`, the caller's environment. That one change accounts for
the different answers.

## A complete lookup comparison

Immediately before `(f 0)` in `distinguishing-program`, the dynamic caller's
environment has this shape:

```text
[a -> 2] [f -> procedure] [a -> 1] empty
```

After binding `ignored` to `0`, dynamic lookup for `a` follows:

```text
[ignored -> 0] [a -> 2] ...
                    ^ first matching active binding
```

The lexical closure for `f`, however, saved an earlier branch:

```text
[f's definition site] [a -> 1] empty
```

Applying `f` extends that saved branch:

```text
[ignored -> 0] [a -> 1] empty
                    ^ lexical binding
```

The environment under lexical scope is better pictured as a persistent,
branching structure than as one mutable stack. Different closures can retain
different older branches after control has moved elsewhere.

## Why lexical scope supports local reasoning

Lexical scope provides several important properties.

### Binding can be determined from the program text

We can associate every bound reference with its declaration without predicting
the run-time call sequence. Tools such as compilers, refactoring systems, and
editors rely on this fact.

### Alpha-renaming preserves meaning

Renaming a declaration and precisely the references it binds should not change
a program. In the example, changing a call-site parameter from `a` to `b` is a
valid alpha-renaming because its body contains no reference bound by that
parameter. The lexically scoped result remains `1`.

Under dynamic scope, that seemingly irrelevant name change removes a binding
from the run-time search path. The result changes from `2` to `1`. Names are no
longer merely local choices.

### A procedure can be understood with its definition context

To understand the free variables of a lexical procedure, inspect the context
where it was defined. Under dynamic scope, the same procedure can mean
different things at different call sites because unrelated callers contribute
bindings.

## Explicit dynamic binding in modern programs

Some programs intentionally need context that follows control flow: a current
output destination, logging level, or configuration setting. Racket provides
**parameters** for this controlled purpose:

```racket
(define current-scale (make-parameter 1))

(define (scale n)
  (* n (current-scale)))

(scale 4)                              ; => 4

(parameterize ([current-scale 10])
  (scale 4))                           ; => 40
```

This is explicit in the declaration and at the rebinding site. It does not
make every ordinary lexical variable dynamically scoped. The distinction is
important: a deliberate dynamic facility can be useful even though accidental
dynamic capture makes ordinary local names difficult to reason about.

## Supervised practice

Without running either evaluator, analyze:

```racket
((lambda (rate)
   ((lambda (convert)
      ((lambda (rate)
         (convert 5))
       3))
    (lambda (amount)
      (* rate amount))))
 10)
```

1. Mark every declaration and every reference.
2. Draw an arrow from each reference to its lexical declaration.
3. Predict the result under lexical scope.
4. List the active environment at the call to `convert`.
5. Predict the result under dynamic scope.
6. Rename the inner `rate` declaration to `factor`. Which result changes?
7. Identify the environment a lexical closure for `convert` must save.

Your two answers should be justified by environment traces, not by intuition
about which number seems more reasonable.

## Common mistakes

- **Treating scope as a run-time value.** Scope associates references with
  declarations; environments associate names with values during evaluation.
- **Saying lexical scope uses the caller.** A lexical closure uses its saved
  definition-site environment when entering the body.
- **Saying dynamic scope has no environment.** It uses the caller's current
  environment and therefore the active call chain.
- **Expecting every program to distinguish the rules.** Programs without a
  relevant non-local reference often produce the same result under both.
- **Choosing an example with no shadowing.** A distinguishing program needs a
  call-site binding that competes with the definition-site binding.
- **Assuming alpha-renaming is harmless under dynamic scope.** A name that is
  unused lexically may still intercept a dynamically resolved reference.
- **Confusing an explicit parameter with global dynamic scope.** A parameter is
  a designated dynamic binding; ordinary Racket variables remain lexical.
- **Saving an environment and then ignoring it.** A closure record alone does
  not implement lexical scope unless application extends the saved field.

## Summary

- Scope rules determine which declaration binds a variable reference.
- Lexical scope follows textual nesting and can be determined from source code.
- Dynamic scope follows the most recent active binding on the call chain.
- A lexical closure saves its definition-site environment.
- A dynamically scoped procedure body uses the caller's environment.
- The two interpreters can share syntax and environment representation while
  differing semantically at application.
- Lexical scope supports local reasoning and meaning-preserving alpha-renaming.
- Explicit dynamically scoped parameters can be useful without making all
  variable lookup dynamic.

## Self-check questions

1. What is the difference between a declaration and a reference?
2. What does the scope of a declaration contain?
3. Which environment does a lexical closure extend when it is applied?
4. Which environment does a dynamically scoped procedure extend?
5. Why do many simple programs fail to distinguish the two rules?
6. What ingredients must a distinguishing example contain?
7. Why can changing a locally unused parameter name affect a dynamically
   scoped program?
8. How do Racket parameters provide dynamic behavior without changing the
   scope of ordinary variables?
