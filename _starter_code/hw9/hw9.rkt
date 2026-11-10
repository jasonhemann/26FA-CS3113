#lang racket
(require "parenthec.rkt")

;; Release tooling loads this file while it is still incomplete. Keep
;; the filename and the main interface unchanged; replace the paste
;; placeholders below with your own corrected Assignment 7 work.

(provide main)

#| Assignment 9: ParentheC Interpreter |#

;; Code should run as fast as necessary, but no faster; something
;; important is always traded away to increase speed.
;;
;; Richard Pattis

;; This, but un-ironically:
;; https://www.reddit.com/media?url=https%3A%2F%2Fi.redd.it%2Ffe96ionbykj01.jpg

#| ===== Assignment Guidelines ===== |#

;; In addition to the standard Assignment Guidelines and the course
;; code-review page (https://hemann.pl/26FA-CS3113/viva/), follow the
;; assignment-specific artifact and review requirements below.


;; This assignment relies on your successful completion of hw7. If you
;; haven't successfully completed hw7 and maintained the versions of
;; your code along the way, please completely correct that before
;; starting this assignment. You will be much happier.

;; Your assignment is to complete the transformation of your
;; interpreter from hw7 to a version we can translate to C.

;; When your interpreter is complete, turn it into C programs using
;; pc2c, and run the test program provided.

;; Save a new copy of your interpreter after you finish every
;; step. **You must preserve all named checkpoints for submission and
;; for your code review.** Also, you will likely need
;; at some point to go back to an older version of your interpreter to
;; correct a mistake; having copies of all previous steps will save a
;; lot of time.

;; Submit the structured zip specified below. Its interp.pc must be
;; the final source you translate with pc2c.

;; Assignment 9 has two distinct grade items: this submitted artifact and
;; an individual code review. Preserve your intermediate versions.
;; Bring an extracted, unmodified copy of your submitted zip. During the
;; review you may consult only its saved intermediate versions,
;; interp.pc, and the two supplied tools.
;; The syllabus defines the shared pass, understanding, quality,
;; penalty-unit, and floor policy. Assignment 9 uses these numerical
;; quality anchors:
;;
;;   Convincing:   8/8
;;   Solid:        6/8
;;   Minimum pass: 4/8
;;
;; Its accumulated penalty units cap a successful review as follows:
;;
;;   Penalty units   Maximum score
;;   0               8/8
;;   1               7/8
;;   2               6/8
;;   3               5/8
;;   4 or more       4/8
;;
;; The recorded score is the lower of the holistic quality score and
;; this cap. The cap floor does not itself establish a pass.
;;
;; Book your first review through the CSAS 3113 code-review booking page:
;; https://hemann.pl/book/csas-3113-code-review/
;; Make one booking for this assignment. If your review is marked Not yet,
;; arrange the next attempt with me directly; retries are not self-service.
;; The booking page is the sole current source for bookable dates,
;; times, and sign-up availability; those changing details are not
;; duplicated here.
;;
;; You must pass this review no later than Friday, December 11, 2026, at
;; 5:00 p.m. Eastern, the absolute Assignment 9 code-review grading deadline.
;;
;; The named checkpoints and course concepts in this assignment define
;; the review's scope; the conversation does not follow a fixed question
;; family or sequence.

;; Read the ParentheC paper, "Using ParentheC to Transform Scheme
;; Programs to C or How to Write Interesting Recursive Programs in a
;; Spartan Host":
;; https://github.com/jasonhemann/22SU-CS4400/blob/fffd7dbe4c1fe942a03926f8287bdd813a1dc51e/assets/docs/parenthec.pdf
;; The release folder provides parenthec.rkt and
;; pc2c.rkt; use those exact copies.

;; You will also need to use the following define-union for
;; expressions and main program:

(define-union expression
  (const cexp)
  (var n)
  (if test conseq alt)
  (mult nexp1 nexp2)
  (sub1 nexp)
  (zero nexp)
  (letcc body)
  (throw kexp vexp)
  (let exp body)
  (lambda body)
  (app rator rand))




;; PASTE YOUR VALUE-OF-CPS, APPLY-K, APPLY-ENV, APPLY-CLOSURE, AND
;; THEIR CONSTRUCTORS HERE. Begin by replacing these load-only
;; placeholders with your own corrected Assignment 7 definitions.

(define (value-of-cps expr env k)
  (error 'value-of-cps "paste your corrected Assignment 7 definition here"))

(define (empty-env)
  (error 'empty-env "paste your corrected Assignment 7 definition here"))

(define (empty-k)
  (error 'empty-k "paste your corrected Assignment 7 definition here"))


;; (let ((f (lambda (f)
;;            (lambda (n)
;;          (if (zero? n)
;;          1
;;              (* n ((f f) (sub1 n))))))))
;;   (* (letcc k ((f f) (throw k ((f f) 4)))) 5))

;; The above program, translated
;; Notice that this test program is not quoted data.

(define main
  (lambda ()
    (value-of-cps
     (expression_let
      (expression_lambda
       (expression_lambda
        (expression_if
         (expression_zero (expression_var 0))
         (expression_const 1)
         (expression_mult (expression_var 0) (expression_app (expression_app (expression_var 1) (expression_var 1)) (expression_sub1 (expression_var 0)))))))
      (expression_mult
       (expression_letcc
        (expression_app
         (expression_app (expression_var 1) (expression_var 1))
         (expression_throw (expression_var 0) (expression_app (expression_app (expression_var 1) (expression_var 1)) (expression_const 4)))))
       (expression_const 5)))
     (empty-env)
     (empty-k))))




#| ===== Project Part II ===== |#

#| Submission archive contract

Submit one zip containing exactly one final interp.pc and the
intermediate source versions you kept while completing the numbered
transformations in a7 and those described below. If you made
corrections to your a7 code in the meantime, submit the corrected
versions instead. You may include more files than these, and you may
use directories and structure. Gradescope will expand the zip when you
upload it; the grader searches the resulting file tree for that
uniquely named file, as well as your other code. You need not submit
generated C or header files, nor copies of the supplied tools.

To make the zip, put interp.pc, and your saved intermediate source
files in a folder such as a9-submission/; subfolders are fine. From
that folder's parent directory, create a fresh archive with:

  zip -r a9-submission.zip a9-submission

Or use your computer's file manager to create a zip archive of that
folder. Open the zip to check its contents, then upload the zip file
to the Assignment 9 artifact dropbox in Gradescope. Do not upload
interp.pc or the folder by itself.

Name the intermediate files clearly so we can tell which numbered
steps each file represents. The final interp.pc must be
self-contained.

The grader uses an instructor-owned copy of pc2c.rkt to translate
the submitted interp.pc, compiles the generated C and header files,
runs the executable, and checks for a successful execution. You should
still run the supplied test program yourself and check that it
computes 120.

After Gradescope expands it, the grader rejects submissions with more
than 256 entries, any file over 8 MiB, interp.pc over 2 MiB, or more
than 64 MiB of uncompressed content.

|#

#|

1. Here are the steps you will need to accomplish:

  1. Copy the relevant parts (Part II) of your fully correct version
     of your final product from assignment 7 into this file where
     indicated. Do not copy over the tests, however. Use the supplied
     parenthec.rkt in the same directory as this file. Change the
     match-expression in value-of-cps to instead be a
     union-case-expression. Consult the
     ParentheC paper or the example from class to see how to do this. Make
     sure to remove the backquotes and commas in the patterns of what was
     your match expression. Ensure `main` is below your interpreter, and
     make sure it returns 120 when you invoke it.

  2. Transform your closure constructor to a define-union, change the
     match in apply-closure to instead use union-case, and ensure that your
     constructor invocations are preceded with clos_, or something other
     than clos if you use a different name for your union. Make sure to
     remove the backquotes and commas in the patterns in what was your
     match expression.

  3. Transform your environment constructors to a define-union, change
     the match in apply-env to instead use union-case, and ensure all
     constructor invocations are preceded with envr_, or something other
     than envr if you use a different name for your union. Make sure to
     remove the backquotes and commas in the patterns in what was your
     match expression.

  4. Transform your continuation constructors to a define-union,
     change the match in apply-k to instead use union-case, and ensure all
     constructor invocations are preceded with kt_, or something other
     than kt if you use a different name for your union. Make sure to
     remove the backquotes and commas in the patterns in what was your
     match expression.

  5. Transform all your serious function calls to our A-normal form
     style, by adding let* above your serious calls, and ensuring that the
     names of the actual parameters to the serious calls are *exactly* the
     names of the formal parameters in the definition.

  6. Registerize the interpreter. Turn each let* expression to a begin
     block: the former let* bindings will become set! expressions, and the
     body becomes the invocation of a function of no arguments. Change all
     serious functions to be functions of no arguments. Define your global
     registers using define-registers at the top of the program.

  7. Change all of your (define name (lambda () ...)) statements to
     instead use define-label. Define your program counter at the top of
     the program using define-program-counter.

  8. Convert all label invocations into assignments to the program
     counter, and then add calls to mount-trampoline and
     dismount-trampoline. Note this will require modifying empty-k in your
     kt union, and the empty-k clause in the union-case inside apply-k. On
     the last line of main, print the register containing the final value
     of the program, e.g. (printf "Fact 5: ~s\n" v) See the ParentheC
     document for notes on these steps.

  9. Comment out the lines `#lang racket`,
     `(require "parenthec.rkt")`, and `(provide main)`. If you added it
     to your file, also comment your invocation of main (that is
     `(main)` but leave the definition of main intact). And save a copy
     of this file named interp.pc.

   After all checkpoints are complete, translate the exact submitted
   interp.pc with the supplied translator:

       racket -e '(require "pc2c.rkt") (pc2c "interp.pc" "a9.c" "a9.h")'
       cc -o a9 a9.c
       ./a9

   The generated program must complete and print the expected result.
   Compilation warnings from the legacy translator are not, by
   themselves, failures; compilation errors or an incorrect result are.

   Keep the generated a9.c and a9.h beside interp.pc while testing.
   Submit interp.pc in the zip; generated C and header files are optional.

|#

#| ===== Optional enrichment =====

Problems 2–3 are optional. Gradescope does not require or test them.
They extend the ParentheC pipeline in worthwhile directions, and you
are strongly encouraged to attempt them. They deliberately have no
starter stubs.

|#

#| ===== Just Dessert ===== |#

;; 2. Add a callcc form to your interpreter that behaves like Racket's
;; call/cc. Change the test program to one that uses callcc and send
;; this, along with any other required changes, to office hours for
;; discussion.

;; 3. Hosts more spartan. If you have another nasty, spartan, ornery
;; host language in mind, and you'd like to hand compile to that
;; language or write yourself a transpiler for that host, do so. Send
;; Jason the upshot of your work. Interesting hosts might lack a
;; garbage collector, higher-order procedures, and/or tail-call
;; optimization. Java would, for instance, be an interesting choice
;; for a transpiler. DCL, Pascal, wasm, BLISS, etc might also make
;; interesting choices. Complete the required C path first; then ask
;; for pre-clearance on an additional target so we can agree on a
;; useful scope and test.
