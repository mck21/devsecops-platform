#!/usr/bin/env python3
"""Switch Istio VirtualService weights and update active color in Git."""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ACTIVE_COLOR_FILE = ROOT / "k8s/overlays/staging/active-color.yaml"
VIRTUALSERVICE_FILE = ROOT / "k8s/blue-green/virtualservice.yaml"


def switch_to(target: str) -> None:
    if target not in {"blue", "green"}:
        raise SystemExit("Target color must be blue or green")

    other = "green" if target == "blue" else "blue"
    target_weight = 100
    other_weight = 0

    vs = VIRTUALSERVICE_FILE.read_text()

    vs = re.sub(
        rf"(subset: {target}\n          weight: )\d+",
        rf"\g<1>{target_weight}",
        vs,
        count=1,
    )
    vs = re.sub(
        rf"(subset: {other}\n          weight: )\d+",
        rf"\g<1>{other_weight}",
        vs,
        count=1,
    )
    VIRTUALSERVICE_FILE.write_text(vs)

    active = ACTIVE_COLOR_FILE.read_text()
    active = re.sub(
        r"(ACTIVE_COLOR: )\w+",
        rf"\g<1>{target}",
        active,
        count=1,
    )
    ACTIVE_COLOR_FILE.write_text(active)

    print(f"active_color={target}")


def main() -> None:
    if len(sys.argv) != 2:
        raise SystemExit("Usage: traffic_switch.py <blue|green>")
    switch_to(sys.argv[1])


if __name__ == "__main__":
    main()
