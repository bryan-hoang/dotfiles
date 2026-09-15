# Rust Tool Caching

This glossary distinguishes Cargo command routing from compiler-result caching
for globally installed Rust CLI tools.

## Language

**Cargo command wrapper**: The program that receives a Cargo command and
delegates it to Cargo. It routes commands but does not necessarily own compiler
caching. _Avoid_: Rust compiler wrapper, cache owner

**Rust compiler wrapper**: The program Cargo invokes around individual `rustc`
compilations. One wrapper owns a given compiler invocation. _Avoid_: Cargo
command wrapper

**Registry install**: An installation such as `cargo install <crate>` where
Cargo obtains a package from a registry and builds its executable for the
install root. _Avoid_: path install, binary cache

**Path install**: An installation such as `cargo install --path <directory>`
from a local crate checkout. _Avoid_: registry install

**Compiler-result cache**: A cache of reusable compiler outputs, not a cache of
Cargo's final executable installation step. _Avoid_: whole-install cache, binary
cache

**Cache owner**: The Rust compiler wrapper whose cache serves a compiler
invocation. `mbx` and `sccache` cannot both own the same invocation. _Avoid_:
Cargo command wrapper
