#!/usr/bin/env python3
"""Render docs/slides.html from docs/slides.md + docs/slides.template.html.

The markdown file is the source you edit; the HTML file is a build artifact.
Run via `make slides`, or `build-slides.py [source.md] [output.html]` for another deck.
`make pptx` builds this and then the PowerPoint
(scripts/pptx/), which reads the same parsed slides.

Slide format:

    ## 7. A website in two commands
    section: By hand first
    eyebrow: By hand first
    layout: title          (optional; only the opening slide uses it)

    Body. Lines starting with `<` pass through as HTML untouched, which is how
    diagrams, tables, terminal blocks and code survive. Markdown bullets
    (`- text`) become the deck's bullet list. `**bold**` and `` `code` `` work
    in bullets and paragraphs.

    ### notes

    One paragraph per line. Shown with the N key, never on the slide.
"""
import html
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
SRC = ROOT / "docs/slides.md"
TMPL = ROOT / "docs/slides.template.html"

INLINE = (
    (re.compile(r"\*\*(.+?)\*\*"), r"<b>\1</b>"),
    (re.compile(r"(?<!\w)`([^`]+)`(?!\w)"), r"<code>\1</code>"),
    (re.compile(r"(?<!\*)\*([^*\n]+)\*(?!\*)"), r"<em>\1</em>"),
)


def inline(text):
    for pattern, repl in INLINE:
        text = pattern.sub(repl, text)
    return text


VOID = {"area", "base", "br", "col", "embed", "hr", "img", "input", "link",
        "meta", "param", "source", "track", "wbr", "path", "rect", "circle",
        "line", "polyline", "polygon", "use", "stop"}

OPEN_TAG = re.compile(r"<([a-zA-Z][\w-]*)(?:\s[^>]*?)?(/?)>")
CLOSE_TAG = re.compile(r"</([a-zA-Z][\w-]*)>")


def depth_delta(line):
    """How many HTML block levels this line opens minus the ones it closes."""
    opens = sum(
        1 for name, selfclose in OPEN_TAG.findall(line)
        if not selfclose and name.lower() not in VOID
    )
    closes = len(CLOSE_TAG.findall(line))
    return opens - closes


def render_body(lines, name=""):
    """Markdown bullets and paragraphs become deck markup; HTML passes through.

    A ``` fence becomes a code box with its contents escaped for you, so `<`, `>`
    and `&` can be written as they are. Once a raw HTML block opens, every line (blank lines and entity-escaped
    lines included) is copied verbatim until that block closes again, so <pre>
    and <svg> contents survive untouched.
    """
    out, bullets, depth = [], [], 0
    fence = None  # lines of an open ``` block, or None

    def flush():
        if bullets:
            items = "".join(f"    <li>{inline(b)}</li>\n" for b in bullets)
            out.append(f'  <ul class="points">\n{items}  </ul>')
            bullets.clear()

    for line in lines:
        stripped = line.strip()
        if fence is not None:
            if stripped.startswith("```"):
                out.append(f'  <pre style="--code-lines:{len(fence)}">' + html.escape("\n".join(fence), quote=False) + "</pre>")
                fence = None
            else:
                fence.append(line)
            continue
        if depth == 0 and stripped.startswith("```"):
            flush()
            fence = []  # anything after the backticks (a language name) is ignored
            continue
        if depth > 0:
            out.append(line)
            depth += depth_delta(line)
            continue
        if stripped.startswith("- "):
            bullets.append(stripped[2:].strip())
        elif not stripped:
            flush()
        elif stripped.startswith("<"):
            flush()
            out.append(line if line.startswith(" ") else "  " + line)
            depth += depth_delta(line)
        else:
            flush()
            out.append(f'  <p class="lede">{inline(stripped)}</p>')
    flush()
    if fence is not None:
        print(f"warning: unterminated ``` code block in slide '{name}'", file=sys.stderr)
        out.append(f'  <pre style="--code-lines:{len(fence)}">' + html.escape("\n".join(fence), quote=False) + "</pre>")
    if depth != 0:
        print(f"warning: unbalanced HTML in slide '{name}' (depth {depth}); "
              "check for a missing or extra closing tag", file=sys.stderr)
    return "\n".join(out)


def parse(text):
    slides, current = [], None
    in_fence = False
    for raw in text.split("\n"):
        if raw.lstrip().startswith("```"):
            in_fence = not in_fence  # the fence line itself falls through as ordinary body text
        elif in_fence:
            if current is not None:
                current["notes" if current["in_notes"] else "body"].append(raw)
            continue
        if raw.startswith("## "):
            if current:
                slides.append(current)
            title = raw[3:].strip()
            title = re.sub(r"^\d+\.\s*", "", title)
            current = {"title": title, "meta": {}, "body": [], "notes": [], "in_notes": False, "head_done": False}
            continue
        if current is None:
            continue  # file header / comments before the first slide
        if raw.strip() == "### notes":
            current["in_notes"] = True
            continue
        if current["in_notes"]:
            current["notes"].append(raw)
            continue
        m = re.match(r"^(section|eyebrow|layout):\s*(.*)$", raw)
        if m and not current["head_done"]:
            current["meta"][m.group(1)] = m.group(2).strip()
            continue
        if raw.strip():
            current["head_done"] = True
        current["body"].append(raw)
    if current:
        slides.append(current)
    return slides


def render(slide):
    meta = slide["meta"]
    section = meta.get("section", "")
    cls = "slide title-slide" if meta.get("layout") == "title" else "slide"
    parts = [f'<section class="{cls}" data-section="{html.escape(section)}">']

    eyebrow = meta.get("eyebrow", "")
    title = slide["title"]
    if meta.get("layout") == "title":
        if eyebrow:
            parts.append(f'  <p class="eyebrow">{eyebrow}</p>')
        parts.append(f"  <h1>{html.escape(title)}</h1>")
    elif meta.get("layout") == "bare":
        if eyebrow:
            parts.append(f'  <p class="eyebrow">{eyebrow}</p>')
    elif title and title != "Slide":
        parts.append('  <div class="head">')
        if eyebrow:
            parts.append(f'    <p class="eyebrow">{eyebrow}</p>')
        parts.append(f"    <h2>{html.escape(title)}</h2>")
        parts.append("  </div>")
    elif eyebrow:
        parts.append(f'  <p class="eyebrow">{eyebrow}</p>')

    body = render_body(slide["body"], slide["title"])
    if body:
        parts.append(body)

    note_lines, fence = [], None  # ``` blocks in the notes become escaped <pre> too
    for raw in slide["notes"]:
        if fence is not None:
            if raw.strip().startswith("```"):
                note_lines.append("<pre>" + html.escape("\n".join(fence), quote=False) + "</pre>")
                fence = None
            else:
                fence.append(raw)
        elif raw.strip().startswith("```"):
            fence = []
        elif raw.strip():
            note_lines.append(raw.strip())
    if fence is not None:
        print(f"warning: unterminated ``` code block in the notes of slide '{title}'", file=sys.stderr)
    if note_lines:
        parts.append('  <aside class="notes">')
        for n in note_lines:
            parts.append(f"    {n}" if n.startswith("<") else f"    <p>{inline(n)}</p>")
        parts.append("  </aside>")

    parts.append("</section>")
    rendered = "\n".join(parts)
    headings = re.findall(r"<h[12][\s>]", rendered)
    if len(headings) > 1:
        print(f"warning: slide '{title}' renders {len(headings)} headings; "
              "give it `layout: bare` if the body already carries its own", file=sys.stderr)
    return rendered


def main():
    source = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else SRC
    output = pathlib.Path(sys.argv[2]) if len(sys.argv) > 2 else source.with_suffix(".html")
    slides = parse(source.read_text())
    if not slides:
        sys.exit(f"no slides found in {source}")
    rendered = "\n\n".join(render(s) for s in slides)
    template = TMPL.read_text().replace("<title>From Git commits to Terraform</title>",
                                        f"<title>{html.escape(slides[0]['title'])}</title>")
    output.write_text(template.replace("{{SLIDES}}", rendered))
    print(f"{output.name} ← {source.name} ({len(slides)} slides)")


if __name__ == "__main__":
    main()
