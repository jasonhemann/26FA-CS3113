---
title: "Registerization"
order: 12
permalink: /lec/registerization/
published: true
toc: true
toc_sticky: true
---

The original, general transformation development remains on Jason Hemann's
site as [Representation Independence Procedure](https://hemann.pl/representation-independence/).
This course companion uses factorial to make the register invariants and the
student practice concrete without reproducing an assignment transformation.

Our defunctionalized CPS factorial still passes values as procedure arguments.
**Registerization** moves those argument values into an explicit, fixed set of
registers. Here a **serious procedure** is one of the recursive or otherwise
control-transferring procedures in the CPS interface—specifically the
factorial worker and the continuation dispatcher. The serious procedures then
take no arguments: each reads its inputs from registers, writes the next
serious procedure's inputs to registers, and tail-calls that procedure.

Factorial is intentionally used here because it exposes the register
invariants without entangling them with an evaluator or a larger transformation
pipeline.

## Learning objectives

After working through this note, you should be able to:

- state the entry invariant for each registerized procedure;
- map procedure parameters to explicit registers;
- explain why assignments must preserve the values of the old arguments;
- trace control between a worker and `apply-k` without accumulating
  host-language call frames;
- relate the registerized program to its parameterized predecessor; and
- describe the costs of using global mutable state.

## The parameterized starting point

We begin with factorial in CPS using data-structural continuations:

```racket
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
```

There are two serious interfaces:

```text
fact-ri : n k     -> answer
apply-k : k value -> answer
```

The registerized program therefore needs three registers:

- `n-reg` for `fact-ri`'s `n` parameter;
- `k-reg` for the continuation shared by both interfaces; and
- `v-reg` for `apply-k`'s `value` parameter.

## Entry invariants

The meaning of a zero-argument procedure call depends on the register state at
entry:

| Procedure | Required register contents |
| --- | --- |
| `fact-reg` | `n-reg` is the remaining factorial input; `k-reg` is the continuation for its result. |
| `apply-k-reg` | `v-reg` is the completed value; `k-reg` is the continuation to receive it. |

These are the registerized counterparts of ordinary parameter bindings. A call
is correct only if the caller establishes the callee's entry invariant first.

## Replacing an argument call

The parameterized base case is:

```racket
(apply-k k 1)
```

Its registerized counterpart stores the actual arguments in the corresponding
registers and then invokes the zero-argument procedure:

```racket
(set! v-reg 1)
;; k-reg already contains k
(apply-k-reg)
```

The recursive case is more delicate. The parameterized call is:

```racket
(fact-ri (sub1 n)
         (multiply-k n k))
```

Both right-hand sides refer to the *old* register values. The continuation must
save the old `n-reg` before `n-reg` is decremented:

```racket
(set! k-reg (multiply-k n-reg k-reg))
(set! n-reg (sub1 n-reg))
(fact-reg)
```

Reversing the first two assignments would save the wrong factor. Register
assignment order is therefore part of the program's correctness argument.

## The registerized continuation dispatcher

The empty continuation simply returns `v-reg`. A multiplication frame contains
the factor and older continuation that should become the next state:

```racket
(define (apply-k-reg)
  (match k-reg
    [(empty-k)
     v-reg]
    [(multiply-k saved-n saved-k)
     (set! v-reg (* saved-n v-reg))
     (set! k-reg saved-k)
     (apply-k-reg)]))
```

Before the recursive call, the two assignments re-establish the
`apply-k-reg` entry invariant for the next continuation record.

## The registerized worker

```racket
(define (fact-reg)
  (if (zero? n-reg)
      (begin
        (set! v-reg 1)
        (apply-k-reg))
      (begin
        (set! k-reg (multiply-k n-reg k-reg))
        (set! n-reg (sub1 n-reg))
        (fact-reg))))
```

Every serious call is a tail call, and every serious procedure receives its
inputs through the registers. The continuation structures are still explicit
data; registerization changes how values move between procedures, not what the
continuations mean.

## Driver boundary

A small driver establishes the initial machine state:

```racket
(define (fact-registerized n)
  (set! n-reg n)
  (set! k-reg (empty-k))
  (fact-reg))

;; A testing boundary for an already-constructed continuation state.
(define (run-continuation k value)
  (set! k-reg k)
  (set! v-reg value)
  (apply-k-reg))
```

The caller still gets an ordinary one-argument interface. On the inside,
control moves through the fixed registers and zero-argument serious functions.

## A complete state trace

For `(fact-registerized 3)`, the significant states are:

| Next procedure | `n-reg` | `v-reg` | `k-reg` meaning |
| --- | ---: | ---: | --- |
| `fact-reg` | 3 | unspecified | return final answer |
| `fact-reg` | 2 | unspecified | multiply by 3, then return |
| `fact-reg` | 1 | unspecified | multiply by 2, then by 3, then return |
| `fact-reg` | 0 | unspecified | multiply by 1, then by 2, then by 3, then return |
| `apply-k-reg` | 0 | 1 | multiply by 1, then by 2, then by 3, then return |
| `apply-k-reg` | 0 | 1 | multiply by 2, then by 3, then return |
| `apply-k-reg` | 0 | 2 | multiply by 3, then return |
| `apply-k-reg` | 0 | 6 | return final answer |

`n-reg` is no longer meaningful to `apply-k-reg`; its entry invariant mentions
only `k-reg` and `v-reg`. Register invariants specify which parts of the global
state matter at each control point.

## Executable reference

```racket
#lang racket

(define (fact n)
  (if (zero? n)
      1
      (* n (fact (sub1 n)))))

(struct empty-k () #:transparent)
(struct multiply-k (saved-n saved-k) #:transparent)

;; The explicit registers.
(define n-reg #f)
(define k-reg #f)
(define v-reg #f)

;; Entry invariant:
;;   k-reg is a continuation and v-reg is its incoming value.
(define (apply-k-reg)
  (match k-reg
    [(empty-k)
     v-reg]
    [(multiply-k saved-n saved-k)
     (set! v-reg (* saved-n v-reg))
     (set! k-reg saved-k)
     (apply-k-reg)]))

;; Entry invariant:
;;   n-reg is a nonnegative integer and k-reg expects its factorial.
(define (fact-reg)
  (if (zero? n-reg)
      (begin
        (set! v-reg 1)
        (apply-k-reg))
      (begin
        ;; Save the old n-reg in the frame before changing n-reg.
        (set! k-reg (multiply-k n-reg k-reg))
        (set! n-reg (sub1 n-reg))
        (fact-reg))))

(define (fact-registerized n)
  (set! n-reg n)
  (set! k-reg (empty-k))
  (fact-reg))

(define (run-continuation k value)
  (set! k-reg k)
  (set! v-reg value)
  (apply-k-reg))

(module+ test
  (require rackunit)

  (for ([n (in-range 11)])
    (check-equal? (fact-registerized n)
                  (fact n)))

  ;; Exercise the dispatcher from a nonempty machine state.
  (check-equal?
   (run-continuation
    (multiply-k 3
                (multiply-k 2 (empty-k)))
    4)
   24))
```

## What changed—and what did not

Registerization changes the calling convention:

| Parameterized program | Registerized program |
| --- | --- |
| formal parameters name inputs | entry invariants name input registers |
| actual arguments carry values | assignments place values in registers |
| a serious function receives arguments | a serious function takes no arguments |
| local parameter bindings hold current inputs | mutable registers hold current inputs |

It does not change:

- the definition of factorial;
- the meaning of either continuation constructor;
- the order in which continuation records are consumed; or
- the required result for any nonnegative input.

The main proof obligation is local: immediately before each serious call, do
the registers satisfy that callee's entry invariant with the same values the
parameterized call would have passed?

## Mutation and reentrancy

The simple machine uses one global register set. It is consequently not
reentrant: two computations cannot safely share these registers at the same
time, and a nested call to the driver would overwrite the outer computation's
state. It is also unsuitable for parallel calls without separate machine
states.

That limitation is not an accidental coding defect. It is a consequence of
choosing one global register bank as the representation of parameter bindings.
A production implementation can package registers into a machine-state value,
but the global form makes the calling convention especially visible.

## Supervised practice

Starting from the state

```text
n-reg = 4
k-reg = (empty-k)
v-reg = unspecified
```

1. Record the state immediately before every serious call.
2. At each row, state the entry invariant that must hold.
3. Circle the assignment that must happen before `n-reg` changes.
4. Explain why `v-reg` is irrelevant on entry to `fact-reg`.
5. Explain why `n-reg` is irrelevant on entry to `apply-k-reg`.
6. Predict the error caused by reversing the two assignments in the recursive
   branch.

## Common mistakes

- **Calling before loading registers.** A zero-argument serious procedure still
  has inputs; they must satisfy its entry invariant.
- **Overwriting a needed old value.** Construct next-state values before
  changing any register they depend on.
- **Assuming all registers are meaningful everywhere.** Each control point has
  its own entry invariant.
- **Leaving serious parameters in place.** A fully registerized serious
  function reads its former parameters from registers.
- **Changing continuation meaning.** Registerization moves values; it should not
  redesign the continuation representation or dispatcher behavior.
- **Ignoring shared-state limitations.** A global register bank makes the
  program non-reentrant unless access is externally controlled.

## Summary

- Registerization replaces serious-function arguments with explicit registers.
- Each zero-argument procedure has an entry invariant describing its input
  registers.
- A caller writes the values that an ordinary call would have passed, then
  tail-calls the callee.
- Assignment order must preserve every value needed to construct the next
  state.
- The continuation data still represents pending work; `k-reg` selects that
  work and `v-reg` supplies its input.
- The registerized program exposes a small abstract machine with two control
  procedures and three registers.
- Global registers make the teaching machine simple but non-reentrant.

## Self-check questions

1. Which former parameters correspond to `n-reg`, `k-reg`, and `v-reg`?
2. What must be true whenever `fact-reg` begins?
3. What must be true whenever `apply-k-reg` begins?
4. Why must the recursive branch construct `multiply-k` before decrementing
   `n-reg`?
5. What is the registerized counterpart of an ordinary actual argument?
6. Which aspects of the continuation representation survive unchanged?
7. Why can the driver retain an ordinary one-argument interface?
8. What prevents two simultaneous computations from sharing this machine?

## Acknowledgment

This factorial presentation is based on Jason Hemann's registerization notes
and the course's earlier factorial/Fibonacci transformation developments.
