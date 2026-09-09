---
title: "Free and bound references and lexical address"
order: 3
permalink: /lec/free-bound-variables-lexical-address/
published: true
toc: true
toc_sticky: true
---

## Learning objectives

- Learn the structure of another recursive datatype: lambda-calculus expressions.
- Distinguish variable declarations from references.
- Explain scope and shadowing, and identify free and bound references.
- Write recursive programs that answer questions about references.
- Find lexical addresses and recognize expressions that differ only in their bound names.

## Lambda-calculus expressions as a datatype

```text
      x, y, z ∈ Vars ::= Symbol
expr, e₁, e₂ ∈ Expr ::= y | (lambda (x) e₁) | (e₁ e₂)
```

There are three and exactly three forms in the lambda calculus. There are
many kinds of lambda calculi, but when we discuss *the* lambda calculus,
this is what we'll mean. We represent variable names with Racket symbols.

```racket
'x
'(lambda (x) x)
'((lambda (x) x) y)
```

The grammar tells us where to recur. A symbol has no recursive parts. A
lambda has one, its body. An application has two, its operator and operand.
The declaration in `(lambda (x) e₁)` is not a recursive `Expr` position.

You can keep this template in a file. Many of our programs will start with
something very similar. Fill in the right-hand sides:

```racket
(define (f expr)
  (match expr
    [`,y #:when (symbol? y)         ]
    [`(lambda (,x) ,body)           ]
    [`(,rator ,rand)                ]))
```

### Work together: a bag of declarations

Write `bag-of-declarations`. It takes an expression and returns a bag of
all the variable declarations in it. A bag keeps duplicates.

```racket
;; Expr -> Listof Symbol
(define (bag-of-declarations expr)
  (match expr
    [`,y #:when (symbol? y)         ]
    [`(lambda (,x) ,body)           ]
    [`(,rator ,rand)                ]))
```

## Declarations and references

A variable **reference** is a use of a variable. A **declaration** introduces
a variable as a name for some value. In

```racket
'(lambda (x) (x y))
```

the `x` in the parameter list is a declaration. The `x` and `y` in the body
are references. We can reach each reference by structural recursion on
`Expr`; we don't recur into the parameter list as though it were an
expression.

### Work together: is there a reference?

For each row, decide whether the expression contains a reference to the
given name. Point to the reference if there is one.

| Name | Expression | Yes or no? |
| --- | --- | --- |
| `z` | `(lambda (z) x)` | |
| `x` | `x` | |
| `y` | `(lambda (x) y)` | |
| `z` | `(lambda (z) (x y))` | |
| `lambda` | `(lambda (lambda) lambda)` | |

## Scope and shadowing

**Scope is the part of the program where a declaration has meaning.**
References to that name in its scope refer to that declaration.

A lambda declaration has scope in its body. A nested declaration of the
same name **shadows** the outer declaration: it makes a hole in the outer
declaration's scope.

```racket
'(lambda (x)
   ((lambda (x) x)
    x))
```

The reference inside the inner lambda refers to the inner declaration.
The final `x` refers to the outer declaration. Inside the inner lambda,
we can't use `x` to refer to the outer declaration.

We can find the declaration for a reference without running the program.
Start at the reference and work outward through the expression to the
nearest enclosing declaration of that name. This is **lexical scope**.
The `lambda` is a **binder**: it connects a declaration with its scope.

## Free and bound references

Free and bound are properties of **references**. A reference is **bound**
in an expression if it is in the scope of a declaration of that name.
Otherwise it is **free** in that expression.

Keep track of which expression we're talking about. The reference in `x`
is free. That same reference, as the body of `(lambda (x) x)`, is bound in
the whole lambda expression.

We'll call our two questions `ref-occurs-free` and `ref-occurs-bound`:
does this expression contain a free reference to `x`, and does it contain
a bound reference to `x`? These aren't opposites. There can be references
of both kinds, or no references to that name at all.

### Work together: free or bound?

Decide what each call should return before running it. For a bound
reference, find its declaration. The final `'()` is an accumulator;
we'll develop that version below.

```racket
(ref-occurs-free 'x 'x '())
(ref-occurs-free 'y 'x '())
(ref-occurs-bound 'x 'x '())
(ref-occurs-bound 'z '(lambda (z) x) '())
(ref-occurs-bound 'y '(lambda (x) y) '())
(ref-occurs-bound 'y '(lambda (y) y) '())
(ref-occurs-free 'x '((lambda (x) x) x) '())
(ref-occurs-bound 'x '((lambda (x) x) x) '())
(ref-occurs-free 'z '((lambda (x) x) x) '())
(ref-occurs-bound 'z '((lambda (x) x) x) '())
```

## An accumulator version

Carry the names declared by the enclosing lambdas in `acc`, with the
nearest declaration first. At the start, `acc` is `'()`. When we enter a
lambda's body, we add its declared name. At a reference, membership in
`acc` tells us whether that reference is bound.

Here `x` is the name we're looking for, `expr` is the expression, and `y`
is the symbol matched at a reference. We use `z` for a lambda's declared
name so we don't hide the `x` we're looking for.

```racket
(define (ref-occurs-free x expr acc)
  (match expr
    [`,y #:when (symbol? y) (and (eqv? x y) (not (memv y acc)))]
    [`(lambda (,z) ,body) (ref-occurs-free x body (cons z acc))]
    [`(,rator ,rand) (or (ref-occurs-free x rator acc) (ref-occurs-free x rand acc))]))

(define (ref-occurs-bound x expr acc)
  (match expr
    [`,y #:when (symbol? y) (and (eqv? x y) (if (memv y acc) #t #f))]
    [`(lambda (,z) ,body) (ref-occurs-bound x body (cons z acc))]
    [`(,rator ,rand) (or (ref-occurs-bound x rator acc) (ref-occurs-bound x rand acc))]))
```

`memv` returns either `#f` or a list. The `if` in `ref-occurs-bound` makes
the result a boolean. In the application clause, both recursive calls
receive the same `acc`: a declaration inside the operator doesn't bind
references in the operand.

**We will not accept accumulator solutions for the free/bound-reference
problems on HW2.** Those problems ask you to work from the recursive
structure of the expression without carrying enclosing declarations.
In the starter, the predicates are named `free-reference-occurs?` and
`bound-reference-occurs?` and each takes two arguments. Keep those names
and argument lists for your submission. The classroom versions above
take three arguments, including the explicit accumulator.

The separate `lex` problem on HW2 **does** take an accumulator, initially
`'()`.

### Collecting names

We can also ask for all the names with free references in an expression,
or all the names with bound references. Order doesn't matter, but don't
return the same name twice.

For `((lambda (x) x) x)`, what should each of those lists contain? Use the
free/bound questions above to explain your answers.

## From names to lexical addresses

We don't need names to figure out the reference. We could get rid of the
names; we just need to know where the reference was bound.

Consider these expressions from our work-together exercise:

```racket
'(lambda (x) (lambda (y) x))
'(lambda (p) (lambda (q) p))
'(lambda (z) (lambda (w) w))
```

In what sense are the first two the same, and different from the third?
Which declaration does the reference use in each one?

The first two are **alpha-equivalent**: changing the bound names hasn't
changed which declaration the reference refers to.

A **lexical address**, or **de Bruijn index**, counts outward from a
reference to its declaration. The nearest enclosing lambda is `0`, the
next is `1`, and so on. Count every enclosing lambda, regardless of its
declared name.

We write a reference with address `0` as `(var 0)`, and one with address
`1` as `(var 1)`. The `var` tag distinguishes a reference from a natural
number; when we include numbers in a language, the numbers themselves
stay untagged. We remove the declared name from each lambda.

### Work together: remove the names

Translate the three expressions above by hand. Then try:

```racket
'(lambda (y) (lambda (x) (x y)))
'(lambda (x) ((lambda (x) x) x))
```

For each reference, point to its declaration and count how far away it is.
Do the first two expressions from the earlier exercise have the same
translation? What happens at the shadowed reference in the last example?

For the HW2 `lex` problem, all references have declarations in the input
expression. Work out the addresses on paper first. Then think about what
information you need to carry so that, when you reach a reference, you
can find its address without going back up the expression.
