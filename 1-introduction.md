# Introduction

Storage systems are important because applications rely on them to store data, and to
persist that data even if the computer shuts down (perhaps unexpectedly, say due to
a power failure) and reboots. However, file systems have internally complicated
implementations, with optimizations and concurrency for high performance, which
lead to bugs. Sometimes these bugs result in the file system misbehaving, either
by incorrectly storing data or failing to retrieve it.

The approach taken in this thesis is to implement a file system with good
performance and concurrency, then formally verify that it always meets its
specification. More concretely the verified artifact
from this thesis is **DaisyNFS**, which implements the Network File System (NFS)
protocol on top of a disk. The specification for this file system stipulates
that each operation is implemented atomically (with respect to both other
threads and on crash), and behaves according to a formal model of the NFS
specification as laid out in prose in RFC 1813.

A file system is a large program, so we divided both the implementation and
proof of DaisyNFS into two layers. First, a **transaction system** implements
support for transactions that consist of a sequence of reads and writes which
appear to execute atomically, including if the system crashes. Next, the
**file-system layer** uses the transaction system by implementing each NFS
operation as a single transaction, automatically making a file-system operation
atomic for concurrency and crashes. Transactions greatly simplify making a file
system correct, since they handle concurrency and crash safety so the file
system can focus on correctly implementing its data structures and algorithms.

The proofs for the two layers are handled differently. The transaction system
exposes a simple API but its internals involve lots of concurrency and
crash-safety reasoning. Performance is important since this layer limits the
performance and concurrency of the file system. This layer's verification uses
specialized infrastructure we developed and describe in the thesis:
**Perennial** is a new program logic for reasoning about the combination of
concurrency and crash safety, and **Goose** is a tool that translates the Go
implementation of the system to a model that we can apply Perennial to.

For the file-system implementation and proof, we use the Dafny verification
language. The file-system operations interact with the transaction system to
store and retrieve data. To run the system, we compile the Dafny code to Go,
which imports and calls into the transaction system as a library. Dafny only
supports sequential reasoning, which is sufficient at this layer because the
transaction system guarantees that the Dafny code appears to run sequentially.

It is not obvious how to connect a verified transaction system with the Dafny
proof. This thesis develops an appropriate specification for the transaction
system and then uses an on-paper proof to argue that the entire system is
correct. The overall system's correctness then depends on some manual audits
over the Dafny code to check that the reasoning steps are sound.

DaisyNFS implements the NFSv3 protocol, a standard protocol for exposing a file
system over the network. We use DaisyNFS by mounting it with the Linux NFS
client and then interacting with the mounted file system using the standard
system-call API. A performance evaluation of DaisyNFS shows that it is
competitive with the Linux kernel NFS server exporting an ext4 file system.
