"use strict";
// node build.js <ir.json> <out.pptx> [slide numbers, comma separated]
// Turns the slide trees from extract_ir.py into an editable .pptx: native text, tables and shapes.
// Run through `make pptx`. Never edit the generated file by hand; edit docs/slides.md instead.
const pptxgen = require("pptxgenjs");
const fs = require("fs");
const path = require("path");
const { applyTheme } = require("./apply_theme.js");

const [IR_PATH, OUT, ONLY_ARG] = process.argv.slice(2);
if (!IR_PATH || !OUT) { console.error("usage: node build.js <ir.json> <out.pptx> [slide numbers]"); process.exit(2); }
const IR = JSON.parse(fs.readFileSync(IR_PATH, "utf8"));
const ONLY = ONLY_ARG ? ONLY_ARG.split(",").map(Number) : null;
const problems = []; // { n, fatal, msg }: reported at the end, never silent

// ── Theme ────────────────────────────────────────────────────────────────────
const SANS = "Arial";
const MONO = "Courier New";
const HEX = { ink: "16201C", surface: "FFFFFF", muted: "5B6660", ground: "F1F3EF", network: "4B57C9", edge: "11807A",
  compute: "8A3FA0", data: "B7791F", access: "B4442F", plus: "1F7A4D" };
const THEME = {
  name: IR[0]?.title || "From Git commits to Terraform",
  headFontFace: SANS,
  bodyFontFace: SANS,
  colors: { dk1: HEX.ink, lt1: HEX.surface, dk2: HEX.muted, lt2: HEX.ground, accent1: HEX.network, accent2: HEX.edge,
    accent3: HEX.compute, accent4: HEX.data, accent5: HEX.access, accent6: HEX.plus, hlink: HEX.network, folHlink: HEX.compute },
};

const pres = new pptxgen();
pres.defineLayout({ name: "WIDE169", width: 13.333, height: 7.5 });
pres.layout = "WIDE169";
pres.title = THEME.name;
pres.subject = "Playful Programming talk";
pres.theme = { headFontFace: SANS, bodyFontFace: SANS };
const C = pres.SchemeColor;
const INK = C.text1, MUTED = C.text2, WHITE = C.background1, GROUND = C.background2;
const CAT = { network: C.accent1, edge: C.accent2, compute: C.accent3, data: C.accent4, access: C.accent5, plus: C.accent6 };
const RULE = "D3D9D2", CODEBG = "E6EAE4", TERM_DIM = "9AA39E", TERM_OK = "8FD0A8", HL = "CBE3D3";

// ── Geometry (the web deck is a 1280x720 stage = 13.333x7.5in, so 1px = 1/96in) ──
const PX = 1 / 96;
const L = 72 * PX, W = 1136 * PX, BOTTOM = 656 * PX;
const GAP = 0.2, LH = 1.2;

// ── Layouts ──────────────────────────────────────────────────────────────────
const numStyle = { x: 12.0, y: 7.0, w: 0.58, h: 0.3, fontFace: MONO, fontSize: 10, color: MUTED, align: "right" };
pres.defineSlideMaster({
  title: "TITLE", background: { color: HEX.ground },
  objects: [{ placeholder: { options: { name: "title", type: "title", x: L, y: 1.85, w: 8.9, h: 2.6, fontFace: SANS, fontSize: 66,
    bold: true, color: INK, align: "left", valign: "top", margin: 0 }, text: "" } }],
});
pres.defineSlideMaster({
  title: "CONTENT", background: { color: HEX.ground }, slideNumber: numStyle,
  objects: [{ placeholder: { options: { name: "title", type: "title", x: L, y: 0.9, w: W, h: 1.2, fontFace: SANS, fontSize: 36,
    bold: true, color: INK, align: "left", valign: "top", margin: 0 }, text: "" } }],
});
pres.defineSlideMaster({ title: "BARE", background: { color: HEX.ground }, slideNumber: numStyle });

// ── Drawing context: every draw goes through here so layout can be measured dry ─
const ctx = { slide: null, dry: false, maxY: 0, n: 0 };
const mark = (y, h) => { if (!ctx.dry) ctx.maxY = Math.max(ctx.maxY, y + h); };
function addText(runs, o) {
  mark(o.y, o.h);
  if (ctx.dry) return;
  ctx.slide.addText(runs, { isTextBox: true, margin: 0, valign: "top", fit: "none", ...o });
}
function addShape(type, o) {
  mark(o.y, o.h);
  if (ctx.dry) return;
  ctx.slide.addShape(type, o);
}
const measure = (fn) => { const p = ctx.dry; ctx.dry = true; const h = fn(); ctx.dry = p; return h; };

// ── Text metrics (estimates; QA is by render) ────────────────────────────────
const cw = (face, bold) => (face === MONO ? 0.6 : bold ? 0.53 : 0.48);
function countLines(runs, pt, w) {
  let lines = 1, cur = 0;
  for (const r of runs) {
    const size = r.size || pt, face = r.face || SANS;
    for (const part of r.text.split(/(\n)/)) {
      if (part === "\n") { lines++; cur = 0; continue; }
      for (const tok of part.split(/( +)/)) {
        if (!tok) continue;
        const tw = tok.length * cw(face, r.bold) * size / 72;
        if (/^ +$/.test(tok)) { cur += tw; continue; }
        if (cur + tw > w && cur > 0) { lines++; cur = tw; } else cur += tw;
      }
    }
    if (r.breakLine) { lines++; cur = 0; }
  }
  return lines;
}
const textH = (runs, pt, w, lh = LH) => countLines(runs, pt, w) * pt * lh / 72;

// ── Tree helpers ─────────────────────────────────────────────────────────────
const isEl = (n) => n && typeof n === "object";
const cls = (n) => (n.c || "").split(/\s+/).filter(Boolean);
const has = (n, c) => cls(n).includes(c);
const kids = (n) => (n.k || []).filter(isEl);
const nodeText = (n) => (typeof n === "string" ? n : (n.k || []).map(nodeText).join(""));
const style = (n) => Object.fromEntries(((n.a && n.a.style) || "").split(";").map((s) => s.split(":").map((x) => x && x.trim())).filter((p) => p[0] && p[1]));
const px = (v) => (v == null ? null : parseFloat(v) * PX);
function find(n, t, c) { for (const k of kids(n)) { if (k.t === t && (!c || has(k, c))) return k; } return null; }
function findDeep(n, t, c) { for (const k of kids(n)) { if (k.t === t && (!c || has(k, c))) return k; const r = findDeep(k, t, c); if (r) return r; } return null; }
const inkColor = (n) => { for (const c of cls(n)) { const m = /^ink-(\w+)/.exec(c); if (m) return CAT[m[1]]; } return MUTED; };

function inlineRuns(n, base = {}) {
  const out = [];
  const walk = (x, st) => {
    if (typeof x === "string") { out.push({ text: x, ...st }); return; }
    const s = { ...st }, c = cls(x);
    if (x.t === "br") { out.push({ text: "", br: true }); return; }
    if (x.t === "b" || x.t === "strong") s.bold = true;
    if (x.t === "em") s.italic = true;
    if (x.t === "a" && /^https?:\/\//.test(x.a.href || "")) s.hyperlink = x.a.href;
    if (x.t === "code") { s.face = MONO; if (st.size) s.size = Math.round(st.size * 0.88 * 10) / 10; }
    if (x.t === "span") {
      if (c.includes("d") || c.includes("c")) s.color = MUTED;
      if (c.includes("p")) s.color = TERM_DIM;
      if (c.includes("ok")) s.color = TERM_OK;
      if (c.includes("k")) { s.color = CAT.network; s.bold = true; }
      if (c.includes("s")) s.color = CAT.data;
      if (c.includes("hl")) s.highlight = HL;
    }
    for (const k of x.k || []) walk(k, s);
  };
  for (const k of n.k || []) walk(k, base);
  return out;
}
function normRuns(runs) {
  const out = []; let prevSpace = true;
  for (const r of runs) {
    if (r.br) {
      if (out.length) out[out.length - 1] = { ...out[out.length - 1], text: out[out.length - 1].text.replace(/ $/, ""), breakLine: true };
      prevSpace = true;
      continue;
    }
    let t = r.text.replace(/\s+/g, " ");
    if (prevSpace) t = t.replace(/^ /, "");
    if (!t) continue;
    prevSpace = t.endsWith(" ");
    out.push({ ...r, text: t });
  }
  if (out.length) out[out.length - 1].text = out[out.length - 1].text.replace(/ $/, "");
  return out.filter((r) => r.text !== "");
}
function toLines(runs) {
  const lines = [[]];
  for (const r of runs) {
    r.text.split("\n").forEach((p, i) => { if (i > 0) lines.push([]); if (p !== "") lines[lines.length - 1].push({ ...r, text: p }); });
  }
  while (lines.length && !lines[lines.length - 1].length) lines.pop();
  while (lines.length && !lines[0].length) lines.shift();
  return lines;
}
function pptxRuns(runs, base, para) {
  return runs.map((r, i) => ({
    text: r.text,
    options: {
      fontFace: r.face || base.fontFace || SANS, fontSize: r.size || base.fontSize, bold: r.bold != null ? r.bold : base.bold,
      italic: r.italic, color: r.color || base.color, ...(r.highlight ? { highlight: r.highlight } : {}),
      ...(r.hyperlink ? { hyperlink: { url: r.hyperlink } } : {}),
      ...(r.breakLine ? { breakLine: true } : {}), ...(i === 0 && para ? para : {}),
    },
  }));
}

// ── Blocks ───────────────────────────────────────────────────────────────────
function para(n, x, y, w, pt, color, o = {}) {
  const base = { size: undefined };
  const runs = normRuns(inlineRuns(n, { size: pt, bold: o.bold }));
  if (!runs.length) return 0;
  const bw = o.maxW ? Math.min(w, o.maxW) : w;
  const h = textH(runs, pt, bw);
  addText(pptxRuns(runs, { fontSize: pt, color, bold: o.bold }), { x, y, w: bw, h, lineSpacingMultiple: o.ls || 1.0, objectName: o.name });
  return h;
}

function bullets(n, x, y, w) {
  const pt = has(n, "tight") ? 16.5 : 19.5, gap = 0.19, ind = 0.3;
  const items = kids(n).filter((k) => k.t === "li");
  let h = 0; const all = [];
  items.forEach((li, i) => {
    const runs = normRuns(inlineRuns(li, { size: pt }));
    h += textH(runs, pt, w - ind) + (i ? gap : 0);
    const pr = pptxRuns(runs, { fontSize: pt, color: INK }, { bullet: { code: "2013", indent: 22 }, paraSpaceAfter: 13 });
    pr[pr.length - 1].options.breakLine = i < items.length - 1;
    all.push(...pr);
  });
  addText(all, { x, y, w, h: h + 0.1, lineSpacingMultiple: 1.0, objectName: "Bullets" });
  return h;
}

function steps(n, x, y, w) {
  const pt = 18, gap = 0.15, ind = 0.5;
  let cy = y;
  kids(n).filter((k) => k.t === "li").forEach((li, i) => {
    const runs = normRuns(inlineRuns(li, { size: pt }));
    const h = Math.max(textH(runs, pt, w - ind), 0.34);
    addText(String(i + 1), { x, y: cy + 0.01, w: 0.3, h: 0.3, shape: pres.ShapeType.roundRect, rectRadius: 0.04, fill: { color: INK },
      color: GROUND, fontFace: MONO, fontSize: 11, bold: true, align: "center", valign: "middle", objectName: "Step number" });
    addText(pptxRuns(runs, { fontSize: pt, color: INK }), { x: x + ind, y: cy, w: w - ind, h, objectName: "Step" });
    cy += h + gap;
  });
  return cy - y - gap;
}

function codeBox(n, x, y, w, kind) {
  const term = kind === "term";
  const st = style(n);
  let want = term ? 14.25 : st["font-size"] ? parseFloat(st["font-size"]) * 0.75 : 12.75;
  const lines = toLines(inlineRuns(n, { color: term ? GROUND : INK }));
  const maxChars = Math.max(1, ...lines.map((l) => l.reduce((a, r) => a + r.text.length, 0)));
  const pad = 0.27, inner = w - pad * 2;
  let pt = Math.max(10.5, Math.min(want, (inner * 72) / (0.6 * maxChars)));
  // A ``` block (marked by --code-lines) also has to fit the page: shrink it to the space left
  // below it, keeping 0.75in for a line of text after it. Never below 10.5pt.
  if (!term && st["--code-lines"]) {
    const room = BOTTOM - y - 0.75 - pad * 2;
    pt = Math.max(10.5, Math.min(pt, (room * 72) / (lines.length * 1.3)));
  }
  const h = lines.length * pt * 1.3 / 72 + pad * 2;
  const flat = [];
  lines.forEach((l, i) => {
    const rr = l.length ? l : [{ text: " " }];
    const pr = pptxRuns(rr, { fontFace: MONO, fontSize: pt, color: term ? GROUND : INK });
    pr[pr.length - 1].options.breakLine = i < lines.length - 1;
    flat.push(...pr);
  });
  addText(flat, { x, y, w, h, shape: pres.ShapeType.roundRect, rectRadius: 0.06, fill: { color: term ? INK : CODEBG },
    margin: pad * 72, lineSpacingMultiple: 1.05, objectName: term ? "Terminal" : "Code" });
  return h;
}

function table(n, x, y, w) {
  const trs = []; const grab = (el) => kids(el).forEach((k) => (k.t === "tr" ? trs.push(k) : grab(k)));
  grab(n);
  const rows = trs.map((tr) => kids(tr).map((c) => ({ th: c.t === "th", node: c })));
  const nc = rows[0].length;
  const firstFixed = rows.slice(1).some((r) => (style(r[0].node).width || "") === "150px") || true;
  const weights = [];
  for (let c = 0; c < nc; c++) {
    let m = 6;
    rows.forEach((r) => { const len = Math.min(48, nodeText(r[c].node).trim().length); m = Math.max(m, len); });
    weights.push(c === 0 ? 0 : m);
  }
  const fw = 1.56;
  const rest = w - fw, tot = weights.slice(1).reduce((a, b) => a + b, 0) || 1;
  const colW = weights.map((m, c) => (c === 0 ? fw : (rest * m) / tot));
  let total = 0; const rowH = [];
  const data = rows.map((r) => {
    let maxH = 0;
    const cells = r.map((c, ci) => {
      const head = c.th, first = ci === 0;
      const pt = head ? 10.5 : first ? 11.25 : 15;
      let runs = normRuns(inlineRuns(c.node, { size: pt }));
      if (head || first) runs = runs.map((q) => ({ ...q, text: q.text.toUpperCase() }));
      if (!runs.length) runs = [{ text: " " }];
      maxH = Math.max(maxH, textH(runs, pt, colW[ci] - 0.28));
      const base = { fontFace: head || first ? MONO : SANS, fontSize: pt, color: head || first ? MUTED : INK };
      return { text: pptxRuns(runs, base), options: { border: [{ type: "none" }, { type: "none" }, { type: "solid", pt: 0.75, color: RULE }, { type: "none" }], valign: "top" } };
    });
    const h = maxH + 0.22; rowH.push(h); total += h;
    return cells;
  });
  mark(y, total);
  if (!ctx.dry) ctx.slide.addTable(data, { x, y, w, colW, rowH, margin: [5, 8, 5, 8], autoPage: false, objectName: "Table" });
  return total;
}

function facts(n, x, y, w) {
  const dtW = 1.56, gap = 0.19, pt = 16.5;
  let cy = y;
  const rows = kids(n).filter((k) => has(k, "fact"));
  const rowGap = n.a && /gap:\s*16px/.test(n.a.style || "") ? 0.17 : 0.23;
  rows.forEach((f, i) => {
    const dt = find(f, "dt"), dd = find(f, "dd");
    const runs = normRuns(inlineRuns(dd, { size: pt }));
    const h = Math.max(textH(runs, pt, w - dtW - gap), 0.3);
    addShape(pres.ShapeType.line, { x, y: cy, w, h: 0, line: { color: RULE, width: 0.75 } });
    addText(nodeText(dt).trim().toUpperCase(), { x, y: cy + 0.17, w: dtW, h: 0.25, fontFace: MONO, fontSize: 10.5, color: inkColor(dt), charSpacing: 1, objectName: "Fact label" });
    addText(pptxRuns(runs, { fontSize: pt, color: INK }), { x: x + dtW + gap, y: cy + 0.14, w: w - dtW - gap, h, objectName: "Fact" });
    cy += 0.14 + h + (i < rows.length - 1 ? rowGap : 0.05);
  });
  return cy - y;
}

function chips(n, x, y, w) {
  const known = has(n, "known");
  const pt = 12, chH = 0.34, gap = 0.105;
  let cx = x, cy = y, rows = 1;
  kids(n).forEach((s) => {
    const text = nodeText(s).trim(), lead = has(s, "lead");
    const cwid = lead ? text.length * 0.6 * 10 / 72 + 0.5 : text.length * 0.6 * pt / 72 + 0.26;
    if (cx > x && cx + cwid > x + w) { cx = x; cy += chH + gap; rows++; }
    if (lead) addText(text.toUpperCase(), { x: cx, y: cy + 0.06, w: cwid, h: 0.22, fontFace: MONO, fontSize: 10, color: INK, charSpacing: 1, wrap: false, objectName: "Chip label" });
    else addText(text, { x: cx, y: cy, w: cwid, h: chH, shape: pres.ShapeType.roundRect, rectRadius: 0.04, line: { color: RULE, width: 1 },
      fontFace: MONO, fontSize: pt, color: MUTED, align: "center", valign: "middle", objectName: "Chip" });
    cx += cwid + gap;
  });
  return rows * chH + (rows - 1) * gap;
}

function ledger(n, x, y, w) {
  const rowsPer = parseInt(((n.a.style || "").match(/--rows:\s*(\d+)/) || [])[1] || "9", 10);
  const items = kids(n).map((k) => {
    if (has(k, "group")) return { g: true, text: nodeText(k).trim(), color: inkColor(k) };
    const em = find(k, "em");
    const name = (k.k || []).filter((q) => typeof q === "string").join("").trim();
    return { g: false, name, desc: em ? nodeText(em).trim() : "" };
  });
  const colGap = 0.5, cwid = (w - colGap) / 2;
  const cols = [items.slice(0, rowsPer), items.slice(rowsPer)];
  let maxH = 0;
  cols.forEach((col, ci) => {
    let cy = y; const cx = x + ci * (cwid + colGap);
    col.forEach((it) => {
      if (it.g) {
        cy += 0.12;
        addShape(pres.ShapeType.roundRect, { x: cx, y: cy + 0.05, w: 0.125, h: 0.125, rectRadius: 0.02, fill: { color: it.color }, line: { type: "none" } });
        addText(it.text.toUpperCase(), { x: cx + 0.22, y: cy, w: cwid - 0.22, h: 0.24, fontFace: MONO, fontSize: 10.5, color: it.color, charSpacing: 1, objectName: "Ledger group" });
        cy += 0.3;
      } else {
        addText("+", { x: cx, y: cy, w: 0.22, h: 0.26, fontFace: MONO, fontSize: 13.5, bold: true, color: CAT.plus });
        addText(it.name, { x: cx + 0.23, y: cy, w: cwid - 0.23, h: 0.26, fontFace: MONO, fontSize: 13.5, color: INK, objectName: "Ledger resource" });
        cy += 0.27;
        if (it.desc) { addText(it.desc, { x: cx + 0.23, y: cy, w: cwid - 0.23, h: 0.22, fontFace: SANS, fontSize: 12, color: MUTED }); cy += 0.22; }
        cy += 0.06;
      }
    });
    maxH = Math.max(maxH, cy - y);
  });
  return maxH;
}

function legend(n, x, y) {
  let cx = x;
  kids(n).forEach((sp) => {
    const text = nodeText(sp).trim(), col = inkColor(sp), wd = text.length * 0.55 * 13.5 / 72 + 0.3;
    addShape(pres.ShapeType.roundRect, { x: cx, y: y + 0.06, w: 0.15, h: 0.15, rectRadius: 0.02, fill: { color: col }, line: { type: "none" } });
    addText(text, { x: cx + 0.23, y, w: wd, h: 0.26, fontFace: SANS, fontSize: 13.5, color: INK, wrap: false, objectName: "Legend" });
    cx += 0.23 + wd + 0.2;
  });
  return 0.3;
}

function planSummary(n, x, y, w) {
  const runs = [];
  kids(n).forEach((s, i) => {
    if (i) runs.push({ text: "\u00A0\u00A0\u00A0\u00A0\u00A0", face: MONO });
    normRuns(inlineRuns(s, { size: 13.5 })).forEach((r) => runs.push({ ...r, face: MONO, ...(r.bold ? { color: CAT.plus } : {}) }));
  });
  const yy = Math.max(y + 0.15, BOTTOM - 0.45);
  addShape(pres.ShapeType.line, { x, y: yy, w, h: 0, line: { color: RULE, width: 0.75 } });
  addText(pptxRuns(runs, { fontSize: 13.5, color: INK }), { x, y: yy + 0.1, w, h: 0.3, objectName: "Plan summary" });
  return yy + 0.4 - y;
}

function callout(n, x, y, w) {
  let cy = y;
  kids(n).forEach((k, i) => {
    if (i) cy += 0.21;
    if (has(k, "label")) { addText(nodeText(k).trim().toUpperCase(), { x, y: cy, w, h: 0.22, fontFace: MONO, fontSize: 10.5, color: MUTED, charSpacing: 1 }); cy += 0.22; }
    else if (k.t === "pre") cy += codeBox(k, x, cy, w, "pre");
    else cy += para(k, x, cy, w, 16.5, INK, { name: "Callout" });
  });
  return cy - y;
}

function edges(n, x, y, w) {
  let cy = y;
  const li = kids(n).filter((k) => k.t === "li");
  li.forEach((it, i) => {
    const tag = find(it, "span", "tag"), spans = kids(it).filter((k) => k.t === "span" && !has(k, "tag"));
    const real = has(tag, "real");
    addText(nodeText(tag).trim().toUpperCase(), { x, y: cy + 0.03, w: 1.05, h: 0.26, shape: pres.ShapeType.roundRect, rectRadius: 0.03,
      line: { color: real ? CAT.plus : CAT.access, width: 1 }, fontFace: MONO, fontSize: 10, color: real ? CAT.plus : CAT.access,
      align: "center", valign: "middle", charSpacing: 0.5, objectName: "Tag" });
    const runs = normRuns(inlineRuns(spans[0], { size: 15 }));
    const h = Math.max(textH(runs, 15, w - 1.25), 0.3);
    addText(pptxRuns(runs, { fontSize: 15, color: INK }), { x: x + 1.25, y: cy, w: w - 1.25, h, objectName: "Note" });
    cy += h + 0.17;
  });
  return cy - y - 0.17;
}

function columns(parts, x, y, w, gap, fr) {
  const total = fr.reduce((a, b) => a + b, 0), usable = w - gap * (parts.length - 1);
  let cx = x, maxH = 0;
  parts.forEach((p, i) => {
    const cwid = (usable * fr[i]) / total;
    const h = block(p, cx, y, cwid) || 0;
    maxH = Math.max(maxH, h);
    cx += cwid + gap;
  });
  return maxH;
}

function marginTop(n) {
  const st = style(n);
  if (st["margin-top"]) return parseFloat(st["margin-top"]) * PX;
  if (has(n, "examples")) return has(n, "known") ? 0.125 : 0.27;
  return null;
}
const marginBottom = (n) => (style(n)["margin-bottom"] ? parseFloat(style(n)["margin-bottom"]) * PX : null);

function flow(list, x, y, w) {
  let cy = y, prevMb = null, first = true;
  for (const n of list) {
    if (!isEl(n) || n.t === "aside" || n.t === "h1") continue;
    const mt = marginTop(n);
    const gap = first ? 0 : mt != null ? mt : prevMb != null ? prevMb : GAP;
    const h = block(n, x, cy + gap, w);
    if (h == null) continue;
    cy += gap + h; prevMb = marginBottom(n); first = false;
  }
  return cy - y;
}

function fill(n, x, y, w) {
  const h = measure(() => flow(n.k, x, y, w));
  const off = Math.max(0, Math.min(0.8, (BOTTOM - y - h) / 2));
  flow(n.k, x, y + off, w);
  return h + off;
}

function block(n, x, y, w) {
  const c = cls(n);
  switch (n.t) {
    case "p":
      if (c.includes("lede")) return para(n, x, y, w, 21, MUTED, { maxW: 8.75, name: "Lede" });
      if (c.includes("big")) return para(n, x, y, w, 30, INK, { maxW: 9.4, name: "Statement" });
      if (c.includes("small")) return para(n, x, y, w, 13.5, MUTED);
      if (c.includes("quote")) return para(n, x, y, w, 54, INK, { bold: true, maxW: 9.2, ls: 0.95, name: "Question" });
      return para(n, x, y, w, 18, INK);
    case "h3": { const h = para(n, x, y, w, 21, INK, { bold: true }); return h + 0.08; }
    case "ul":
      if (c.includes("points")) return bullets(n, x, y, w);
      if (c.includes("edges")) return edges(n, x, y, w);
      break;
    case "ol": return steps(n, x, y, w);
    case "pre": return codeBox(n, x, y, w, "pre");
    case "table": return table(n, x, y, w);
    case "dl": return facts(n, x, y, w);
    case "figure": return figure(n, x, y, w);
    case "div":
      if (c.includes("term")) return codeBox(n, x, y, w, "term");
      if (c.includes("fill")) return fill(n, x, y, w);
      if (c.includes("cols-3")) return columns(kids(n), x, y, w, 0.375, [1, 1, 1]);
      if (c.includes("cols")) return columns(kids(n), x, y, w, 0.583, [1, 1]);
      if (c.includes("code-grid")) return columns(kids(n), x, y, w, 0.458, [1.35, 1]);
      if (c.includes("apptype")) return columns(kids(n), x, y, w, 0.667, [1.15, 1]);
      if (c.includes("callout")) return callout(n, x, y, w);
      if (c.includes("examples")) return chips(n, x, y, w);
      if (c.includes("ledger")) return ledger(n, x, y, w);
      if (c.includes("plan-summary")) return planSummary(n, x, y, w);
      if (c.includes("legend")) return legend(n, x, y);
      if (!c.length) return flow(n.k, x, y, w);
      break;
  }
  problems.push({ n: ctx.n, fatal: true, msg: `the PowerPoint export has no renderer for <${n.t}${n.c ? ' class="' + n.c + '"' : ""}>, so it was left out` });
  return 0;
}

// ── Figures: native chart for the resource-count slide, shapes for the rest ──
function figure(n, x, y, w) {
  const svg = find(n, "svg"), cap = find(n, "figcaption");
  const capRuns = cap ? normRuns(inlineRuns(cap, { size: 14.25 })) : [];
  const capH = cap ? textH(capRuns, 14.25, Math.min(w, 11)) : 0;
  const availH = BOTTOM - y - capH - 0.15;
  const label = (svg.a["aria-label"] || "");
  let used;
  {
    const vb = svg.a.viewBox.split(/[ ,]+/).map(Number);
    const s = Math.min(w / vb[2], availH / vb[3]);
    used = vb[3] * s;
    renderSvg(svg, x, y, s, vb);
  }
  if (cap) addText(pptxRuns(capRuns, { fontSize: 14.25, color: MUTED }), { x, y: y + used + 0.15, w: Math.min(w, 11), h: capH, objectName: "Caption" });
  return used + (cap ? 0.15 + capH : 0);
}

// ── SVG -> native shapes ─────────────────────────────────────────────────────
function catOf(c) { for (const k of Object.keys(CAT)) if (c.includes("b-" + k) || c.includes("seg-" + k)) return k; return null; }
function varColor(v) { const m = /var\(--(\w+)\)/.exec(v || ""); return m && CAT[m[1]] ? CAT[m[1]] : null; }

function renderSvg(svg, x0, y0, s, vb) {
  const X = (v) => x0 + (v - vb[0]) * s, Y = (v) => y0 + (v - vb[1]) * s, len = (v) => v * s;
  const lw = (px_) => Math.max(0.75, px_ * s * 72);
  const walk = (list) => kids({ k: list }).forEach((n) => {
    if (n.t === "defs") return;
    const c = cls(n), st = style(n), a = n.a;
    if (n.t === "g") return walk(n.k);
    if (n.t === "rect") {
      const rx = parseFloat(a.rx || 0), cat = catOf(c);
      const type = rx > 0 ? pres.ShapeType.roundRect : pres.ShapeType.rect;
      const o = { x: X(+a.x), y: Y(+a.y), w: len(+a.width), h: len(+a.height), ...(rx > 0 ? { rectRadius: len(rx) } : {}) };
      if (/^#[0-9a-f]{6}$/i.test(a.fill || "")) {
        // Preserve solid SVG fills, including the QR code's modules and quiet zone.
        addShape(type, { ...o, fill: { color: a.fill.slice(1) }, line: { type: "none" } });
      } else if (c.includes("zone")) {
        const col = varColor(st.stroke) || MUTED;
        addShape(type, { ...o, fill: { type: "none" }, line: { color: col, width: lw(2), ...(a["stroke-dasharray"] ? { dashType: "dash" } : {}) } });
      } else if (c.includes("b-ghost")) addShape(type, { ...o, fill: { type: "none" }, line: { color: MUTED, width: lw(2), dashType: "dash" } });
      else if (c.includes("b-plain")) addShape(type, { ...o, fill: { color: WHITE }, line: { color: MUTED, width: lw(2) } });
      else if (c.some((q) => q.startsWith("seg-"))) addShape(type, { ...o, fill: { color: CAT[cat] }, line: { color: GROUND, width: 0.75 } });
      else if (cat) addShape(type, { ...o, fill: { color: CAT[cat], transparency: 90 }, line: { color: CAT[cat], width: lw(2) } });
      else addShape(type, { ...o, fill: { type: "none" }, line: { color: MUTED, width: lw(1) } });
      return;
    }
    if (n.t === "text") {
      const text = nodeText(n).trim(); if (!text) return;
      let size = c.includes("lbl") ? 20 : c.includes("sub") ? 15 : c.includes("mono") || c.includes("arrow-label") || c.includes("tick") ? 14 : c.includes("seg-num") ? 16 : 16;
      if (st["font-size"]) size = parseFloat(st["font-size"]);
      const mono = c.includes("mono") || c.includes("arrow-label") || c.includes("tick") || c.includes("seg-num");
      const bold = c.includes("lbl") || c.includes("seg-num") || st["font-weight"] === "600";
      const color = varColor(st.fill) || (c.includes("seg-num") ? GROUND : c.includes("sub") || c.includes("arrow-label") || c.includes("tick") ? MUTED : INK);
      const pt = size * s * 72, face = mono ? MONO : SANS;
      const tw = text.length * cw(face, bold) * pt / 72 + 0.5, hh = pt * 1.3 / 72;
      const anchor = a["text-anchor"] || "start";
      const bx = anchor === "middle" ? X(+a.x) - tw / 2 : anchor === "end" ? X(+a.x) - tw : X(+a.x);
      addText(text, { x: bx, y: Y(+a.y) - pt * 0.93 / 72, w: tw, h: hh, fontFace: face, fontSize: pt, bold, color,
        align: anchor === "middle" ? "center" : anchor === "end" ? "right" : "left", wrap: false });
      return;
    }
    if (n.t === "line") { drawLine(+a.x1, +a.y1, +a.x2, +a.y2, c, false); return; }
    if (n.t === "path") {
      const nums = []; const re = /([MLHVZ])|(-?\d*\.?\d+)/g; let m, cmd = null, args = [], pts = [], cur = [0, 0];
      const flush = () => {
        if (cmd === "M" || cmd === "L") { cur = [args[0], args[1]]; pts.push(cur.slice()); }
        else if (cmd === "H") { cur = [args[0], cur[1]]; pts.push(cur.slice()); }
        else if (cmd === "V") { cur = [cur[0], args[0]]; pts.push(cur.slice()); }
        args = [];
      };
      const need = { M: 2, L: 2, H: 1, V: 1, Z: 0 };
      while ((m = re.exec(a.d))) {
        if (m[1]) { cmd = m[1]; args = []; if (need[cmd] === 0) flush(); }
        else { args.push(parseFloat(m[2])); if (args.length === need[cmd]) { flush(); } }
      }
      const arrow = !!a["marker-end"];
      for (let i = 1; i < pts.length; i++) drawLine(pts[i - 1][0], pts[i - 1][1], pts[i][0], pts[i][1], c, arrow && i === pts.length - 1);
      return;
    }
  });
  function drawLine(x1, y1, x2, y2, c, arrow) {
    const dashed = c.includes("dash") || c.includes("no");
    const color = c.includes("grid") ? RULE : c.includes("no") ? CAT.access : c.includes("dash") ? MUTED : INK;
    const px1 = X(x1), py1 = Y(y1), px2 = X(x2), py2 = Y(y2);
    addShape(pres.ShapeType.line, { x: Math.min(px1, px2), y: Math.min(py1, py2), w: Math.abs(px2 - px1), h: Math.abs(py2 - py1),
      flipH: px2 < px1, flipV: py2 < py1,
      line: { color, width: c.includes("grid") ? 0.75 : lw(2), ...(dashed ? { dashType: "dash" } : {}), ...(arrow ? { endArrowType: "triangle" } : {}) } });
  }
  walk(svg.k);
}

// ── Eyebrow, title, notes ────────────────────────────────────────────────────
function eyebrow(n) {
  if (!n) return;
  const chip = find(n, "span", "chip");
  const rest = (n.k || []).filter((q) => typeof q === "string" || !has(q, "chip")).map(nodeText).join("").trim().toUpperCase();
  let x = L;
  if (chip) {
    const t = nodeText(chip).trim().toUpperCase(), cwid = t.length * 0.6 * 10 / 72 + 0.24;
    addText(t, { x, y: 0.5, w: cwid, h: 0.26, shape: pres.ShapeType.roundRect, rectRadius: 0.03, fill: { color: INK }, color: GROUND,
      fontFace: MONO, fontSize: 10, bold: true, align: "center", valign: "middle", charSpacing: 0.5, objectName: "Eyebrow chip" });
    x += cwid + 0.14;
  }
  if (rest) addText(rest, { x, y: 0.52, w: W - (x - L), h: 0.24, fontFace: MONO, fontSize: 11, color: MUTED, charSpacing: 1, objectName: "Eyebrow" });
}

let lastSection = null;
function buildSlide(s) {
  ctx.n = s.n; ctx.maxY = 0; ctx.dry = false;
  const t = s.tree, top = kids(t);
  const isTitle = s.cls.includes("title-slide");
  const head = top.find((k) => k.t === "div" && has(k, "head"));
  const eb = head ? find(head, "p", "eyebrow") : top.find((k) => k.t === "p" && has(k, "eyebrow"));
  const titleNode = isTitle ? top.find((k) => k.t === "h1") : head ? find(head, "h2") : findDeep(t, "h1", "stackname");
  const layout = isTitle ? "TITLE" : titleNode ? "CONTENT" : "BARE";
  if (s.section !== lastSection) { pres.addSection({ title: s.section }); lastSection = s.section; }
  const slide = pres.addSlide({ masterName: layout, sectionTitle: s.section });
  ctx.slide = slide;

  const notes = find(t, "aside", "notes");
  // Collapse whitespace in prose, but keep a ``` block's (<pre>) line breaks and spacing.
  if (notes) slide.addNotes(kids(notes).map((p) => p.t === "pre"
    ? nodeText(p).replace(/^\n+|\s+$/g, "")
    : nodeText(p).replace(/\s+/g, " ").trim()).filter(Boolean).join("\n\n"));

  eyebrow(eb);
  let y0 = 1.3;
  if (titleNode) {
    const text = nodeText(titleNode).trim();
    slide.addText(text, { placeholder: "title" });
    if (!isTitle) { const lines = Math.ceil((text.length * 0.54 * 36) / 72 / W); y0 = 0.9 + lines * 0.58 + 0.32; }
  }
  if (isTitle) {
    const meta = top.find((k) => has(k, "title-meta"));
    const lede = find(meta, "p", "lede");
    const runs = normRuns(inlineRuns(lede, { size: 21 }));
    addText(pptxRuns(runs, { fontSize: 21, color: MUTED }), { x: L, y: 5.6, w: 7.4, h: textH(runs, 21, 7.4), objectName: "Subtitle" });
    const ribbonW = 460 * PX, widths = [2, 9, 3, 5, 5], tot = 24; let rx = L + W - ribbonW;
    ["edge", "network", "compute", "data", "access"].forEach((k, i) => {
      const rw = (ribbonW * widths[i]) / tot;
      addShape(pres.ShapeType.rect, { x: rx, y: 6.5, w: rw, h: 0.17, fill: { color: CAT[k] }, line: { type: "none" }, objectName: "Category key" });
      rx += rw;
    });
  } else {
    flow(top.filter((k) => !(k === head || k === eb || k === titleNode || (k.t === "aside"))), L, y0, W);
  }
  if (!isTitle && ctx.maxY > BOTTOM + 0.2) problems.push({ n: s.n, fatal: false, msg: `"${s.title}" runs to ${ctx.maxY.toFixed(2)}in; the usable area ends at ${BOTTOM.toFixed(2)}in. Shorten it or split the slide` });
}

(async () => {
  for (const s of IR) { if (ONLY && !ONLY.includes(s.n)) continue; buildSlide(s); }
  await pres.writeFile({ fileName: OUT });
  await applyTheme(OUT, THEME);
  console.log(`wrote ${OUT}`);
  for (const p of problems) console.error(`  ${p.fatal ? "ERROR" : "warning"}: slide ${p.n}: ${p.msg}`);
  if (problems.some((p) => p.fatal)) { console.error("The deck was written, but content is missing from it (see ERROR above)."); process.exitCode = 1; }
})();
