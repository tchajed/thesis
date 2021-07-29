# Introduction

Motivation: storage systems that are reliable, because many applications rely on
them but the bugs involved are subtle

This thesis: we'll build a file system and verify it. This will also require
building the tools to do so.

# Overview

Implementation-focused: transaction system gives general abstraction, Dafny code
uses transactions to implement file-system data structures

Start with spec: code implements atomic NFS API

Key idea, important to remaining structure: use new and heavyweight verification
for transaction system, but simple and automated verification for transactions

repeated hierarchy: interface, specification, system design, proof

# DaisyNFS

Basic idea: transaction system makes any client atomic, Dafny proof assumes
atomicity and shows implementation is correct, therefore file-system run on top
of transaction system is atomic _and_ correct

API and specification for transaction system, using program refinement (theorem 1)

NFS transition-system specification; code verified against this in Dafny
(theorem 2)

## what does the spec mean?

overall system correctness is about the linked code; no mechanized reasoning but
we can still argue on paper, and intended specification is clear (theorem 3)

Mechanized proofs must be about a model of the code. In transaction system we do
this explicitly and methodically (foundationally), because we want custom
reasoning principles and these things are prone to error. In Dafny these are
implicit in the language: we can think of trusting Dafny to correctly convert
specifications to VCs because they are the formulae of Hoare logic against a
semantics of Dafny.

## verifying transaction system

basic summary? see rest of thesis

because this is foundational, developed two large tools: Goose and Perennial.
Perennial framework itself is not a focus of the thesis.

## verifying in Dafny

high-level system design

proof: focus on indirect blocks and freeing space

# Goose

independent chapter that answers how we reason about transaction system's
implementation using a custom program logic

# transactions

## background on separation logic/Iris/Perennial

main ideas: ownership, locks, wpc, crash-aware locks, recovery idempotence,
refinement

## verifying a transaction system

API: atomic access to variable-sized data

implementation: write-ahead logging, objects, two-phase locking

proof: build layer with implicit ownership, then use 2PL to manage objects,
refinement proof shows transactions appear to run at commit time

# related work

# implementation

## Goose

## Perennial

## transactions

## DaisyNFS

# evaluation

development process, "what have we verified?"

proof and incremental effort

performance evaluation
