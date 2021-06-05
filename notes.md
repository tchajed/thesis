# Introduction outline

want to separate verified artifact from contributions:

- approach for separating file system proof into transaction system then
  sequential verification in a different tool
- proof of a sophisticated journaling system, verified in several layers using a
  new specification style for crash-safe abstractions
- program logic for concurrency and crash safety with support for ownership
  across a crash
- tool, semantics, and reasoning principles for Go

# Overall structure

outer structure is SOSP 2021: verified transaction system, verified file system,
compose the two

transaction system requires extended background on Goose and Perennial

chapters:

1. Introduction
2. Related work
3. Overall proof structure
   - transaction system specification
   - file-system layers
4. Goose (new text)
5. Perennial (POPL 2021/2022)
6. Transaction system (mostly OSDI 2021, but using refinement spec from SOSP 2021)
7. File-system proof
8. Evaluation

# What work is left?

Goose chapter. I think I know what this text needs to cover.

Peony paper needs a revision for resubmission. For thesis we just need to
explain this stuff better, for example using crash borrows will help.
Re-submission will probably need some new thing to differentiate from the OSDI
paper,

Didn't describe the GoJournal proof in any detail. Especially lacking are the
actual crash safety/recovery principles, like the core monotonic counter that
tells you a transaction ID is durable.

Explain the transaction system invariant (improve text in SOSP 2021 paper).

Explain the file-system invariant in some more detail

Paper proof of file-system correctness (should also be in SOSP appendix)
