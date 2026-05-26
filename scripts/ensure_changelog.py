#!/usr/bin/env python3
"""
Ensures the [Unreleased] section of CHANGELOG.md has content before a deploy.

If all Added / Changed / Fixed sections under [Unreleased] are empty, this
script finds the most recent versioned release that has real content and
copies those sections into [Unreleased] so the deploy never ships empty notes.
"""

import re
import sys
from pathlib import Path

CHANGELOG_PATH = Path(__file__).parent.parent / "CHANGELOG.md"
SECTIONS = ["Added", "Changed", "Fixed"]


def section_has_content(body: str, section: str) -> bool:
    """Return True if ### <section> in *body* has at least one non-empty bullet."""
    pattern = rf"### {section}\n(.*?)(?=\n### |\n---|\Z)"
    m = re.search(pattern, body, re.DOTALL)
    if not m:
        return False
    for line in m.group(1).splitlines():
        stripped = line.strip()
        # A real bullet starts with "- " followed by non-whitespace
        if re.match(r"^-\s+\S", stripped):
            return True
    return False


def body_has_content(body: str) -> bool:
    return any(section_has_content(body, s) for s in SECTIONS)


def main():
    if not CHANGELOG_PATH.exists():
        print("⚠️  CHANGELOG.md not found — skipping changelog check")
        return

    content = CHANGELOG_PATH.read_text(encoding="utf-8")

    # --- locate [Unreleased] block ---
    unreleased_match = re.search(
        r"(## \[Unreleased\])(.*?)(?=\n## \[)", content, re.DOTALL
    )
    if not unreleased_match:
        print("⚠️  No [Unreleased] section found — skipping")
        return

    unreleased_header = unreleased_match.group(1)
    unreleased_body = unreleased_match.group(2)

    if body_has_content(unreleased_body):
        print("✅ [Unreleased] already has content — nothing to do")
        return

    print("⚠️  [Unreleased] sections are all empty — searching for fallback release...")

    # --- find the first versioned release with real content ---
    versioned_entries = list(
        re.finditer(
            r"(## \[\d+\.\d+\.\d+\+\d+\][^\n]*\n)(.*?)(?=\n## |\Z)",
            content,
            re.DOTALL,
        )
    )

    fallback_body = None
    fallback_header = None
    for entry in versioned_entries:
        body = entry.group(2)
        if body_has_content(body):
            fallback_header = entry.group(1).strip()
            fallback_body = body
            break

    if fallback_body is None:
        print("⚠️  No versioned release with content found — leaving [Unreleased] as-is")
        return

    print(f"✅ Using changelog content from: {fallback_header}")

    # --- splice fallback content into Unreleased ---
    new_unreleased = unreleased_header + fallback_body
    new_content = content.replace(
        unreleased_match.group(0),  # original Unreleased block
        new_unreleased,
        1,
    )

    CHANGELOG_PATH.write_text(new_content, encoding="utf-8")
    print("✅ Filled [Unreleased] with content from most recent release that has data")


if __name__ == "__main__":
    main()
