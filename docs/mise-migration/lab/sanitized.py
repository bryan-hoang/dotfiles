#!/usr/bin/env python3
"""Sanitized sources (review code SANITIZED, E112 to E128).

Each source under ROOT/dotfiles/<HOME-relative path> may hold only the fields
its row in sanitized-allowlist.tsv allows, plus one include (two comment
lines). The source is a mise template: E011 renders it to
HOME/<HOME-relative path>, and the include splices in the excluded
application-local input
HOME/<HOME-relative path>.local when it exists. Prints field names and counts
only, never values.

    sanitized.py check ROOT                exit 1 on any unknown field
    sanitized.py save ROOT [SAVE-ARGS...]  check, then mise dot save SAVE-ARGS
"""

import os
import re
import sys
from pathlib import Path

ALLOWLIST = Path(__file__).with_name("sanitized-allowlist.tsv")
TERA = ("{{", "{%", "{#")


def read(path):
    return Path(path).read_bytes().decode()


def rows():
    for line in read(ALLOWLIST).splitlines()[1:]:
        rid, path, fmt, allow, _local = line.split("\t")
        yield rid, path, fmt, [tuple(p.split(".")) for p in allow.split()]


def include(path, fmt):
    # Two comment lines, so the source still parses; they render as two empty
    # comments followed by the local input on its own lines.
    c = "\t// " if fmt == "jsonc" else "# "
    local = "/" + path.removeprefix("dotfiles/") + ".local"
    return (
        f'{c}{{% set local = env.HOME ~ "{local}" %}}\n'
        f'{c}{{% if local is file %}}{{{{ "\\n" ~ read_file(path=local) }}}}{{% endif %}}\n'
    )


def jsonc_keys(text):
    # Every object key as a path; array elements add a "[]" segment.
    i, stack, path, expect = 0, [], [], False
    while i < len(text):
        c = text[i]
        if c == '"':
            j = i + 1
            while text[j] != '"':
                j += 2 if text[j] == "\\" else 1
            if stack and stack[-1] == "{" and expect:
                path[-1], expect = text[i + 1 : j], False
                yield tuple(path)
            i = j + 1
            continue
        if text.startswith("//", i):
            i = text.find("\n", i)
            if i < 0:
                break
            continue
        if text.startswith("/*", i):
            i = text.index("*/", i) + 2
            continue
        if c in "{[":
            stack.append(c)
            path.append("[]" if c == "[" else None)
            expect = c == "{"
        elif c in "}]":
            stack.pop()
            path.pop()
        elif c == ",":
            expect = stack[-1] == "{"
        i += 1


def fields(fmt, text):
    """Field paths in source order. Unparsable lines are fields too, so they
    fail closed."""
    if fmt == "jsonc":
        try:
            return list(jsonc_keys(text))
        except (IndexError, ValueError):
            return [("<unparsed>",)]
    out, section = [], None
    for raw in text.splitlines():
        s = raw.strip()
        if not s or s[0] == "#" or (fmt == "ini" and s[0] == ";"):
            continue
        if fmt in ("line", "args"):
            out.append((re.split(r"[\s=:]", s.lstrip("-"), maxsplit=1)[0],))
        elif fmt == "yaml":
            if s == "---":
                continue
            if raw[0] in " \t-":
                if not out:
                    out.append(("<unparsed>",))
                continue
            m = re.match(r"([^:#]+):(\s|$)", raw)
            out.append((m[1].strip().strip("'\""),) if m else ("<unparsed>",))
        elif s.startswith("["):
            section = s.strip("[]").strip()
            out.append((section,))
        else:
            key = re.split(r"[=:]" if fmt == "ini" else "=", s, maxsplit=1)[0].strip()
            out.append((key,) if section is None else (section, key))
    return out


def allowed(field, patterns):
    # A field shorter than a matching pattern is a container on its way there.
    return any(
        len(field) <= len(p) and all(a in ("*", b) for a, b in zip(p, field))
        for p in patterns
    )


def problems(path, fmt, patterns, text):
    inc = include(path, fmt)
    if text.count(inc) != 1:
        yield "local input include missing or repeated"
    body = text.replace(inc, "")
    if any(d in body for d in TERA):
        yield "template syntax outside the include line"
    for f in fields(fmt, body):
        if not allowed(f, patterns):
            yield f"unknown field {'.'.join(f)}"


def check(root):
    bad = n = 0
    for rid, path, fmt, patterns in rows():
        n += 1
        src = Path(root, path)
        found = (
            list(problems(path, fmt, patterns, read(src)))
            if src.is_file()
            else ["missing"]
        )
        for p in found:
            print(f"{rid} {path}: {p}")
        bad += len(found)
    print(f"sanitized_sources={n} unknown_fields={bad}")
    return bad == 0


def main(argv):
    cmd, root, *rest = argv
    if cmd == "check":
        return 0 if check(root) else 1
    if cmd == "save":
        if not check(root):
            print("save blocked: sanitized source has unknown fields")
            return 1
        os.execvp("mise", ["mise", "dot", "save", *rest])
    raise SystemExit(__doc__)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
