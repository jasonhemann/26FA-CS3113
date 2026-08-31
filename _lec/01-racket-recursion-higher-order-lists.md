---
title: "Racket recursion and higher-order list programming"
order: 1
permalink: /lec/racket-recursion-higher-order-lists/
published: true
toc: true
toc_sticky: true
---

Racket makes the structure of data unusually visible. A list is either empty
or it has a first item and a smaller list containing the remaining items. Good
list programs follow that same division: handle the empty list, then solve a
nonempty list using the answer for its tail.

This correspondence between a data definition and a program is our first
recurring method for designing language tools.

## Learning objectives

After working through this note, you should be able to:

- distinguish proper lists from general pairs;
- derive a structurally recursive list function from the shape of its input;
- state what a recursive call promises to compute;
- explain why `map`, `filter`, and `foldr` are higher-order functions;
- express common traversals using those higher-order operations; and
- recognize recursion that fails to make progress toward its base case.

## Pairs and proper lists

`cons` constructs a pair. `car` selects its first field and `cdr` selects its
second:

```racket
(cons 'cat 3)            ; a pair, but not a proper list
(car (cons 'cat 3))      ; => 'cat
(cdr (cons 'cat 3))      ; => 3
```

A **proper list** is a more specific, recursively defined kind of value:

```text
List-of-A ::= '()
            | (cons A List-of-A)
```

The second field of every pair in a proper list is another proper list. Thus
`'(cat dog owl)` is shorthand for:

```racket
(cons 'cat (cons 'dog (cons 'owl '())))
```

The empty list is written `'()`. For a nonempty proper list `xs`, `(car xs)` is
its first item and `(cdr xs)` is the strictly smaller list containing the rest.
That smaller value is what makes structural recursion possible.

## The natural-recursion template

When a function consumes a proper list, begin with the cases in the data
definition:

```racket
(define (process-list xs)
  (cond
    [(empty? xs) ...]
    [else
     ... (car xs) ...
     ... (process-list (cdr xs)) ...]))
```

The recursive call is not a ritual. It comes with a precise promise:

> `(process-list (cdr xs))` produces the complete answer for every item after
> the first one.

The nonempty case must combine `(car xs)` with that promised answer. Because
`(cdr xs)` is structurally smaller than `xs`, repeated recursive calls
eventually reach `'()`.

## A counting example

Suppose `count` should report how many times a value occurs in a list.

```racket
(define (count target xs)
  (cond
    [(empty? xs) 0]
    [(eqv? target (car xs))
     (add1 (count target (cdr xs)))]
    [else
     (count target (cdr xs))]))
```

The base answer is zero because an empty list has no occurrences. In the
nonempty case, the recursive call counts all occurrences in the tail. If the
first item is the target, the complete answer is one more; otherwise it is
exactly the tail's answer.

### A complete trace

Evaluate `(count 'a '(a b a))` by following the calls:

```text
(count 'a '(a b a))
= 1 + (count 'a '(b a))
= 1 +     (count 'a '(a))
= 1 + 1 + (count 'a '())
= 1 + 1 + 0
= 2
```

At every line, the unexpanded recursive call still means “the number of `a`s
in this remaining suffix.” That is the function's **recursive invariant**.

## Reconstructing a list

Functions that return lists usually reconstruct their results with `cons`.
This function removes every occurrence of a target:

```racket
(define (remove-all target xs)
  (cond
    [(empty? xs) '()]
    [(eqv? target (car xs))
     (remove-all target (cdr xs))]
    [else
     (cons (car xs)
           (remove-all target (cdr xs)))]))
```

There are two distinct nonempty cases:

- when the first item should be discarded, return the processed tail;
- when it should be retained, put it in front of the processed tail.

Notice that this function constructs a new list. It does not mutate the input.

Here is a transformation that can add more than one output item for a single
input item:

```racket
(define (put-y-after-x xs)
  (cond
    [(empty? xs) '()]
    [(eqv? (car xs) 'x)
     (cons 'x
           (cons 'y
                 (put-y-after-x (cdr xs))))]
    [else
     (cons (car xs)
           (put-y-after-x (cdr xs)))]))
```

For example, `(put-y-after-x '(x b x))` produces `'(x y b x y)`.

## Functions are values

Racket procedures are ordinary values. A `lambda` expression constructs an
anonymous procedure:

```racket
(lambda (n) (* n n))
```

It can be stored, passed to another procedure, or returned as a result:

```racket
(define square
  (lambda (n) (* n n)))

(define (make-adder amount)
  (lambda (n) (+ amount n)))

(define add3 (make-adder 3))
(add3 10)                       ; => 13
```

A function that consumes or produces another function is **higher order**.
Higher-order functions let us separate the traversal of a data structure from
the operation performed at each element.

## Three higher-order traversals

### `map`: transform every item

`map` preserves the list's length and applies a function to each item:

```racket
(map square '(2 3 4))           ; => '(4 9 16)
```

Its structural definition is:

```racket
(define (my-map f xs)
  (cond
    [(empty? xs) '()]
    [else
     (cons (f (car xs))
           (my-map f (cdr xs)))]))
```

### `filter`: retain selected items

`filter` consumes a predicate—a function whose result is used as true or
false—and keeps exactly the items for which it succeeds:

```racket
(filter even? '(1 2 3 4 5 6))  ; => '(2 4 6)
```

```racket
(define (my-filter keep? xs)
  (cond
    [(empty? xs) '()]
    [(keep? (car xs))
     (cons (car xs)
           (my-filter keep? (cdr xs)))]
    [else
     (my-filter keep? (cdr xs))]))
```

### `foldr`: replace the list constructors

`foldr` captures a more general pattern. It replaces each `cons` with a
combining function and replaces `'()` with a base value:

```racket
(define (my-foldr combine base xs)
  (cond
    [(empty? xs) base]
    [else
     (combine (car xs)
              (my-foldr combine base (cdr xs)))]))
```

For the list `'(a b c)`, the result has this shape:

```text
(combine 'a (combine 'b (combine 'c base)))
```

This is why the operation is called a right fold: the nested computation is
associated to the right.

Many familiar functions are folds:

```racket
(define (length/fold xs)
  (foldr (lambda (_item tail-length)
           (add1 tail-length))
         0
         xs))

(define (sum xs)
  (foldr + 0 xs))

(define (copy-list xs)
  (foldr cons '() xs))
```

In `length/fold`, the first argument to the combining function is deliberately
unused: every element contributes one regardless of its value.

## One runnable development

The definitions below can be saved together and run as a complete Racket
module:

```racket
#lang racket

(define (count target xs)
  (cond
    [(empty? xs) 0]
    [(eqv? target (car xs))
     (add1 (count target (cdr xs)))]
    [else
     (count target (cdr xs))]))

(define (remove-all target xs)
  (cond
    [(empty? xs) '()]
    [(eqv? target (car xs))
     (remove-all target (cdr xs))]
    [else
     (cons (car xs)
           (remove-all target (cdr xs)))]))

(define (put-y-after-x xs)
  (cond
    [(empty? xs) '()]
    [(eqv? (car xs) 'x)
     (cons 'x (cons 'y (put-y-after-x (cdr xs))))]
    [else
     (cons (car xs) (put-y-after-x (cdr xs)))]))

(define (my-map f xs)
  (cond
    [(empty? xs) '()]
    [else
     (cons (f (car xs))
           (my-map f (cdr xs)))]))

(define (my-filter keep? xs)
  (cond
    [(empty? xs) '()]
    [(keep? (car xs))
     (cons (car xs)
           (my-filter keep? (cdr xs)))]
    [else
     (my-filter keep? (cdr xs))]))

(define (my-foldr combine base xs)
  (cond
    [(empty? xs) base]
    [else
     (combine (car xs)
              (my-foldr combine base (cdr xs)))]))

(module+ test
  (require rackunit)

  (check-equal? (count 'a '(a b a c a)) 3)
  (check-equal? (remove-all 8 '(8 1 8 2 3 8)) '(1 2 3))
  (check-equal? (put-y-after-x '(x b x)) '(x y b x y))
  (check-equal? (my-map add1 '(3 4 5)) '(4 5 6))
  (check-equal? (my-filter symbol? '(a 1 b 2 c)) '(a b c))
  (check-equal? (my-foldr + 0 '(10 20 30)) 60)
  (check-equal? (my-foldr cons '() '(a b c)) '(a b c)))
```

## The central distinctions

Keep these ideas separate:

| Idea | Question it answers |
| --- | --- |
| Data definition | What shapes can the input have? |
| Structural recursion | Which smaller component should the function process next? |
| Recursive invariant | What complete answer does the recursive call promise? |
| Higher-order argument | Which behavior varies while the traversal stays fixed? |

`map`, `filter`, and `foldr` are not alternatives to recursion. They package
common recursive traversals so that a caller supplies only the varying part.

## Supervised practice

Work with a partner. Start from a data definition and write down the promise
made by each recursive call before writing code.

1. Define `duplicate-symbols`, which duplicates symbols but leaves other list
   elements single. For example, `'(a 7 b)` should become `'(a a 7 b b)`.
2. Define `product` by structural recursion, then express it with `foldr`.
3. Express “square every odd number and discard every even number” as a
   composition of `filter` and `map`.
4. Predict the fully nested expression produced by
   `(foldr string-append "!" '("a" "b" "c"))` before running it.
5. For each definition, identify the smaller input and state why computation
   must eventually reach the base case.

## Common mistakes

- **Calling `car` or `cdr` before checking for `'()`.** Neither operation is
  defined on the empty list.
- **Assuming every pair is a proper list.** `(cons 'a 'b)` is a pair whose
  second field is not a list.
- **Recursing on the original input.** A call such as `(f xs)` inside `f` makes
  no structural progress.
- **Forgetting to use the recursive result.** Recomputing the tail or returning
  only `(car xs)` loses the answer for the rest of the list.
- **Putting `cons` around the wrong cases.** Filtering out an item means
  returning the processed tail without reconstructing that item.
- **Confusing a function with a call.** `square` is a procedure value;
  `(square 5)` applies it and produces a number.
- **Expecting `map` to remove items.** `map` produces one result for each input
  item; `filter` may change the length.
- **Treating `foldr`'s base as an afterthought.** The base is the meaning of the
  empty list and usually determines the kind of result being built.

## Summary

- Proper lists are generated from `'()` and `cons`.
- A structurally recursive list program mirrors those two cases.
- The recursive call computes a complete answer for a structurally smaller
  input.
- Procedures are values, so programs can consume and return them.
- `map` transforms, `filter` selects, and `foldr` replaces the constructors of
  a list with a chosen computation.
- Naming the recursive invariant turns code tracing into an explanation of why
  the program works.

## Self-check questions

1. What additional condition turns a chain of pairs into a proper list?
2. Why is `(cdr xs)` a suitable recursive input when `xs` is nonempty?
3. What does the recursive call in `remove-all` promise to return?
4. Which of `map`, `filter`, and `foldr` necessarily preserves list length?
5. What two replacements does `foldr` make in the list's construction?
6. Why is `make-adder` higher order even though its argument is a number?
7. How can you tell, before running it, that a structurally recursive function
   will reach its base case?
