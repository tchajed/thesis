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

_Much more to say here_

## The Goose subset of Go

To give an overview of Goose, it is helpful to informally lay out what the
supported subset of Go is. We assume no specific knowledge of Go; it is
sufficient to remember that it is a C-like imperative language. This overview
makes some reference to GooseLang; similarly we won't need any specifics about
how GooseLang works other than that it is a general imperative language with
pointers and concurrency.
