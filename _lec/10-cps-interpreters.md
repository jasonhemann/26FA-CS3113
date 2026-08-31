---
title: "A small interpreter in continuation-passing style"
order: 10
permalink: /lec/cps-interpreters/
published: true
toc: true
toc_sticky: true
---

An interpreter is an ordinary recursive program, so it can use the same
continuation-passing interface as other recursive programs. In a CPS
interpreter, the current continuation says what to do with the value of the
current object-language subexpression.

This note deliberately uses a tiny language of closed arithmetic expressions.
That keeps the focus on control flow: there are no variables, environments,
closures, or control operators to distract from the CPS invariant.

## Learning objectives

After working through this note, you should be able to:

- state the correctness relationship between direct and CPS evaluators;
- explain what the evaluator's continuation expects to receive;
- trace the order in which an arithmetic syntax tree is evaluated;
- distinguish host-language arithmetic from recursive interpretation;
- explain why both recursive calls in a binary form need continuations; and
- test an evaluator with continuations other than the identity procedure.

## A tiny object language

Our object language contains numbers, addition, and multiplication:

```text
e ::= n
    | (+ e e)
    | (* e e)
```

An object-language program is quoted Racket data. For example:

```racket
'(+ (* 2 3) (+ 4 5))
```

The direct evaluator follows the grammar:

```racket
(define (value-of expr)
  (match expr
    [(? number? n)
     n]
    [`(+ ,left ,right)
     (+ (value-of left)
        (value-of right))]
    [`(* ,left ,right)
     (* (value-of left)
        (value-of right))]
    [bad-expression
     (error 'value-of "not an arithmetic expression: ~v"
            bad-expression)]))
```

The host calls to `+` and `*` are not recursive interpreter calls. They combine
values only after the object-language operands have been interpreted.

Using the serious/simple distinction from the preceding note, recursive calls
to `value-of-cps` and invocations of `k` are serious: they use the CPS control
interface and therefore receive or resume a continuation. The retained host
operations `+` and `*` are simple primitives in this evaluator. They run
directly only after serious evaluator calls have supplied both operand values.
This classification belongs to the evaluator's stated interface; it is not an
intrinsic classification of addition or multiplication.

## The evaluator's CPS invariant

`value-of-cps` accepts an expression and a continuation. Its continuation
expects the value of that expression.

For every expression `e` in the grammar and every suitable continuation `k`,
the intended relationship is:

```text
(value-of-cps e k)  behaves like  (k (value-of e))
```

This invariant should hold at *every recursive call*. The continuation at a
recursive call records how that subexpression's value will contribute to the
value of the surrounding expression.

## The three evaluator clauses

For a number, the value is already available, so the evaluator sends it to the
continuation:

```racket
[(? number? n)
 (k n)]
```

For addition, we choose left-to-right evaluation. The continuation for the
left operand receives `left-value` and initiates evaluation of the right
operand. The inner continuation then has both values and can deliver their sum
to `k`:

```racket
[`(+ ,left ,right)
 (value-of-cps left
               (lambda (left-value)
                 (value-of-cps right
                               (lambda (right-value)
                                 (k (+ left-value right-value))))))]
```

Multiplication has the same control shape, but combines its operand values with
host-language multiplication:

```racket
[`(* ,left ,right)
 (value-of-cps left
               (lambda (left-value)
                 (value-of-cps right
                               (lambda (right-value)
                                 (k (* left-value right-value))))))]
```

Each continuation corresponds to a data dependency:

- evaluating the right operand depends on having finished the left operand;
- performing the arithmetic depends on having both operand values; and
- completing the surrounding computation depends on delivering the arithmetic
  result to the older continuation.

## A complete trace

Consider:

```racket
'(+ (* 2 3) (+ 4 5))
```

Let `K0` be the initial continuation. The evaluator proceeds as follows:

| Step | Current expression | What its continuation will do |
| --- | --- | --- |
| 1 | `(+ (* 2 3) (+ 4 5))` | receive the whole expression's value in `K0` |
| 2 | `(* 2 3)` | remember the right addition and the outer `+` |
| 3 | `2` | begin evaluating `3` |
| 4 | `3` | multiply `2` and `3`, producing `6` |
| 5 | `(+ 4 5)` | remember the left outer value `6` |
| 6 | `4` | begin evaluating `5` |
| 7 | `5` | add `4` and `5`, producing `9` |
| 8 | completed outer `+` | send `(+ 6 9)`, or `15`, to `K0` |

The syntax tree is recursive, but the continuation chain fixes a linear order
for visiting the nodes whose values depend on one another.

## Executable reference

```racket
#lang racket

(define (value-of expr)
  (match expr
    [(? number? n)
     n]
    [`(+ ,left ,right)
     (+ (value-of left)
        (value-of right))]
    [`(* ,left ,right)
     (* (value-of left)
        (value-of right))]
    [bad-expression
     (error 'value-of "not an arithmetic expression: ~v"
            bad-expression)]))

(define (value-of-cps expr k)
  (match expr
    [(? number? n)
     (k n)]
    [`(+ ,left ,right)
     (value-of-cps left
                   (lambda (left-value)
                     (value-of-cps right
                                   (lambda (right-value)
                                     (k (+ left-value
                                           right-value))))))]
    [`(* ,left ,right)
     (value-of-cps left
                   (lambda (left-value)
                     (value-of-cps right
                                   (lambda (right-value)
                                     (k (* left-value
                                           right-value))))))]
    [bad-expression
     (error 'value-of-cps "not an arithmetic expression: ~v"
            bad-expression)]))

(define (run expr)
  (value-of-cps expr values))

(module+ test
  (require rackunit)

  (define examples
    (list 7
          '(+ 2 3)
          '(* (+ 2 3) 4)
          '(+ (* 2 3) (+ 4 5))
          '(* (+ 1 (* 2 3)) (+ 4 5))))

  (for ([expr (in-list examples)])
    (check-equal? (run expr)
                  (value-of expr)))

  ;; The CPS invariant also holds for non-identity continuations.
  (check-equal?
   (value-of-cps '(+ (* 2 3) 4) add1)
   (add1 (value-of '(+ (* 2 3) 4))))

  (check-equal?
   (value-of-cps '(* 6 7) number->string)
   (number->string (value-of '(* 6 7))))

  (check-exn #rx"not an arithmetic expression"
             (lambda () (run '(subtract 8 3)))))
```

## Why CPS is useful here

The direct evaluator delegates control sequencing to Racket. The CPS evaluator
represents that sequencing with ordinary values—currently Racket procedures.
That explicit interface gives us a place to study, inspect, and eventually
change the representation of pending evaluation contexts.

Notice what CPS does *not* change:

- the object-language grammar is the same;
- each expression has the same value;
- host arithmetic still combines already-evaluated numbers; and
- recursion still follows immediate syntactic subexpressions.

The representation of control changes; the intended object-language meaning
does not.

## Supervised practice

Trace the following expression under `value-of-cps`:

```racket
'(* (+ 1 2) (+ 3 4))
```

1. List the numeric leaves in the order they are delivered to their immediate
   continuations.
2. State which continuation first remembers the value `3`.
3. State which continuation remembers the value of the entire left operand.
4. Identify every use of host-language arithmetic.
5. Replace the initial continuation with `(lambda (answer) (list 'answer
   answer))` and predict the final result.

The important artifact is the continuation trace, not merely the final number.

## Common mistakes

- **Calling the direct evaluator from the CPS evaluator.** Recursive
  interpretation must preserve the CPS invariant and supply a continuation.
- **Combining syntax instead of values.** Host `+` and `*` receive interpreted
  numbers, not quoted operand expressions.
- **Forgetting the older continuation.** The innermost continuation must send
  the combined result to `k`.
- **Invoking `k` with a partial result.** The continuation for the whole binary
  expression expects the final combined value.
- **Reversing the documented order accidentally.** Evaluating the right operand
  first could preserve the numeric answer here, but it would not implement the
  stated left-to-right control behavior.
- **Thinking the continuation is the answer.** It is a procedure describing
  what should happen *when* an answer becomes available.

## Summary

- The continuation of `value-of-cps` expects the value of the current
  subexpression.
- The central invariant is `(value-of-cps e k) = (k (value-of e))`.
- A literal immediately invokes its continuation with its value.
- A binary expression creates continuations that sequence its operand
  evaluations and combine their values.
- The given evaluator makes left-to-right order explicit.
- CPS changes the representation of control, not the language's intended
  arithmetic meaning.

## Self-check questions

1. What value does the continuation at a recursive evaluator call expect?
2. Why does the addition clause construct two nested continuations?
3. Which free variables must the continuation for the right operand remember?
4. Where does object-language evaluation end and host-language arithmetic
   begin?
5. How does the code record left-to-right evaluation order?
6. Why is testing only with `values` weaker than testing the full invariant?
7. Which parts of the direct and CPS evaluators are structurally alike?

## Acknowledgment

The continuation vocabulary and dependency-oriented presentation build on CPS
notes by Adam Foltzer, adapted for interpreter lectures by Jason Hemann.
