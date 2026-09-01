---
title: "Representation-independent environments and closures"
order: 5
permalink: /lec/representation-independent-environments-closures/
published: true
toc: true
toc_sticky: true
---

Our first interpreter represented an environment as a Racket procedure and an
object-language closure as another Racket procedure. Those choices were
convenient, but they were not part of the object language's meaning. We should
be able to change either representation without rewriting the interpreter.

That is the purpose of **representation independence**: client code depends on
the behavior promised by an interface, not on the concrete data used to
implement that behavior.

## Learning objectives

After working through this note, you should be able to:

- separate an abstract value's interface from one concrete representation;
- state the observable laws for environments and closures;
- identify the interpreter clauses that create and use each abstract value;
- replace functional environments with data-structural environments without
  changing the evaluator;
- replace higher-order closures with data-structural closures without changing
  the evaluator; and
- explain why representation independence is a semantic design principle, not
  merely a code-cleanup technique.

## The problem with using a representation directly

Here is a familiar functional environment:

```racket
(define (empty-env)
  (lambda (name)
    (error 'value-of "unbound variable: ~a" name)))

(define (extend-env name value env)
  (lambda (query)
    (if (eqv? query name)
        value
        (env query))))
```

If the variable clause says `(env name)`, then the evaluator knows that an
environment is a procedure. That knowledge is a dependency. Replacing the
environment with a list or a structure would force us to edit the evaluator.

The same issue appears when the application clause applies a closure as a
Racket procedure. In both cases, the evaluator is coupled to a choice that
ought to remain private to the representation.

The repair has two steps:

1. name the operations that the evaluator actually needs; and
2. require the evaluator to use only those operations.

## The environment interface

An interpreter needs three environment operations:

```text
empty-env  : -> Environment
extend-env : Name x Value x Environment -> Environment
apply-env  : Environment x Name -> Value
```

Their names are less important than their behavior. For any environment `E`,
name `x`, value `v`, and name `y` different from `x`, they should satisfy:

```text
apply-env(extend-env(x, v, E), x) = v
apply-env(extend-env(x, v, E), y) = apply-env(E, y)    when x != y
```

An empty environment has no successful lookup. These laws say what it means
for a representation to behave as an environment. They also explain
shadowing: lookup finds the newest extension with the requested name.

### Two environment representations

A small `env-ops` record will hold the three operations. Its definition appears
in the complete program below; these first snippets let us compare the two
implementations directly.

A functional representation stores the lookup behavior itself:

```racket
(define functional-environments
  (env-ops
   (lambda ()
     (lambda (name)
       (error 'value-of "unbound variable: ~a" name)))
   (lambda (name value env)
     (lambda (query)
       (if (eqv? query name)
           value
           (env query))))
   (lambda (env name)
     (env name))))
```

A data-structural representation records the history of extensions:

```racket
(struct empty-environment () #:transparent)
(struct environment-extension (name value rest) #:transparent)

(define structural-environments
  (env-ops
   empty-environment
   environment-extension
   (lambda (env query)
     (match env
       [(empty-environment)
        (error 'value-of "unbound variable: ~a" query)]
       [(environment-extension name value rest)
        (if (eqv? query name)
            value
            ((env-ops-lookup structural-environments) rest query))]))))
```

These values look completely different in the Racket debugger. Through the
three interface operations, however, they have the same observable behavior.

## The closure interface

For our one-argument language, a closure must preserve:

1. a formal parameter;
2. a body expression; and
3. the environment from the lambda's definition site.

The evaluator needs one operation that constructs this package and one that
applies it:

```text
make-closure  : Name x Expression x Environment -> Closure
apply-closure : Closure x Value x BodyEvaluator -> Value
```

The `BodyEvaluator` argument below is an implementation convenience. It says
how to resume interpretation once the representation reveals the closure's
saved components. The observable closure law is:

```text
apply-closure(make-closure(x, body, saved-E), argument)
  = evaluate body in extend-env(x, argument, saved-E)
```

Notice `saved-E`: lexical scope uses the definition-site environment, not the
environment at the call site.

### Two closure representations

A corresponding `closure-ops` record holds closure construction and
application.

A functional closure stores the future behavior in a Racket procedure:

```racket
(define functional-closures
  (closure-ops
   (lambda (name body saved-env)
     (lambda (argument evaluate-body)
       (evaluate-body name body saved-env argument)))
   (lambda (closure argument evaluate-body)
     (closure argument evaluate-body))))
```

A data-structural closure stores the three components explicitly:

```racket
(struct closure-record (name body saved-env) #:transparent)

(define structural-closures
  (closure-ops
   closure-record
   (lambda (closure argument evaluate-body)
     (match closure
       [(closure-record name body saved-env)
        (evaluate-body name body saved-env argument)]))))
```

Again, the representations differ but the promised behavior does not.

## One evaluator, four combinations

The complete program below packages each interface's operations in a small
Racket structure. `make-evaluator` extracts those operations once. Its
`value-of` function never examines an environment or a closure directly.

```racket
#lang racket

(struct env-ops (empty extend lookup) #:transparent)
(struct closure-ops (make apply) #:transparent)

;; Functional environments
(define functional-environments
  (env-ops
   (lambda ()
     (lambda (name)
       (error 'value-of "unbound variable: ~a" name)))
   (lambda (name value env)
     (lambda (query)
       (if (eqv? query name)
           value
           (env query))))
   (lambda (env name)
     (env name))))

;; Data-structural environments
(struct empty-environment () #:transparent)
(struct environment-extension (name value rest) #:transparent)

(define structural-environments
  (letrec ([operations
            (env-ops
             empty-environment
             environment-extension
             (lambda (env query)
               (match env
                 [(empty-environment)
                  (error 'value-of
                         "unbound variable: ~a"
                         query)]
                 [(environment-extension name value rest)
                  (if (eqv? query name)
                      value
                      ((env-ops-lookup operations) rest query))])))])
    operations))

;; Functional closures
(define functional-closures
  (closure-ops
   (lambda (name body saved-env)
     (lambda (argument evaluate-body)
       (evaluate-body name body saved-env argument)))
   (lambda (closure argument evaluate-body)
     (closure argument evaluate-body))))

;; Data-structural closures
(struct closure-record (name body saved-env) #:transparent)

(define structural-closures
  (closure-ops
   closure-record
   (lambda (closure argument evaluate-body)
     (match closure
       [(closure-record name body saved-env)
        (evaluate-body name body saved-env argument)]))))

(define (make-evaluator environment-operations closure-operations)
  (define empty-env
    (env-ops-empty environment-operations))
  (define extend-env
    (env-ops-extend environment-operations))
  (define apply-env
    (env-ops-lookup environment-operations))
  (define make-closure
    (closure-ops-make closure-operations))
  (define apply-closure
    (closure-ops-apply closure-operations))

  (define (value-of expr env)
    (match expr
      [(? number? n)
       n]

      [(? symbol? name)
       (apply-env env name)]

      [`(* ,e1 ,e2)
       (* (value-of e1 env)
          (value-of e2 env))]

      [`(lambda (,(? symbol? name)) ,body)
       (make-closure name body env)]

      [`(,operator ,operand)
       (define closure
         (value-of operator env))
       (define argument
         (value-of operand env))
       (apply-closure
        closure
        argument
        (lambda (name body saved-env actual)
          (value-of body
                    (extend-env name actual saved-env))))]

      [bad-expression
       (error 'value-of
              "not an expression in the object language: ~v"
              bad-expression)]))

  (lambda (expr)
    (value-of expr (empty-env))))

(module+ test
  (require rackunit)

  (define representation-pairs
    (list
     (list functional-environments functional-closures)
     (list functional-environments structural-closures)
     (list structural-environments functional-closures)
     (list structural-environments structural-closures)))

  (for ([representations (in-list representation-pairs)])
    (match-define (list environments closures) representations)
    (define run (make-evaluator environments closures))

    (check-equal?
     (run '(((lambda (x) (lambda (y) (* x y))) 6) 7))
     42)

    ;; The inner x shadows the outer x.
    (check-equal?
     (run '((lambda (x) ((lambda (x) (* x x)) 5)) 9))
     25)

    ;; f closes over x = 3, not the call site's x = 100.
    (check-equal?
     (run
      '((lambda (x)
          ((lambda (f)
             ((lambda (x) (f 4)) 100))
           (lambda (y) (* x y))))
        3))
     12)))
```

There are two independent choices and therefore four combinations. All four
pass the same tests. This is stronger evidence than testing only the
all-functional and all-structural endpoints: it shows that neither abstraction
secretly relies on the other's representation.

## Reading the evaluator by interface boundaries

Five sites matter:

| Interpreter event | Interface operation |
| --- | --- |
| Begin evaluating a closed program | `empty-env` |
| Enter a closure body | `extend-env` |
| Evaluate a variable reference | `apply-env` |
| Evaluate lambda syntax | `make-closure` |
| Evaluate an application | `apply-closure` |

Everything else in the evaluator works with expressions or ordinary values.
This small table is a useful audit: if the evaluator calls an environment as a
procedure or pattern-matches a closure record, representation knowledge has
leaked across the boundary.

## A worked representation swap

Consider:

```racket
(((lambda (x)
    (lambda (y)
      (* x y)))
  6)
 7)
```

With functional representations:

1. evaluating the outer lambda creates a Racket procedure that captures the
   empty environment;
2. applying it to `6` creates an extended environment procedure;
3. evaluating the inner lambda creates another Racket procedure that captures
   that extended environment;
4. applying it to `7` creates one more environment procedure; and
5. the two lookups return `6` and `7`, whose product is `42`.

With structural representations:

1. evaluating the outer lambda creates a `closure-record` containing the empty
   environment record;
2. applying it to `6` creates an `environment-extension` record;
3. evaluating the inner lambda creates another `closure-record` containing
   that extended environment;
4. applying it to `7` creates another extension record; and
5. recursive `apply-env` calls find `x = 6` and `y = 7`.

The intermediate Racket values change. The object program's result does not.
That is exactly the boundary between representation and meaning.

## Supervised practice

Use this object-language program:

```racket
((lambda (x)
   ((lambda (f)
      ((lambda (x)
         (f 3))
       20))
    (lambda (y)
      (* x y))))
 4)
```

1. Trace it once using structural environments and structural closures.
2. Draw every `environment-extension` and `closure-record` created.
3. Circle the environment saved by the closure bound to `f`.
4. Predict the result before running the evaluator.
5. Switch only the closure representation. Identify which intermediate values
   change and which lookups remain the same.
6. Find every place in `value-of` that would need editing if the interfaces
   were removed.

The important deliverable is the explanation of what remains invariant, not a
picture of one preferred representation.

## Common mistakes

- **Calling a representation an interface.** A list, structure, or procedure is
  a representation. `empty-env`, `extend-env`, and `apply-env` form an
  interface.
- **Changing client code during a representation swap.** If the evaluator must
  change, the old representation was not fully hidden.
- **Testing only one convenient program.** A constant expression cannot reveal
  a broken environment, and a lambda that ignores its free variables cannot
  reveal a broken saved environment.
- **Saving the call-site environment in a closure.** That changes lexical scope
  into dynamic scope; it is not a harmless representation change.
- **Inspecting abstract values for debugging and then depending on their
  shape.** Printed forms may differ even when observable behavior agrees.
- **Confusing `make-closure` with application.** Construction saves code and an
  environment. Application supplies an argument and begins evaluating the
  saved body.
- **Assuming abstraction makes implementations identical.** Representation
  independence permits implementations to differ internally while satisfying
  the same laws.

## Summary

- Representation independence separates observable behavior from concrete
  implementation choices.
- The environment interface consists of construction, extension, and lookup.
- The closure interface consists of construction and application.
- Environment laws explain lookup and shadowing.
- The closure law explains definition-site capture and lexical scope.
- An evaluator that uses only the interfaces can combine functional and
  structural representations independently.
- A successful representation change preserves object-language results even
  though host-language intermediate values change.

## Self-check questions

1. What does the first environment law say about the newest binding?
2. Why does the second environment law require `x != y`?
3. Which environment belongs inside a lexical closure?
4. What representation knowledge leaks through the expression `(env name)`?
5. Why do the four combinations in the test suite provide stronger evidence
   than two endpoint implementations?
6. Can two representations print differently but implement the same abstract
   value? Explain.
7. Which single evaluator clause creates closures, and which one consumes
   them?
8. What semantic change would occur if `apply-closure` extended the caller's
   environment instead of the saved environment?
