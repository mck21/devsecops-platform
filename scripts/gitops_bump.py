#!/usr/bin/env python3
"""Update the idle color image tag in staging kustomization.yaml."""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ACTIVE_COLOR_FILE = ROOT / "k8s/overlays/staging/active-color.yaml"
KUSTOMIZATION_FILE = ROOT / "k8s/overlays/staging/kustomization.yaml"


def read_active_color() -> str:
    for line in ACTIVE_COLOR_FILE.read_text().splitlines():
        if line.strip().startswith("ACTIVE_COLOR:"):
            return line.split(":", 1)[1].strip()
    raise SystemExit("ACTIVE_COLOR not found in active-color.yaml")


def idle_color(active: str) -> str:
    if active == "blue":
        return "green"
    if active == "green":
        return "blue"
    raise SystemExit(f"Invalid ACTIVE_COLOR: {active}")


def bump_tag(sha_tag: str) -> tuple[str, str]:
    active = read_active_color()
    idle = idle_color(active)
    image_name = f"backend-{idle}"

    content = KUSTOMIZATION_FILE.read_text()
    pattern = rf"(- name: {re.escape(image_name)}\n    newName: [^\n]+\n    newTag: )[^\n]+"
    updated, count = re.subn(pattern, rf"\g<1>{sha_tag}", content, count=1)
    if count != 1:
        raise SystemExit(f"Failed to update newTag for {image_name}")

    KUSTOMIZATION_FILE.write_text(updated)
    return idle, image_name


def main() -> None:
    if len(sys.argv) != 2:
        raise SystemExit("Usage: gitops_bump.py <sha-tag>")

    idle, image_name = bump_tag(sys.argv[1])
    print(f"idle_color={idle}")
    print(f"image_name={image_name}")


if __name__ == "__main__":
    main()
