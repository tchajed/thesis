# Goose

The transaction system is implemented in Go and verified in Perennial. To carry
this out, we need a way to connect the implementation to something Perennial can
reason about. The approach we take is to translate the implementation into a
model in Perennial. As long as the model exhibits all the behaviors of the real
code, then a specification proven for the model should hold for the real Go code.

The verification infrastructure for the transaction system is all developed as
part of this thesis. This chapter describes the overall approach, which we call
Goose. (We will also use Goose in some places to refer to the subset of Go
supported.) The next chapter goes into the reasoning in Perennial on top. Before
we can translate Go code, we need some way of writing a model of the source
code. It turns out to be convenient to use another programming language for this
purpose, which we call GooseLang. After translating, we will want to carry out
proofs on top of the generated GooseLang code, so in chapter 3.3 we talk about
the reasoning principles we have for GooseLang.

This chapter is intentionally fairly independent of the rest of the thesis for a
reader interested in verifying Go code but not the specifics of the transaction
system proof or the file system built on top. Crash safety is also of little
importance in this chapter. We focus on normal execution of Go here; crashes are
modeled simply by stopping execution and wiping out all of the state except for
the disk. The next chapter on Perennial talks about how to reason about crashes
as specified in this way.

## Why Go?

Go turns out to be a very convenient language for building verification
infrastructure. The goose translator effectively gives a semantics to the source
code, in the form of the semantics of the generated GooseLang code. For the
verification to be meaningful, the translation must preserve the semantics of
the source, or at least over-approximate it.

We needed to build the translator while being careful to capture the source code
accurately. One highly practical aspect of Go is that it has good tooling,
including libraries for parsing and type-checking Go source code. Not only do
these libraries save time in implementing Goose, they greatly improve
reliability since they are written by experts (the Go compiler team, extracting
code from the compiler itself).

In addition to having an accurate syntax tree and even types for the source
code, Go is a simple language. There wasn't much in the way of syntax that we
needed before the Goose subset of Go was sufficient to write real systems, and
even idiomatic Go didn't require much more than the basics. The remaining
restrictions in Goose were easy enough to work with that we could implement
GoJournal the way we wanted to.

Finally, Go is a good language to build systems in. It has efficient and useful
built-in slice and map collections, and anything we build on top is verified.
The runtime handles concurrency efficiently and has good support for
synchronization using locks and condition variables, allowing a low-level
implementation. We were able to use low-level interfaces to the operating system
to access the disk. Garbage collection simplifies some code and carries a
relatively low performance impact due to the efficient runtime. The tooling for
testing, debugging, and profiling is extremely good, making it easy to fix bugs
(before verification or in unverified code) and find performance problems while
optimizing.

## Related work

There are many approaches and systems people have used to verify implementations.

We wanted control over the translation process to simplify the resulting model
that we needed to write proofs for. Using an existing translator that
essentially translates syntax would still leave the task of giving a semantics
to the output code and proving the right specifications in Perennial to reason
about various parts of the semantics.

Most closely related work is Robbert Krebbers's thesis, on a semantics for C
that includes both operational semantics and an "axiomatic semantics" which is a
separation logic for interactive proofs (it also has an interpreter to test and
debug, which produces all of the behaviors of a program).

VST also models C for the purpose of interactive proofs.

_Much more to say here_

## High-level overview

The goal of the translation is to model a Go program using GooseLang, which is a
programming language defined in Coq for this purpose. When we say GooseLang is a
programming language, we mean it in a theoretical sense: GooseLang consists of a
type of programs in Coq and a small-step semantics of these programs. Since
GooseLang programs support references to model the Go heap, the semantics is
written in terms of transitions of (program, heap) pairs where the heap maps
pointers to values. The intention of the translation is that the semantics of
the translated function should cover all the behaviors of the Go code, in terms
of return values and effect on the heap. As long as this is true, a proof that
the translated code always satisfies some specification means that the real
running code will, too.

GooseLang is a low-level language, so many constructs in Go translate to (small)
implementations in GooseLang. This implementation choice proved to be much more
convenient than adding primitives to the language for every Go construct. For
example, a slice is represented as a tuple of pointer, length, and capacity, and
appending to a slice requires checking for available capacity and copying if
none is available. Appending to a slice is a complicated operation, and it was
easier to write it correctly as a program rather than directly as a transition
in the semantics. The one cost to this design strategy is that an arbitrary
GooseLang program is much more general than translated Go programs. This has no
impact on verifying any _specific_ Go program, and so far has not been a burden
for the proofs we do have for arbitrary GooseLang programs.

An important aspect of GooseLang is supporting interactive proofs on top of the
translated code. The interactive proofs use separation logic, a variant of Hoare
logic, so specifications describe the behavior of each individual function. In
order to support verification of any translated code, GooseLang comes with a
specification for any primitive or function that the translated code might refer
to, including libraries like slices used to model more sophisticated Go
features. GooseLang has many "pure" operations that have no effect on the heap,
due to many primitive data types and operations (for example, there are both
8-, 32-, and 64-bit integers, and arithmetic and logical operations for each).
The specifications for these operations are handled with a single lemma, which
is applied automatically with a tactic `wp_pures`.

Since our goal is to support interactive rather than automated proofs, it is
helpful to make the model simple to work with. We try to maintain a strong
correspondence between the model and source code: each Go package translates to
a single Coq file, and each top-level declaration in the Go code maps to a
Gallina definition (a GooseLang constant or function). Goose has a special case
for translating immutable variables to let bindings in GooseLang (rather than
allocating a pointer that will only be read). As a result, factoring out a
sub-expression to a variable has little impact on proofs, since it just adds one
more pure step.

While the model is simple in terms of control flow and structure, we can safely
translate any given Go operation to a sophisticated model as long as the proof
abstracts it away. The subsequent sections in this chapter walk through several
features of Go. In each case we first implement the feature in GooseLang, which
as a model of its behavior primarily aims to be faithful to Go. Next, we develop
reasoning principles for the features, in the form of separation logic
assertions (for example, to represent a slice) and Hoare triples (for example,
to specify the behavior of Append). The key is that the model is trusted to
capture Go's behavior so some sophistication is useful, whereas the reasoning
principles aim to hide that complexity to make proofs practical.

## Supported and unsupported features

Each function is translated to a single Coq definition, which is a GooseLang
function. For concurrency, Goose supports the `go` statement and the synchronization
primitives `*sync.Mutex` and `sync.Cond`.

Go's primitive uint64, uint32, uint8 (byte), and boolean types are all
supported, as well as most of the pure functions on those types. Goose also
supports pointers, structs, and methods on structs. Finally, Goose supports Go's
built-in data structures, slices and maps.

Notably missing in Goose but prominent in Go is support for interfaces and
channels. We believe both are easy enough to support, but interfaces were not
necessary for our implementation, and rather than channels we use mutexes and
condition variables for more low-level control over synchronization.

Control flow is also slightly tricky since a Go function is translated to a
single GooseLang expression that should evaluate to the function's return value.
We can support many specific patterns, especially common cases like early
returns inside `if` statements and loops with `break` and `continue`, but more
complex control flow - particularly returning from within a loop - is not
supported. If we wanted to fix this the right solution would probably be to
represent all functions in continuation-passing style, though this would
complicate the translation of every function call.

We do not support Go's defer statement. It would be nice to support some common
and simple patterns, particularly for unlocking, by translating `defer`
statically; Go's general `defer` is much more complicated since it can actually
be issued anywhere in a function and pushes to a stack of calls that are
executed in reverse order at return time.

We do not support mutual recursion between Go functions, and additionally
require the translation to be in the right order so definitions appear before
they are used. The subtlety here is that definition management in Go, as in most
imperative languages, conceptually treats all top-level definitions as
simultaneous, whereas Coq processes definitions sequentially. Using Coq
definition management to model Go definition management imposes a limitation
compared to Go, but is much simpler to work with compared to modeling a Go
package as a set of mutually recursive definitions. In such a model it would be
necessary to first give specifications to every definition that may be assumed
by other proofs, and to ensure the proof isn't circular each function would have
to be proven in some order that only assumes previous results.

## Modeling pointers

Pointers turn out to be slightly subtle because of concurrency. In short,
GooseLang disallows concurrent reads and writes to the same location by making
such racy access undefined behavior (any specification for a program implies
that if the precondition holds, the program never exhibits undefined behavior).
The hardware provides some guarantees, but they are relatively weak: for
example, different cores can observe writes at different times. Go's own memory
model specifies even weaker guarantees. Rather than attempt to formalize Go's
rules (which are complex and involve defining a partial order over all program
instructions), we side step the issue and make any races undefined, which works
for our intended use cases since we always synchronize concurrent access with
locks.

To disallow concurrent reads and writes we first need to detect them. The
GooseLang semantics does this by augmenting the heap with extra information
giving the number of current readers. Rather than making reads a single atomic
step, we split them into two primitives. The first increments the number of readers
and the second decrements the count and returns the current value. The semantics
of a write are only defined if there are no readers and undefined otherwise.

Next, we need reasoning principles to abstract away this complexity from program
verification. Separation logic turns out to provide the right language to reason
about racy access. When a thread owns $l \mapsto v$, we know no other thread can
have access to location $l$, so the specifications for reads and writes are
unaffected by the operations being non-atomic (although their proofs are a bit
more complicated to deal with the new semantics). The only change is that
the Read operation is no longer an atomic primitive but a function that takes
two execution steps. In Iris this means that two threads cannot share memory
with an invariant and must mediate access with a lock, which transfers ownership
of the $l \mapsto v$ for multiple execution steps.

## Structs

One of the first features needed when writing any Go is support for structs. We
treat a struct value as just a tuple of its fields, while the struct definition
gives the names of those fields. This data is enough to implement constructing a
struct from its fields and accessing a field by name, which we implement in
Gallina.

Structs in memory are more interesting than struct values. Structs could be
stored in a single location; due to our non-atomic semantics for memory, this
would be sound even for structs larger than a machine word. However, this model
would be too restrictive: it is safe for threads to concurrently access
_different fields_, just not the same field, and we actually take advantage of
this property (largely to write more natural Go code; working around this
restriction requires splitting structs up if they are stored in memory).

To support this concurrency, we model a struct in memory with a flattened
representation, with each base element in a separate memory cell. The flattening
applies recursively to fields that are themselves structs, until a base literal
is reached (like an integer or boolean); base elements are at most a machine
word, but can be smaller. When allocating a new pointer, the semantics flattens
composite values and stores the elements in a sequence of contiguous addresses.

With a flattened representation we need non-trivial code to read a struct
through a pointer, particularly when some of its fields are themselves flattened
structs. We implemented
this code by augmenting the "schema" that represents a struct type with not only
the fields, but their types as well. The exact types are not important, but we
do need the entire tree of how big each field is and the shape of each field in
order to determine the location and extent of any given field. Using types to
represent these shapes makes the translation much simpler, since we have access
to the type of every sub-expression from the Go type checker. Any load of a
value from memory is translated to a Gallina LoadTyped macro that takes a Coq
representation of the type being loaded and uses it to determine what offsets to
load.

For the purpose of proofs we represent a pointer to an arbitrary type $t$ with a
typed points-to fact of the form $l \mapsto_t v$. This definition expands to a
number of primitive points-to facts, one for each base element. The
specification for loading says $\{l \mapsto_t v\} LoadTyped(t, l) \{RET v, l
\mapsto_t v\}$, which (much like the non-atomic primitive Load) hides the fact
that something non-atomic is happening and looks like an ordinary dereference.
Similarly, StoreTyped also takes a type, although the specification requires the
caller to prove that the value has the right shape (in reality it always will
because the Go code we translate from is well-typed).

The payoff of structs being many independent locations is that it is possible to
model references to individual struct fields. From a pointer to the root of the
struct, a field pointer is simply an offset from that pointer (skipping the
flattened representations of the previous fields). This offset calculation is
much like the code to read a struct from memory, except that it merely computes
a single offset rather than iterating over all the fields and offsets.

Recall that $l \mapsto_t v$ is internally composed of untyped points-to facts
for all the base elements of $v$. In order to reason about $v$'s fields, we
introduce a new struct field points-to fact, written $l \mapsto_{t.f} v$, which
asserts ownership of just field $f$ of a struct of type $t$ rooted at $l$, and
gives that field's value as $v$. A recursive function gives an "exploded" set of
struct fields by iterating over $t$'s fields and $v$ simultaneously. Then, we
give a proof that $l \mapsto_t v$ is equivalent to the separating conjunction of
this exploded list. The result is a convenient lemma for reasoning about a
struct using its fields: in the forward direction, the equivalence breaks a
large typed points-to into individual fields (with the values computed from
$v$), while in the other direction it allows to prove a $l \mapsto_t v$ by
gathering up all the fields.

The struct field points-to is indispensible in proofs, because the pattern of
`x.f` in Go when $x$ is a pointer is in fact a field load (in C, this would be
written `x->f`). The model for loading a struct field is a function
`loadField(x, t, f)` which is implemented in two steps, first computing the
offset to field $f$ and the other to load it (in both cases the struct type $t$
describes how to interpret field $f$). Having a field points-to gives a natural
specification for this type of load: $\{ l \mapsto_{t.f} v \}
\mathtt{loadField}(x, t, f) \{ RET v, l \mapsto_{t.f} v\}$.

The lemmas about breaking apart and recombining structs are all proven against a
simpler model of structs that only requires flattening and offset calculations.
In a sense the model is the trusted code, but the fact that the struct maps-to
exploding lemma is true that all of the expected Hoare triples hold provides
strong evidence that the model is also doing the right thing. For example, the
exploding lemma shows that field offsets are disjoint, since the struct maps-to
can be broken into field points-to facts for each field.

Something to emphasize above: all of the struct code is generic for struct type
$t$, which in the code is concretely the "schema" described above, a list of
fields and types (the code calls this a "descriptor" and uses $d$ as the
metavariable, to avoid confusion with a generic type $t$).

## TODO

Make a point about model being close to implementation of Go (eg, struct
flattening, model of slices, mutable variables).

Talk about interpreter for testing

Describe slice model and reasoning principles

Describe map model
