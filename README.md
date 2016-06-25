# Rust

[![Build Status](https://travis-ci.org/iamed2/Rust.jl.svg?branch=master)](https://travis-ci.org/iamed2/Rust.jl)
[![codecov.io](http://codecov.io/github/iamed2/Rust.jl/coverage.svg?branch=master)](http://codecov.io/github/iamed2/Rust.jl?branch=master)


## Dependencies

You must have `rustc` and `cargo` to use this package.
[Rustup](https://www.rustup.rs/) is the recommended install method.

## Usage

This is a work in progress so there are not many features right now.

Take a look at `test/runtests.jl` for usage examples.

## Capabilities

Current:
- Compile a Rust code string and return a `dlopen`d library

Future:
- Translate fully-typed methods to Rust with a macro that calls `code_typed`
- Rust string support
- Replace common Julia method patterns with their Rust equivalents
- Parameters => Generics
