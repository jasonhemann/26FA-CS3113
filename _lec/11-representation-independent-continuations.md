---
title: "Representation-independent continuations"
date: 2026-10-26
permalink: /lec/representation-independent-continuations/
published: false
toc: true
toc_sticky: true
---

> **Draft status:** This is an unpublished course note. Its explanations and
> examples are still under review.

The CPS factorial procedure represents each pending multiplication as a Racket
procedure. That representation is convenient, but the rest of the program can
observe it only by applying it. We can separate the *meaning* of a continuation
from its particular representation by routing continuation use through one
operation, `apply-k`.

Once that interface is explicit, continuations can be represented as data. The
resulting transformation is called **defunctionalization**.

## Learning objectives

After working through this note, you should be able to:

- distinguish a continuation's meaning from its representation;
- identify the finite continuation shapes created by CPS factorial;
- explain why a continuation record stores exactly its lambda's free values;
- describe the roles of continuation constructors and `apply-k`;
- state the correctness invariant for a data-structural continuation; and
- trace the creation and consumption of a continuation stack.

## The higher-order starting point

Recall the CPS factorial procedure:

```racket
(define (fact-cps n k)
  (if (zero? n)
      (k 1)
      (fact-cps (sub1 n)
                (lambda (smaller-factorial)
                  (k (* n smaller-factorial))))))
```

Although a run can create many continuation *instances*, the program creates
only two continuation *shapes*:

1. an initial continuation that returns the completed answer; and
2. a multiplication continuation that remembers `n` and an older `k`.

The second lambda has `n` and `k` as free variables. Those are precisely the
values an alternative representation must retain for later.

## One continuation interface

Before choosing a representation, read every continuation application as an
operation:

```racket
(define (apply-k k value)
  (k value))
```

In a higher-order representation, `apply-k` simply applies a Racket procedure.
Its conceptual contract is more general:

> `apply-k` resumes the pending computation represented by `k`, supplying
> `value` as the completed result of the immediately preceding computation.

Code that creates continuations and code that applies continuations now meet at
an explicit boundary.

## Continuations as data

We use two transparent Racket structures:

```racket
(struct empty-k () #:transparent)
(struct multiply-k (saved-n saved-k) #:transparent)
```

`empty-k` has no fields because the initial continuation has nothing left to
remember. `multiply-k` stores the two formerly free values:

- `saved-n`, the factor whose multiplication is pending; and
- `saved-k`, the continuation to resume after that multiplication.

The constructors create descriptions of pending work. They do not perform that
work.

## Interpreting continuation data

`apply-k` now dispatches on the representation:

```racket
(define (apply-k k value)
  (match k
    [(empty-k)
     value]
    [(multiply-k saved-n saved-k)
     (apply-k saved-k (* saved-n value))]))
```

Each clause is the body of the higher-order continuation it represents:

- `empty-k` returns the completed answer;
- `multiply-k` performs one pending multiplication and resumes `saved-k`.

Factorial itself creates continuation records instead of continuation
procedures:

```racket
(define (fact-ri n k)
  (if (zero? n)
      (apply-k k 1)
      (fact-ri (sub1 n)
               (multiply-k n k))))
```

No Racket procedure is used as a continuation in this version. The set of
allowed continuation variants is visible in the structure declarations and in
the exhaustive `match` inside `apply-k`.

## The correctness invariant

Let `fact` be direct-style factorial. For every nonnegative `n` and every valid
data-structural continuation `k`, the intended relationship is:

```text
(fact-ri n k)  behaves like  (apply-k k (fact n))
```

The right side says: compute the direct answer, then resume the already-pending
work. The left side interleaves factorial's recursion with explicit
continuation construction. The invariant says these two views agree.

A representation function helps state the same idea another way. If
`continuation->procedure` converts a continuation record back to its procedural
meaning, then:

```text
(apply-k k value) = ((continuation->procedure k) value)
```

This is a testable relationship between representations, not merely a claim
that the driver produces familiar factorial numbers.

## A complete stack trace

Starting with `(fact-ri 4 (empty-k))`, the descent constructs:

```text
(empty-k)
(multiply-k 4 (empty-k))
(multiply-k 3 (multiply-k 4 (empty-k)))
(multiply-k 2 (multiply-k 3 (multiply-k 4 (empty-k))))
(multiply-k 1 (multiply-k 2 (multiply-k 3 (multiply-k 4 (empty-k)))))
```

At `n = 0`, the base value `1` is sent to that stack. `apply-k` consumes one
record at a time:

| Record consumed | Incoming value | Outgoing value |
| --- | ---: | ---: |
| `multiply-k 1 ...` | 1 | 1 |
| `multiply-k 2 ...` | 1 | 2 |
| `multiply-k 3 ...` | 2 | 6 |
| `multiply-k 4 ...` | 6 | 24 |
| `empty-k` | 24 | 24 |

The continuation data forms an explicit stack whose top is the outermost
structure value.

## Executable reference

```racket
#lang racket

(define (fact n)
  (if (zero? n)
      1
      (* n (fact (sub1 n)))))

;; Higher-order reference version.
(define (fact-cps n k)
  (if (zero? n)
      (k 1)
      (fact-cps (sub1 n)
                (lambda (smaller-factorial)
                  (k (* n smaller-factorial))))))

;; Data-structural continuation representation.
(struct empty-k () #:transparent)
(struct multiply-k (saved-n saved-k) #:transparent)

(define (apply-k k value)
  (match k
    [(empty-k)
     value]
    [(multiply-k saved-n saved-k)
     (apply-k saved-k (* saved-n value))]))

(define (fact-ri n k)
  (if (zero? n)
      (apply-k k 1)
      (fact-ri (sub1 n)
               (multiply-k n k))))

(define (run-fact-ri n)
  (fact-ri n (empty-k)))

;; A semantic map used to compare the two representations.
(define (continuation->procedure k)
  (match k
    [(empty-k)
     values]
    [(multiply-k saved-n saved-k)
     (define older-procedure
       (continuation->procedure saved-k))
     (lambda (value)
       (older-procedure (* saved-n value)))]))

(module+ test
  (require rackunit)

  (for ([n (in-range 10)])
    (check-equal? (run-fact-ri n)
                  (fact n))
    (check-equal? (run-fact-ri n)
                  (fact-cps n values)))

  (define pending-work
    (multiply-k 10
                (multiply-k 3 (empty-k))))

  (for ([n (in-range 7)])
    (check-equal?
     (fact-ri n pending-work)
     (apply-k pending-work (fact n))))

  (for ([value (in-range 6)])
    (check-equal?
     (apply-k pending-work value)
     ((continuation->procedure pending-work) value))))
```

## Why this is representation-independent

`fact-ri` does not need to know how continuation records are interpreted. It
uses the constructors and sends completed values through `apply-k`. Conversely,
`apply-k` does not need to know why a particular continuation was created. It
interprets one continuation record according to the interface.

This separation lets us reason about two dimensions independently:

- **meaning:** which computation remains to be done; and
- **representation:** a Racket closure or a tagged data value containing the
  information needed by that computation.

Defunctionalization works here because the program contains a finite,
statically identifiable collection of continuation-lambda shapes.

## Supervised practice

Start with this continuation record and incoming value:

```racket
(define practice-k
  (multiply-k 5
              (multiply-k 2 (empty-k))))
```

1. Draw the continuation stack.
2. Trace `(apply-k practice-k 3)` one record at a time.
3. Write the procedural continuation that has the same meaning.
4. List the free values that each `multiply-k` record stores.
5. Predict `(fact-ri 3 practice-k)` and justify it using the invariant.

## Common mistakes

- **Putting work in a constructor.** A continuation constructor packages
  information; `apply-k` performs the represented work.
- **Omitting a formerly free value.** A data record must retain everything the
  corresponding lambda would have captured.
- **Storing the continuation's input.** The input value arrives later as the
  second argument to `apply-k`; it is not a constructor field.
- **Forgetting the older continuation.** A pending frame normally resumes the
  chain after doing its own work.
- **Mixing representations accidentally.** Once defunctionalized, the
  continuation position contains continuation data, not an arbitrary Racket
  procedure.
- **Testing only the empty continuation.** A faulty `apply-k` can still pass
  driver tests if no test starts with existing pending work.

## Summary

- A higher-order continuation packages pending work as a Racket procedure.
- An explicit `apply-k` interface separates continuation meaning from
  representation.
- Each continuation-lambda shape becomes a data constructor.
- The constructor fields are the lambda's formerly free values.
- `apply-k` interprets each constructor by performing its pending work.
- The invariant `(fact-ri n k) = (apply-k k (fact n))` validates continuation
  chains beyond the empty driver case.
- Defunctionalized continuations make the control stack explicit data.

## Self-check questions

1. Why are there only two continuation constructors even though a run can
   create many continuation values?
2. Why does `multiply-k` store `saved-n` and `saved-k`, but not the incoming
   result?
3. What part of the procedural representation becomes an `apply-k` clause?
4. What does `empty-k` mean?
5. How does the generalized invariant test more than the driver does?
6. In what sense is the resulting continuation stack explicit?
7. What property of the source program makes defunctionalization possible?

## Acknowledgment

The method for making continuations representation-independent follows Will
Byrd's course method. This factorial presentation and its executable invariants
were edited by Jason Hemann.
