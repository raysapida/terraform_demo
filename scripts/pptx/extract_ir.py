#!/usr/bin/env python3
"""docs/slides.md -> a JSON tree per slide, for build.js to turn into a .pptx.

    extract_ir.py [out.json] [slides.md]

Reuses scripts/build-slides.py's parser and renderer, so the PowerPoint is built from
exactly the markup the web deck is built from. Run through `make pptx`.
"""
import importlib.util
import json
import pathlib
import re
import sys
import xml.etree.ElementTree as ET

sys.dont_write_bytecode = True  # must precede the import below, or it leaves a __pycache__
HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parents[1]
spec = importlib.util.spec_from_file_location("bs", REPO / "scripts/build-slides.py")
bs = importlib.util.module_from_spec(spec)
spec.loader.exec_module(bs)
AMP = re.compile(r"&(?!(?:amp|lt|gt|quot|apos|#\d+|#x[0-9a-fA-F]+);)")


def node(el):
    kids = []
    if el.text:
        kids.append(el.text)
    for child in el:
        kids.append(node(child))
        if child.tail:
            kids.append(child.tail)
    attrs = {k: v for k, v in el.attrib.items() if k != "class"}
    return {"t": el.tag, "c": el.attrib.get("class", ""), "a": attrs, "k": kids}


out_path = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else HERE / ".build/ir.json"
md_path = pathlib.Path(sys.argv[2]) if len(sys.argv) > 2 else REPO / "docs/slides.md"
slides = bs.parse(md_path.read_text())
out = []
for i, sl in enumerate(slides, 1):
    html = bs.render(sl)
    try:
        root = ET.fromstring("<root>" + AMP.sub("&amp;", html) + "</root>")
    except ET.ParseError as e:
        sys.exit(f"slide {i} ({sl['title']}): {e}")
    section = root[0]
    out.append({"n": i, "title": sl["title"], "section": section.attrib.get("data-section", ""),
                "cls": section.attrib.get("class", ""), "tree": node(section)})

out_path.parent.mkdir(parents=True, exist_ok=True)
out_path.write_text(json.dumps(out, indent=1))
print(f"{md_path.name}: {len(out)} slides -> {out_path}")
