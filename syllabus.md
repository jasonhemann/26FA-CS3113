---
title: Course Syllabus
layout: single
toc: true
toc_label: "Syllabus Contents"
toc-depth: 2
to: pdf
standalone: true
documentclass: scrartcl
fontsize: 11pt
geometry:
  - margin=1in
linestretch: 1.15
mainfont: Libertinus Serif
colorlinks: true
---


## Purpose and Objectives

This course studies programming languages from an implementation
perspective. We will implement a small language and repeatedly transform its
evaluator. That process gives us concrete models of binding, scope, parameter
passing, control, abstract machines, and compilation—and a method for learning
and predicting the behavior of unfamiliar languages.

After this course you will be able to:

1. analyze binding structure, free and bound variables, lexical address, and
   substitution;
2. implement interpreters using explicit environments and closures;
3. explain lexical and dynamic scope and compare major parameter-passing
   conventions;
4. transform programs and interpreters into continuation-passing,
   representation-independent, registerized, and trampolined forms;
5. carry an interpreter through the ParentheC transformation pipeline to C;
6. explain how macros, objects, compilers, and domain-specific languages fit
   into the larger language-implementation picture; and
7. defend the design and behavior of code you submit.

This syllabus contains policies and expectations I have established
for {{ site.title }}. Please read carefully the entire syllabus before
continuing in this course. I intend for these policies and
expectations to create a productive learning atmosphere for all
students. Unless you are prepared to abide by these policies and
expectations, you risk losing the opportunity to participate further
in the course. Policies and expectations as set forth in this syllabus
may be modified at any time by the course instructor. Notice of such
changes will be made by announcement in class, by written or email
notice, or by changes to this syllabus posted on the course website.

## Contact

The best way to get in contact for personal or private (FERPA, etc.)
messages is via my email address,
[{{ site.author.email }}](mailto:{{ site.author.email }}). You
should expect a response within 48 hours. Questions whose answers would help
the class should go through the course discussion forum once that forum is
announced.

A great regular way to reach out for help is via our [office
hours]({{ site.baseurl }}/office-hours/).

## Grade Breakdown

I will assign overall course grades as follows.

| Component | Weight |
|---|---:|
| Exam 1 | 15% |
| Exam 2 | 15% |
| Exam 3 | 15% |
| Closed-resource paper verification quizzes (best seven of eight) | 25% |
| Assignment artifacts (Assignments 1-9; 2% each) | 18% |
| Assignment 3 code review | 4% |
| Assignment 9 code review | 8% |
| **Total** | **100%** |

Homework is indispensable practice, but unsupervised programming alone no
longer provides sufficiently reliable evidence of individual mastery. Each
homework artifact is therefore graded separately from any associated code
review. Assignments 3 and 9 each have a separate, numerically scored code
review in addition to their ordinary homework artifact. The cumulative
Assignment 9 review carries more weight than the earlier Assignment 3 review.

### Letter Grades

Course totals are converted using Seton Hall's default Canvas grading scheme.
An exact cutoff belongs to the grade beginning at that cutoff.

| Letter grade | Course total |
|---|---:|
| A | 94% or higher |
| A− | at least 90% and below 94% |
| B+ | at least 87% and below 90% |
| B | at least 84% and below 87% |
| B− | at least 80% and below 84% |
| C+ | at least 77% and below 80% |
| C | at least 74% and below 77% |
| C− | at least 70% and below 74% |
| D+ | at least 67% and below 70% |
| D | at least 64% and below 67% |
| D− | at least 61% and below 64% |
| F | below 61% |

## Participation

I expect you to attend each class and remain throughout the session. Regular
attendance is necessary because lectures develop code and transformations
that are difficult to reconstruct from finished files alone. Attendance is
not separately scored. Some class time will be supervised practice: you will
attempt a small problem before we work its solution together. That practice
is not collected or graded. Quizzes, exams, and required code reviews provide
the scored evidence of your understanding. An absence does not by itself
remove a course requirement; contact me promptly about documented or
exceptional circumstances.


### Verification Quizzes

The schedule contains eight short paper verification quizzes, one associated
with each of Assignments 1-8. They normally occupy the first 10-15 minutes of
class and are individual, closed-resource, and closed-device. Each quiz covers
one objective that has already been taught and attempted during supervised
practice, normally the objective associated with the preceding assignment.

Each quiz is scored on a single 0-4 scale:

- **4:** correct result and correct mechanism;
- **3:** correct mechanism with a minor computational or syntactic error;
- **2:** meaningful progress showing a partially correct model;
- **1:** relevant attempt but substantial misunderstanding; and
- **0:** absent, irrelevant, or no usable evidence.

The best seven of the eight written quizzes count. Their points are summed out
of 28 and scaled to the verification-quiz component in the grade breakdown.
The dropped score absorbs one absence. For additional documented absences, I
will offer one scheduled,
cumulative paper-makeup window; I will not create bespoke individual makeup
quizzes.

## Homework

The course has nine independent programming assignments, Assignments 1-9.
Each submitted artifact is a separate, equally weighted grade item. Regular
assignments are released Mondays at approx 6 p.m. Eastern,
and normally close the following Sunday at 10 p.m. Some assignments have
deliberately longer windows, around holidays, exams, and scheduled
breaks. Release dates appear on the
[schedule]({{ site.baseurl }}/schedule/); exact deadlines are stated with each
assignment.

Assignments 1-8 receive automated submission-completion and basic-test credit
only; routine individual written feedback is not part of their grading. I will
love to go over them with you at office hours.

Later assignments deliberately depend on earlier work:

- Assignment 4 reuses corrected pieces of Assignments 2 and 3.
- Assignment 7 builds on the CPS methods of Assignment 6.
- Assignment 9 begins from a corrected, staged Assignment 7 interpreter.

Do not wait until a deadline to discover that a prerequisite is incomplete.
Seek feedback, correct earlier work, and preserve the intermediate program
versions requested by an assignment. Submission of working output is not a
substitute for being able to explain the program.

## Exams

There are three 75-minute in-class exams. Dates are provided on the
[schedule]({{ site.baseurl }}/schedule/).
Exams are individual and closed-resource unless I explicitly announce a
different rule. They are also closed-device. Each exam is preceded by a
scheduled review. Exam 1 is
cumulative through Assignment 4. Exam 2 is cumulative through registerization
and trampolining; Assignment 9 itself is not tested on Exam 2. Exam 3 is
cumulative and includes regression from the first two exams. There is no
additional written final examination.

## Assignment 3 and Assignment 9 Code Reviews

Assignments 3 and 9 each include a separately graded, individual review of the
submitted interpreter, lasting about ten minutes. See the
[code-review page]({{ site.baseurl }}/viva/) for preparation and what to expect.

A review passes when you demonstrate understanding and ownership of the
submitted work; otherwise it is recorded as **Not yet** and must be repeated. A
passing review receives one holistic rating:

- **Convincing:** independent, accurate understanding throughout;
- **Solid:** sound overall understanding with limited gaps or prompting; or
- **Minimum pass:** adequate understanding and ownership of the central
  mechanisms, despite gaps or substantial prompting on nonessential points.

Each assignment maps these ratings to its own point values.

Lateness and reassessment lower the maximum score, not the passing standard.
Assignments 3 and 9 accrue penalty units separately. Each completed
**Not yet** review or unarranged no-show adds one unit. An unexcused Calendar
booking period with no substantive review adds one unit; a no-show in that
period is not counted twice. Artifact lateness has its own consequence and adds
no review unit beyond a missed booking period. Approved accommodations,
documented exceptional circumstances, lack of instructor availability, and
technical failures despite reasonable preparation add no unit.

A passing review earns the lower of its quality score and the cap for its
accumulated units. Earlier **Not yet** reviews affect only the cap, not the
quality score. The cap never falls below the minimum passing score, but the
grade remains incomplete until the review passes. That passing review's capped
score is final.

Each assignment provides its point values and cap table, Calendar schedule
link, required files, checkpoints, and scope, and absolute grading deadline. The
Calendar alone shows current appointment availability. Contact me promptly
about conflicts; approved exceptions may receive an adjusted deadline. Do not
share a review prompt with a student who has not yet completed that review.

Both reviews must be passed by their stated or approved adjusted deadlines to
receive a passing course grade.

## Course evaluations

I encourage students to take time and submit Course evaluations. Your
time is busy at the end of the term when these are available. In order
to fairly compensate you for that time without violating the integrity
or anonymity of the system, if 85% or more of the enrolled students
complete these Course evaluations, then I shall add one percentage point to
each student's course total before converting totals to letter grades.

## Lecture

The vast majority of course content will come from in-class lecture,
supplemented with notes distributed online. Therefore, attending
lecture is of the utmost importance. *You should make every effort to
attend each lecture, and take vigorous notes.* We will often provide
directly the answers to homework problems in lecture, and this course
is significantly more difficult for the student who misses one or more
lectures. There are no substitutes for participating in class
activities. We will sometimes distribute electronic transcripts of the
in-class code, but this is no substitute for careful notes and
understanding its development. Regular class attendance is a student's
obligation, as is responsibility for all the content of class
meetings, including tests.

You should plan to have with you tools to take vigorous notes. I have
traditionally found the use of
laptops and cell phones in the classroom disruptive. The use of cell
phones, smart phones, or other mobile communication devices is
disruptive, and is therefore prohibited during class. Pencil
and paper, or some electronic tablet version of the aforementioned,
are especially effective. Laptops or other devices may be used when I direct
the class to program, test, or inspect an electronic artifact. Otherwise,
laptops and phones should remain put away; a non-disruptive tablet may be used
for note taking. Quizzes and exams are closed-device.

I do not permit electronic video and/or audio recording of class
without prior permission. Unless the student obtains permission from
the instructor electronic video and/or audio recording of class is
prohibited. If you receive permission, any distribution of the
recording is prohibited. Students with specific electronic recording
accommodations authorized by the [DSS](#academic-accommodations) do not
require instructor permission; however, the instructor must be
notified of any such accommodation prior to recording. Any
distribution of such recordings is prohibited.

## Additional Support

In addition to lecture, we provide the following additional resources
for students to avail themselves. Do consider taking regular advantage
of them.

### Scheduled Office Hours

I hold office hours Tuesdays from 8:00 to 9:30 a.m. in McQuaid Hall 210. See
the [office-hours page]({{ site.baseurl }}/office-hours/) for any updates. If
these hours are particularly ill-suited to your class schedule, contact me to
arrange an appointment.

## Academic Integrity

Seton Hall University's academic integrity policy applies to this
course. Students are responsible for understanding and complying with
the University's standards and procedures regarding plagiarism,
cheating, unauthorized collaboration, falsification, and other forms
of academic dishonesty. The official University policy is published in
the undergraduate catalog's [Academic Policies and
Procedures](https://catalogue.shu.edu/undergraduate/academic-policies-procedures/).

All submitted work must be properly attributed. Any outside assistance,
including people, internet resources, and AI tools, must be disclosed exactly
as the assignment directs. Working output alone does not establish mastery;
paper quizzes, exams, and individual code reviews provide the supervised
evidence of your own understanding. During those assessments, use only the
resources explicitly permitted for that assessment.

## Academic Accommodations {#academic-accommodations}

It is the policy and practice of Seton Hall University to promote
inclusive learning environments. If you have a documented disability
you may be eligible for reasonable accommodations in compliance with
University policy, the Americans with Disabilities Act, Section 504
of the Rehabilitation Act, and/or the New Jersey Law against
Discrimination. Please note, students are not permitted to negotiate
accommodations directly with professors. To request accommodations or
assistance, please self-identify with the [Office for Disability
Support Services (DSS)](https://www.shu.edu/disability-support-services/),
Duffy Hall, Room 67 at the beginning of the semester. For more
information or to register for services, contact DSS at
(973) 313-6003 or by e-mail at [DSS@shu.edu](mailto:DSS@shu.edu).

## Equity and Compliance

One of our responsibilities in supporting student learning 360° is to
help create a safe learning environment both in person and virtually.
You should carefully consult the university's [relevant information
and policies](https://www.shu.edu/title-ix/index.cfm), and if you have
or experience any violations of the above I encourage you to take full
advantage of the university resources.

It is also important that you know that federal regulations and
University policy require me to promptly convey any information about
certain kinds of misconduct known to me to our Title IX Coordinator.
In that event, they will work with a small number of others on campus
to ensure that appropriate measures are taken and resources are made
available to the student who may have been harmed. Protecting a
student's privacy is of utmost concern, and all involved will only
share information with those that need to know to ensure the
University can respond and assist.

## Technology and Platforms

We will use a variety of tools and platforms to facilitate teaching
and learning over the semester. Please see the [technology page]({{
site.baseurl }}/tech/) for more details.

## Acknowledgments

Thanks over the years for inspiration and content from at least the
following: Dan Friedman, Shriram Krishnamurthi, Lindsey Kuper, and
Marco Morazán.

![In the syllabus]({{ site.baseurl }}/assets/images/syllabus.gif "Might just be worth checking.")
