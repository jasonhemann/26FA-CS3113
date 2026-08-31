---
title: "Store-passing style"
date: 2026-10-28
permalink: /lec/store-passing-style/
published: false
toc: true
toc_sticky: true
---

> **Draft status:** This is an unpublished, unnumbered special-topic lecture
> note. Its explanations and examples are still under review.

**Store-passing style** (SPS) makes changing state explicit. An SPS procedure
receives the current store and returns both its ordinary value and the store
that the next computation must use.

That one rule lets us describe memoization, allocation, assignment, and
sequencing without mutating a Racket data structure. It also exposes a crucial
interpreter distinction:

```text
Environment : Variable -> Location
Store       : Location -> Value
```

The environment says *where* a variable's value lives. The store says *what
value is currently there*.

## Learning objectives

After working through this note, you should be able to:

- state the input-output contract of a store-passing procedure;
- use `values`, `let-values`, and `let*-values` to thread a store;
- explain why each later computation must receive the preceding computation's
  output store;
- distinguish an environment from a store;
- explain why assignment changes the store rather than the environment;
- trace allocation, variable lookup, assignment, and sequencing in an
  explicit-store interpreter; and
- distinguish object-language mutation from host-language mutation.

## The store-passing contract

We will write the contract of an SPS procedure schematically as

```text
(f-sps input store0) -> (values answer store1)
```

`answer` is the ordinary result of the computation. `store1` is the state
*after* that computation. If another computation happens next, it must receive
`store1`, not `store0`.

Racket's `values` form produces multiple values. `let-values` receives them:

```racket
(define (quotient+remainder m n)
  (values (quotient m n) (remainder m n)))

(let-values ([(q r) (quotient+remainder 17 5)])
  (list q r))
;; => '(3 2)
```

These are two Racket values, not one two-element list. Their positions are part
of the interface. Throughout this note, the ordinary answer comes first and
the successor store comes second.

When several store-passing computations occur in order, `let*-values` makes
the dependency visible:

```racket
(let*-values ([(value1 store1) (first-sps input store0)]
              [(value2 store2) (second-sps value1 store1)])
  (values value2 store2))
```

The second call sees `store1`. Reusing `store0` there would discard every
change made by the first call.

## A first example: memoized Fibonacci

The ordinary recursive Fibonacci program repeats subcomputations. A cache can
record answers already found. In the SPS version, the cache plays the role of
the store. Here `n` is assumed to be an exact nonnegative integer:

```racket
(define (fib-sps n cache)
  (cond
    [(hash-has-key? cache n)
     (values (hash-ref cache n) cache)]
    [(< n 2)
     (values n (hash-set cache n n))]
    [else
     (let*-values ([(v1 cache1) (fib-sps (sub1 n) cache)]
                   [(v2 cache2) (fib-sps (- n 2) cache1)])
       (define answer (+ v1 v2))
       (values answer (hash-set cache2 n answer)))]))

(define (fib n)
  (unless (exact-nonnegative-integer? n)
    (raise-argument-error 'fib "exact-nonnegative-integer?" n))
  (let-values ([(answer final-cache) (fib-sps n (hash))])
    answer))
```

The important feature is not merely that `fib-sps` has an extra parameter.
Every recursive call returns a possibly larger cache, and the next recursive
call receives that cache.

For `(fib-sps 4 (hash))`, the significant flow is:

| Computation | Ordinary value | Relevant cache fact afterward |
|---|---:|---|
| `fib-sps 1` | 1 | `1 -> 1` |
| `fib-sps 0` | 0 | `0 -> 0` |
| `fib-sps 2` | 1 | `2 -> 1` |
| second request for `fib-sps 1` | 1 | cache hit; no recomputation |
| `fib-sps 3` | 2 | `3 -> 2` |
| second request for `fib-sps 2` | 1 | cache hit; no recomputation |
| `fib-sps 4` | 3 | `4 -> 3` |

`hash-set` does not mutate its input hash. It produces a new immutable hash
whose mapping differs at one key. The program models changing state by passing
successive values.

Memoization is a useful warm-up, but an interpreter store has a more specific
job: it models the memory of the language being interpreted.

## Why an interpreter separates environment and store

In an interpreter without assignment, an environment can map a variable
directly to its value:

```text
x -> 5
```

Once the language has assignment, a binding must keep its identity while its
value changes. We insert a location between the name and the value:

```text
Environment                 Store
x -> location 0             location 0 -> 5
```

After `(set! x 4)`, the environment is unchanged:

```text
Environment                 New store
x -> location 0             location 0 -> 4
```

This indirection also explains how a closure can observe an update. The
closure saves an environment containing `x -> location 0`; it does not freeze
the value `5`. Looking up `x` later follows the same location into the current
store.

## A small persistent store

Our teaching store carries the next unused location and an immutable hash of
allocated cells:

```racket
(struct store (next cells) #:transparent)

(define (empty-store)
  (store 0 (hash)))

(define (store-allocate st value)
  (define location (store-next st))
  (values location
          (store (add1 location)
                 (hash-set (store-cells st) location value))))

(define (store-ref st location)
  (hash-ref (store-cells st)
            location
            (lambda ()
              (error 'store-ref "unallocated location: ~s" location))))

(define (store-set st location value)
  (unless (hash-has-key? (store-cells st) location)
    (error 'store-set "unallocated location: ~s" location))
  (store (store-next st)
         (hash-set (store-cells st) location value)))
```

The three operations have different contracts:

| Operation | Result |
|---|---|
| `store-allocate` | a fresh location and a successor store |
| `store-ref` | the value at an existing location |
| `store-set` | a successor store with one location updated |

Reading does not change the store. Allocation and update return new stores.
The old stores remain valid Racket values, which makes traces and tests easy to
inspect.

## The object language

The interpreter below supports this small language:

```text
Expression ::= Number
             | Variable
             | (sub1 Expression)
             | (zero? Expression)
             | (if Expression Expression Expression)
             | (lambda (Variable) Expression)
             | (Expression Expression)
             | (set! Variable Expression)
             | (begin Expression Expression)
```

`begin` has exactly two subexpressions in this teaching language. The first is
evaluated for its effect; its value is discarded. The second provides the
value of the whole `begin` expression.

An environment is an association list from symbols to locations. A closure
saves a parameter, a body, and the environment from its definition site:

```racket
(struct closure (parameter body environment) #:transparent)

(define empty-env '())

(define (extend-env name location env)
  (cons (cons name location) env))

(define (apply-env env name)
  (cond
    [(assq name env) => cdr]
    [else (error 'apply-env "unbound variable: ~s" name)]))
```

Notice that a closure saves locations indirectly through its environment. It
does not save a private copy of the store.

## The evaluator invariant

Every evaluator call obeys the same invariant:

```text
(value-of expression environment store0)
  -> (values value store1)
```

`value` is the meaning of `expression` in `environment`, beginning with
`store0`. `store1` contains exactly the effects of evaluating that expression
in the interpreter's documented order.

The clauses with no effects return their input store unchanged:

```racket
[(? number? n)
 (values n st)]

[(? symbol? name)
 (values (store-ref st (apply-env env name)) st)]

[`(lambda (,parameter) ,body)
 (values (closure parameter body env) st)]
```

The `sub1` clause evaluates its subexpression first and returns the resulting
store:

```racket
[`(sub1 ,operand)
 (let-values ([(value st1) (value-of operand env st)])
   (values (sub1 value) st1))]
```

The `set!` clause evaluates its right-hand side, finds the existing location of
the variable, and updates that location in the resulting store:

```racket
[`(set! ,name ,rhs)
 (let-values ([(value st1) (value-of rhs env st)])
   (values (void)
           (store-set st1 (apply-env env name) value)))]
```

Assignment does not extend the environment and does not allocate a new
location. It changes the value associated with an existing binding.

Sequencing passes the first expression's output store to the second:

```racket
[`(begin ,first ,second)
 (let-values ([(_ st1) (value-of first env st)])
   (value-of second env st1))]
```

At function application, this interpreter evaluates the operator first and
the operand second. It then allocates a fresh location for the argument and
evaluates the body in the closure's saved environment:

```racket
[`(,operator ,operand)
 (let*-values ([(procedure st1) (value-of operator env st)]
               [(argument st2) (value-of operand env st1)])
   (apply-closure procedure argument st2))]
```

The order written here is semantic. Once effects exist, reversing the two
subcomputations can change the result.

## A complete executable interpreter

The following module collects the examples and tests the store-passing
invariants.

```racket
#lang racket

(require rackunit)

;; A warm-up store: a persistent Fibonacci cache.
(define (fib-sps n cache)
  (cond
    [(hash-has-key? cache n)
     (values (hash-ref cache n) cache)]
    [(< n 2)
     (values n (hash-set cache n n))]
    [else
     (let*-values ([(v1 cache1) (fib-sps (sub1 n) cache)]
                   [(v2 cache2) (fib-sps (- n 2) cache1)])
       (define answer (+ v1 v2))
       (values answer (hash-set cache2 n answer)))]))

(define (fib n)
  (unless (exact-nonnegative-integer? n)
    (raise-argument-error 'fib "exact-nonnegative-integer?" n))
  (let-values ([(answer final-cache) (fib-sps n (hash))])
    answer))

;; Store = Location -> Value, plus the next fresh location.
(struct store (next cells) #:transparent)

(define (empty-store)
  (store 0 (hash)))

(define (store-allocate st value)
  (define location (store-next st))
  (values location
          (store (add1 location)
                 (hash-set (store-cells st) location value))))

(define (store-ref st location)
  (hash-ref (store-cells st)
            location
            (lambda ()
              (error 'store-ref "unallocated location: ~s" location))))

(define (store-set st location value)
  (unless (hash-has-key? (store-cells st) location)
    (error 'store-set "unallocated location: ~s" location))
  (store (store-next st)
         (hash-set (store-cells st) location value)))

;; Env = Variable -> Location.
(define empty-env '())

(define (extend-env name location env)
  (cons (cons name location) env))

(define (apply-env env name)
  (cond
    [(assq name env) => cdr]
    [else (error 'apply-env "unbound variable: ~s" name)]))

(struct closure (parameter body environment) #:transparent)

(define (apply-closure procedure argument st)
  (match procedure
    [(closure parameter body saved-env)
     (let-values ([(location st1) (store-allocate st argument)])
       (value-of body
                 (extend-env parameter location saved-env)
                 st1))]
    [_ (error 'apply-closure "not a closure: ~s" procedure)]))

(define (value-of expression env st)
  (match expression
    [(? number? n)
     (values n st)]
    [(? symbol? name)
     (values (store-ref st (apply-env env name)) st)]
    [`(sub1 ,operand)
     (let-values ([(value st1) (value-of operand env st)])
       (values (sub1 value) st1))]
    [`(zero? ,operand)
     (let-values ([(value st1) (value-of operand env st)])
       (values (zero? value) st1))]
    [`(if ,test ,consequent ,alternative)
     (let-values ([(test-value st1) (value-of test env st)])
       (if test-value
           (value-of consequent env st1)
           (value-of alternative env st1)))]
    [`(lambda (,parameter) ,body)
     (values (closure parameter body env) st)]
    [`(set! ,name ,rhs)
     (let-values ([(value st1) (value-of rhs env st)])
       (values (void)
               (store-set st1 (apply-env env name) value)))]
    [`(begin ,first ,second)
     (let-values ([(_ st1) (value-of first env st)])
       (value-of second env st1))]
    [`(,operator ,operand)
     (let*-values ([(procedure st1) (value-of operator env st)]
                   [(argument st2) (value-of operand env st1)])
       (apply-closure procedure argument st2))]
    [_ (error 'value-of "bad expression: ~s" expression)]))

(define (run expression)
  (let-values ([(answer final-store)
                (value-of expression empty-env (empty-store))])
    answer))

(module+ test
  ;; The Fibonacci result and its returned cache agree.
  (let-values ([(answer cache) (fib-sps 10 (hash))])
    (check-equal? answer 55)
    (check-equal? (hash-ref cache 10) 55)
    (check-equal? (hash-ref cache 9) 34))
  (check-equal? (fib 0) 0)
  (check-equal? (fib 1) 1)
  (check-equal? (fib 12) 144)

  ;; Persistent store updates leave the preceding store unchanged.
  (let*-values ([(location st1) (store-allocate (empty-store) 5)])
    (define st2 (store-set st1 location 4))
    (check-equal? location 0)
    (check-equal? (store-ref st1 location) 5)
    (check-equal? (store-ref st2 location) 4))

  ;; Pure expressions and ordinary application still work.
  (check-equal? (run 5) 5)
  (check-equal? (run '((lambda (x) x) 5)) 5)
  (check-equal? (run '((lambda (x) (sub1 x)) 5)) 4)
  (check-equal? (run '(if (zero? 0) 7 8)) 7)

  ;; Assignment changes the cell observed by the following expression.
  (check-equal?
   (run '((lambda (x)
            (begin
              (set! x (sub1 x))
              x))
          5))
   4)

  ;; A closure and its enclosing computation share x's location.
  (check-equal?
   (run '((lambda (x)
            ((lambda (change)
               (begin
                 (change 0)
                 x))
             (lambda (ignored)
               (set! x (sub1 x)))))
          5))
   4)

  ;; A closure uses the store at application time, not a saved snapshot.
  (check-equal?
   (run '((lambda (x)
            ((lambda (f)
               (begin
                 (set! x 4)
                 (f 0)))
             (lambda (ignored) x)))
          5))
   4)

  ;; Effects expose the documented operator-before-operand order.
  (check-equal?
   (run '((lambda (x)
            ((begin
               (set! x 1)
               (lambda (ignored) x))
             (begin
               (set! x 2)
               0)))
          0))
   2)

  ;; A shadowing parameter receives a different location.
  (check-equal?
   (run '((lambda (x)
            (begin
              ((lambda (x) (set! x 0)) 7)
              x))
          5))
   5))
```

## Worked trace: assignment and sequencing

Consider:

```racket
((lambda (x)
   (begin
     (set! x (sub1 x))
     x))
 5)
```

The essential states are:

| Step | Environment fact | Store fact | Produced value |
|---|---|---|---|
| evaluate the lambda | empty | empty | closure |
| evaluate the operand | empty | empty | `5` |
| bind `x` | `x -> 0` | `0 -> 5` | begin body starts |
| read `x` in `(sub1 x)` | `x -> 0` | `0 -> 5` | `5`, then `4` |
| execute `set!` | `x -> 0` | `0 -> 4` | void |
| evaluate the second part of `begin` | `x -> 0` | `0 -> 4` | `4` |

The binding of `x` never changes. The store cell at its location does.

## A closure observes the current store

In the larger test from the complete module, the procedure bound to `change`
was created while `x` referred to location 0. Calling `change` later updates
location 0. When the enclosing body subsequently evaluates `x`, lookup follows
the same saved location into the new store and obtains `4`.

That is the point of the location indirection. If the closure had copied the
value `5` instead, it would fail to observe the assignment.

The next test is sharper still: it creates `f` while `x` contains `5`, changes
`x` to `4`, and only then calls `f`. The answer must be `4`. An implementation
that accidentally saves the creation-time store inside the closure would
return the stale value `5`.

## SPS and CPS are different transformations

Both styles add an explicit parameter, but they expose different hidden
structure:

| Style | Extra input describes | How a computation finishes |
|---|---|---|
| direct style | neither explicitly | returns one ordinary value |
| continuation-passing style | what to do with the value next | invokes a continuation |
| store-passing style | the state before the computation | returns a value and successor state |

A program can use both styles simultaneously. An evaluator in CPS and SPS
would receive both a continuation and a store; each clause would eventually
send both the value and updated store onward according to its chosen
interface. Neither transformation is merely a renaming of the other.

## Supervised practice

Use the evaluator invariant, not trial execution, to work through these.

1. Starting with `x -> 3` and store `3 -> 10`, show the environment and store
   after evaluating `(set! x (sub1 x))`.
2. In the application clause, circle the store consumed by each subcomputation
   and draw arrows showing where that store came from.
3. Predict the result of the shadowing test before running it. Identify the two
   distinct locations allocated for the two bindings named `x`.
4. Write a clause for `(begin e1 e2)` that mistakenly evaluates `e2` with the
   original store. Give the smallest program that exposes the mistake.
5. Extend the language with `(+ e1 e2)`. State the intended order, then write a
   clause that threads both stores correctly.
6. Explain why `store-set` returns a new store while object-language `set!`
   still counts as mutation.

## Common mistakes

- **Reusing an old store.** Each subsequent subcomputation must receive the
  most recently returned store.
- **Mapping variables directly to values.** With assignment, an environment
  maps variables to stable locations; changing values live in the store.
- **Changing the environment for `set!`.** Assignment updates an existing
  cell. Binding introduction is what extends an environment.
- **Allocating from stale state.** Freshness is determined by the current
  store, after all earlier effects.
- **Saving a whole store in a closure.** A closure saves its lexical
  environment. It is applied using the current store.
- **Treating evaluation order as irrelevant.** Once expressions can change
  state, operator-first and operand-first evaluation can differ observably.
- **Confusing explicit state with host mutation.** Successive immutable Racket
  store values can model a language whose programs mutate variables.
- **Confusing SPS with CPS.** A store represents current memory; a continuation
  represents pending control.

## Summary

- An SPS procedure receives a store and returns an ordinary value plus a
  successor store.
- `let*-values` records the data dependency between successive stores.
- Memoized Fibonacci provides a small example of passing an evolving cache.
- An explicit-store interpreter separates `Variable -> Location` from
  `Location -> Value`.
- Variable lookup follows both mappings; assignment updates the second.
- Function application allocates a fresh location for its parameter.
- Closures retain lexical locations and therefore observe later updates
  through the current store.
- Persistent host-language data can model object-language mutation precisely.

## Self-check questions

1. What are the two results of an SPS computation?
2. Why must the second recursive call in `fib-sps` receive `cache1`?
3. What does an environment map a variable to once assignment is present?
4. What changes during `set!`: the environment, the store, or both?
5. Why does a closure save an environment but not a creation-time store?
6. Where does the interpreter allocate a fresh location?
7. What evaluation order does the application clause implement?
8. How can immutable Racket hashes model mutation in the interpreted
   language?
9. What hidden structure does SPS expose that CPS does not?

## Acknowledgment

This note synthesizes store-passing developments from earlier C311 and CSAS
3113 course materials, including the memoized-Fibonacci and explicit-store
interpreter examples used in class from 2012 through 2024. The examples here
have been rewritten and tested for this course.
