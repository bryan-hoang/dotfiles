---
status: accepted
---

# Preserve `sccache` for Registry Installs

The dotfiles set up routes Cargo through `mbx` but retains
`RUSTC_WRAPPER=sccache`. Current upstream `mbx` intentionally passes registry
and Git `cargo install` commands through to Cargo, and `mbx` and `sccache`
cannot both cache the same Rust compiler invocation. Keeping `sccache` preserves
the existing compiler cache for the primary registry-install workflow.

## Recipe

Use the normal Cargo command; the global mise wrapper may still route it through
`mbx`, after which the registry install is handled by Cargo and `sccache`:

```powershell
cargo install <crate>
sccache --show-stats
```

Do not unset `RUSTC_WRAPPER` for registry installs unless an uncached install is
acceptable. `cargo install --path <directory>` is a separate, local check out
case that upstream `mbx` can cache in eligible releases, but it is not the
registry workflow recorded here.

## Consequences

`mbx` is the global Cargo command front door, while `sccache` remains the Rust
compiler-cache owner for ordinary builds and registry installs. Using `mbx` over
`sccache` to cache registry `cargo install` is not supported by current upstream
`mbx`; revisiting that choice requires upstream support rather than another
wrapper arrangement.

## Sources

- <https://mr-boxington.jdx.dev/faq#can-i-use-mbx-together-with-sccache>
- <https://mr-boxington.jdx.dev/cookbook/migrate#from-sccache>
- <https://github.com/jdx/mr-boxington/blob/v1.11.1/crates/mbx/src/cli/shim.rs>
- <https://doc.rust-lang.org/cargo/commands/cargo-install.html>
