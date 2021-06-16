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
correct file system. The artifact resulting from this work is DaisyNFS, which is
a usable Network File System (NFS) server with an efficient, concurrent
implementation on top of a raw disk. We prove that DaisyNFS implements every
file system operation atomically, even if the computer crashes at any time. A
performance evaluation shows that DaisyNFS gets comparable performance to the
Linux NFS server.

The proof of DaisyNFS is divided into two components: a verified transaction
system makes multiple reads and writes in a transaction atomic, and then we
implement a verified file system using a transaction per operation. This thesis
demonstrates how to use this design to use more automated, sequential
verification techniques to reason about the file-system code, even though the
overall system is concurrent. The transaction system has an easy-to-use API but
a complex, highly concurrent implementation. In this thesis we also develop new
techniques and tools to reason about the transaction system.

Prior to the work described in this thesis, there was little formal methods
support for reasoning about the combination of crash safety and concurrency.
