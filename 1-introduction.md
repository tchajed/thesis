# Introduction

This thesis presents an approach for building a file system that has an
efficient, concurrent implementation and a proof that the implementation always
meets its specification. The specification guarantees that every operation is
atomic to other threads, even if the system crashes, and also specifies what
that atomic behavior should be.

Applications rely on file systems to store their data, but there are still
occasionally bugs in modern, well-tested file systems. Bugs in file systems are
especially critical because they can lead to data loss. Storage systems are
especially difficult to make correct because for efficiency they process
multiple requests concurrently, and the system must be correct for any
interleaving of request processing, including a system crash in the middle.
Testing can help find bugs, but exploring all possible interleavings and crash
points is generally infeasible.

In this thesis, we explore formal verification as an approach to building a
correct file system. Our contributions are the techniques and tools that make
this possible. In order to evaluate the techniques, we apply them to a
reasonably complete artifact: DaisyNFS implements a usable file system as a
Network File System (NFS) server, and gets good performance on a number of
benchmarks and storage technologies. Verifying this particular file system is
not an end in itself for this thesis, but a driving force to make sure that the
verification techniques can scale to many optimizations and an implementation of
non-trivial size.

Crash safety requires new techniques, so this thesis contributes not just a
verified implementation but new infrastructure in which to carry out the
verification. While developing infrastructure we were able to explore the entire
verification pipeline, starting from code in a production language (Go), giving
it a semantics, all the way to connecting that semantics to a high-level
specification. In addition, the particular structure of DaisyNFS combines
different verification tools, so another contribution is an approach that
combines the tools. While this particular combination might not be useful to
many systems (since it relies on a transaction system that supports all the code
running in Dafny), we believe the use of refinement to combine different
verification tools is a general idea and our proof gives a template for how that
might work. _Seems most useful if some crash safety/concurrency could be handled
in Dafny - maybe just related work?_

Prior to the work described in this thesis, there was little formal methods
support for reasoning about the combination of crash safety and concurrency.
