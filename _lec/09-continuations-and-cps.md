---
title: "Continuations and continuation-passing style"
date: 2026-10-19
permalink: /lec/continuations-and-cps/
published: false
toc: true
toc_sticky: true
---

> **Draft status:** This is an unpublished course note. Its explanations and
> examples are still under review.

A direct-style function returns its answer to its caller. A function in
**continuation-passing style** (CPS) instead receives an explicit description
of what should happen next. That description is its **continuation**.

CPS makes the control flow that Racket normally manages for us visible in the
program. In this note, factorial and Fibonacci provide small enough examples
that we can see that control flow without other concerns getting in the way.

## Learning objectives

After working through this note, you should be able to:

- describe a continuation as the rest of a computation;
- state the relationship between a direct-style function and its CPS version;
- explain what information a continuation must remember;
- identify the tail calls in a CPS procedure;
- trace the construction and invocation of continuations; and
- distinguish producing an intermediate value from delivering a final answer.

## The implicit work in direct style

Here is factorial in direct style:

```racket
(define (fact n)
  (if (zero? n)
      1
      (* n (fact (sub1 n)))))
```

When `n` is positive, the recursive call happens before the multiplication can
finish. For `(fact 4)`, Racket must remember four pending multiplications while
it computes the base-case answer:

```text
(* 4 [result of (fact 3)])
(* 3 [result of (fact 2)])
(* 2 [result of (fact 1)])
(* 1 [result of (fact 0)])
```

Those pending operations are implicit continuations. CPS makes them explicit.

## The CPS contract

`fact-cps` receives both `n` and a continuation `k`. It never returns the
factorial result in the ordinary way. It sends that result to `k`.

For every exact nonnegative integer `n`, the intended relationship is:

```text
(fact-cps n k)  behaves like  (k (fact n))
```

This statement is stronger than saying that `(fact-cps n values)` happens to
equal `(fact n)`. It says what `fact-cps` does with *any* suitable continuation.

```racket
(define (fact-cps n k)
  (if (zero? n)
      (k 1)
      (fact-cps (sub1 n)
                (lambda (smaller-factorial)
                  (k (* n smaller-factorial))))))
```

The continuation in the recursive case remembers two things:

- the current value of `n`; and
- the older continuation `k`.

When it receives the factorial of `(sub1 n)`, it performs the pending
multiplication and sends that result onward to `k`.

## A complete trace

Let `K0` be the initial continuation `(lambda (answer) answer)`. Evaluating
`(fact-cps 4 K0)` builds this chain:

| Current `n` | Continuation constructed for the recursive call |
| --- | --- |
| 4 | `K1 = (lambda (v) (K0 (* 4 v)))` |
| 3 | `K2 = (lambda (v) (K1 (* 3 v)))` |
| 2 | `K3 = (lambda (v) (K2 (* 2 v)))` |
| 1 | `K4 = (lambda (v) (K3 (* 1 v)))` |
| 0 | invoke `K4` with `1` |

The chain then runs in the opposite direction:

```text
(K4 1)  -> (K3 1)
(K3 1)  -> (K2 2)
(K2 2)  -> (K1 6)
(K1 6)  -> (K0 24)
```

There is no multiplication waiting after a recursive `fact-cps` call returns.
The multiplication lives inside the newly constructed continuation instead.

## Tail calls and explicit control

In `fact-cps`, every call to a procedure that may continue the computation is
in tail position:

- the recursive call to `fact-cps`; and
- the call to `k` in the base case and inside each continuation.

The surrounding activation has no remaining work after any of those calls.
That is the operational hallmark of CPS.

We will use two terms for this boundary throughout the course:

- A **serious call** is a recursive or otherwise control-transferring call in
  the part of the program using a CPS interface. It must receive a continuation
  describing what to do with its result.
- A **simple operation** is a retained immediate primitive that the chosen CPS
  interface leaves in direct style. It produces its result directly for the
  surrounding CPS code to use.

In this example, calls to `fact-cps` and `k` are serious, while operations such
as `zero?`, `sub1`, and `*` are simple. The distinction records a chosen
interface boundary: it does not claim that an operation is intrinsically
simple, inexpensive, or guaranteed to terminate in every setting. A larger CPS
interface must state explicitly which operations it retains as primitives.

## Two recursive results: Fibonacci

Fibonacci shows why continuation nesting follows data dependencies. With base
values `fib(0) = 0` and `fib(1) = 1`, the direct definition is:

```racket
(define (fib n)
  (if (< n 2)
      n
      (+ (fib (sub1 n))
         (fib (- n 2)))))
```

The addition needs both recursive answers. If we choose to compute the
`(sub1 n)` branch first, its continuation must arrange to compute the other
branch. The second branch's continuation then has access to both results and
can add them:

```racket
(define (fib-cps n k)
  (if (< n 2)
      (k n)
      (fib-cps (sub1 n)
               (lambda (first-answer)
                 (fib-cps (- n 2)
                          (lambda (second-answer)
                            (k (+ first-answer second-answer))))))))
```

CPS has made an evaluation-order decision explicit: the first recursive branch
is evaluated before the second one. A different, consistently implemented
choice could compute the second branch first.

## Executable reference

The following complete program tests both CPS contracts, including
continuations other than the identity procedure.

```racket
#lang racket

(define (fact n)
  (if (zero? n)
      1
      (* n (fact (sub1 n)))))

(define (fact-cps n k)
  (if (zero? n)
      (k 1)
      (fact-cps (sub1 n)
                (lambda (smaller-factorial)
                  (k (* n smaller-factorial))))))

(define (run-fact-cps n)
  (fact-cps n values))

(define (fib n)
  (if (< n 2)
      n
      (+ (fib (sub1 n))
         (fib (- n 2)))))

(define (fib-cps n k)
  (if (< n 2)
      (k n)
      (fib-cps (sub1 n)
               (lambda (first-answer)
                 (fib-cps (- n 2)
                          (lambda (second-answer)
                            (k (+ first-answer second-answer))))))))

(define (run-fib-cps n)
  (fib-cps n values))

(module+ test
  (require rackunit)

  (for ([n (in-range 10)])
    (check-equal? (run-fact-cps n) (fact n))
    (check-equal? (run-fib-cps n) (fib n)))

  ;; The contract holds for continuations other than `values`.
  (check-equal? (fact-cps 5 add1)
                (add1 (fact 5)))
  (check-equal? (fib-cps 8 number->string)
                (number->string (fib 8))))
```

## Supervised practice

Without running Racket, trace `(fact-cps 3 (lambda (answer) (+ answer 10)))`.

1. Name each continuation as it is constructed.
2. Write the values delivered while the continuation chain is invoked.
3. Identify the factorial result.
4. Identify the final result of the whole call.
5. Explain why those last two numbers differ.

Then consider the recursive case of `fib-cps` for `n = 4`. Mark which
continuation remembers `n`, which remembers the first recursive answer, and
which continuation receives the sum.

## Common mistakes

- **Calling `k` too early.** An intermediate result should be sent to the
  continuation only when the direct-style function would have produced its
  result.
- **Forgetting the old continuation.** A newly constructed continuation often
  performs one pending operation and then invokes the continuation it captured.
- **Leaving work after a serious call.** If the caller still has a pending
  operation after a recursive CPS call, that operation belongs in a
  continuation.
- **Applying the direct procedure recursively.** The recursive calls inside a
  CPS procedure must use the CPS interface and supply a continuation.
- **Using a computed value twice accidentally.** The formal parameter of a
  continuation stands for one particular suspended computation.
- **Believing CPS determines the only evaluation order.** CPS records an order;
  the programmer or transformation must first choose that order.

## Summary

- A continuation represents the rest of a computation.
- A CPS procedure receives that continuation explicitly and sends its result
  to it.
- The contract `(f-cps input k) = (k (f input))` is the central correctness
  relationship.
- Pending direct-style operations become continuation bodies.
- Values needed later become captured variables of those continuations.
- Serious calls in a CPS program occur in tail position.
- Nested continuations make evaluation order and data dependencies explicit.

## Self-check questions

1. What does the continuation passed to `fact-cps` mean?
2. Which values are free in the continuation constructed by the recursive
   factorial case, and why must it remember them?
3. Why is the multiplication in `fact-cps` not performed immediately?
4. What distinguishes a tail call from an ordinary call followed by more work?
5. In `fib-cps`, why is the continuation for the first recursive branch nested
   outside the call for the second branch?
6. How would you test the CPS contract without relying only on the identity
   continuation?
7. Which evaluation-order choice is encoded by the given `fib-cps`?

## Acknowledgment

This presentation is adapted from CPS lecture notes by Adam Foltzer and from
subsequent course notes and factorial/Fibonacci developments by Jason Hemann.
