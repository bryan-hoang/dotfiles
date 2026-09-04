# WezTerm configuration

This glossary defines the terms used by the shared WezTerm configuration, its
terminal connection types, and its opacity diagnostics.

## Configuration

**Shared configuration**: The common WezTerm setup used across supported
machines and operating systems. _Avoid_: Machine config, local config

**Machine override**: A setting that changes WezTerm behavior on one machine
without changing the shared setup. _Avoid_: Shared setting, temporary override

**OS branch**: Configuration behavior selected for the operating system running
WezTerm. _Avoid_: Machine override, platform profile

## Terminal connections

**Domain**: A named way for WezTerm to create a terminal session. _Avoid_:
Window, tab

**Local session**: A terminal session that runs a shell on the current operating
system. _Avoid_: Local domain, local terminal

**WSL domain**: A domain that opens a shell inside Windows Subsystem for Linux.
_Avoid_: Linux terminal, WSL tab

**SSH domain**: A domain that connects to a remote host using its local SSH
configuration. _Avoid_: Remote domain, SSH tab

## Opacity diagnostics

**Background opacity**: The alpha applied to WezTerm's terminal background.
`1.0` is opaque and `0.0` is fully transparent; foreground text remains
independently rendered. _Avoid_: Entire-window opacity

**WGL path**: The Windows rendering path that uses the GPU vendor's OpenGL
context. _Avoid_: GPU transparency support

**EGL path**: The Windows rendering path that uses ANGLE and Direct3D 11.
_Avoid_: Software renderer

**Normal launch**: A WezTerm GUI launch through the usual window-manager
workflow and shared configuration. _Avoid_: Isolated launch

**Controlled reference**: A temporary, high-contrast surface placed behind a
test window to make background opacity visible in a screenshot. _Avoid_: Desktop
baseline
