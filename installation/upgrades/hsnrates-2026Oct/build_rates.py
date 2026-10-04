#!/usr/bin/env python3
"""Build HSN -> GST rate mapping from the notifications in force (Oct 2026).

Sources (raw/):
  taxcode-9-2025.txt    Notification 9/2025-CT(R) as amended by 19/2025 (31.12.2025,
                        w.e.f. 01.02.2026) and 01/2026 (30.04.2026, w.e.f. 01.05.2026)
                        + corrigendum 06.05.2026. Schedules I..VII = CT rates
                        2.5 / 9 / 20 / 1.5 / 0.125 / 0.75 / (14 = OMITTED 01.02.2026).
  notif-10-2025-ctr.txt Notification 10/2025-CT(R) dated 17.09.2025 - exempts the listed
                        goods from the whole of central tax (supersedes 2/2017-CT(R)).
Cess: NIL on all goods since 01.02.2026 (02/2025-CC(R) w.e.f. 22.09.2025, 03/2025-CC(R)
      w.e.f. 01.02.2026) - not represented here.

Tiering (see REPORT.md):
  A  entry covers the whole heading  -> safe to apply to the head and its children
  B  exact tariff-item entry         -> applies to that item only (no smearing)
  R  residual 18% (9/2025 Sch II S.No 639: goods not specified in any Schedule)
  X  entry names a narrow subset     -> NOT applied by prefix; needs review
"""
import re, csv, collections

RAW = "raw"

CT_TO_IGST = {2.5: 5.0, 9.0: 18.0, 20.0: 40.0, 1.5: 3.0, 0.125: 0.25, 0.75: 1.5}
RESIDUAL_IGST = 18.0

# markers that an entry names a specific subset rather than the whole heading
NARROW_RE = re.compile(
    r"\b(namely|supplied by|only|such as|for use in|used in|of a kind used|intended for|"
    r"in the manufacture|cleared as|from the factory|individual|handmade|khadi|rosaries|"
    r"bangles?|prasadam|rakhi|idols?|gift items|lottery|passenger baggage|human hair|"
    r"organic manure|by a |to a |in respect of)\b", re.I)

COND_RE = re.compile(
    r"pre-packaged|prepackaged|other than fresh or chilled|unit container|sale value|"
    r"not exceeding|brand name|labelled", re.I)


# ---------------------------------------------------------------- cell parsing

def norm_code(tok):
    tok = tok.strip().replace(" ", "").replace("\u2013", "-")
    return tok if re.fullmatch(r"\d{2,8}", tok) else None


def parse_cell(cell):
    s = cell.strip().rstrip(".").strip()
    inc, inc_r, exc, exc_r = [], [], [], []
    catchall = "any chapter" in s.lower()

    # footnote marker: "5 [ 2202 91 00, 2202 99 99 ]" -> the bracket wins
    m = re.fullmatch(r"(\d{1,2})\s*\[\s*(.*?)\s*\]", s, re.S)
    if m and len(m.group(1)) == 1:
        s = m.group(2)

    excl_texts = re.findall(r"[\(\[]\s*(?:other than|except|Except|OTHER THAN)\s+(.*?)[\)\]]", s, re.S)
    body = re.sub(r"[\(\[]\s*(?:other than|except|Except|OTHER THAN)\s+.*?[\)\]]", " ", s, flags=re.S)
    excl_texts += re.findall(r"\bexcept\s+([\d ,]+)", body, re.I)
    body = re.sub(r"\bexcept\s+[\d ,]+", " ", body, flags=re.I)

    def toks(t):
        t = t.replace("\u2013", "-")
        for part in re.split(r",| and | or ", t):
            part = part.strip()
            if not part:
                continue
            mr = re.fullmatch(r"(\d{2,8})\s*(?:-|to)\s*(\d{2,8})", part)
            if mr:
                yield ("range", mr.group(1), mr.group(2))
            else:
                c = norm_code(part)
                if c:
                    yield ("code", c)
                elif re.search(r"any", part, re.I) and re.search(r"chapter", part, re.I):
                    yield ("any", part)

    for t in toks(body):
        if t[0] == "code":
            inc.append(t[1])
        elif t[0] == "range":
            inc_r.append((t[1], t[2]))
    for x in excl_texts:
        for t in toks(x):
            if t[0] == "code":
                exc.append(t[1])
            elif t[0] == "range":
                exc_r.append((t[1], t[2]))
            elif t[0] == "any":
                exc.append("ANY")
    return inc, inc_r, exc, exc_r, catchall


# ---------------------------------------------------------------- notifications

def parse_9_2025():
    lines = open(f"{RAW}/taxcode-9-2025.txt", encoding="utf8").read().split("\n")
    heads = [(i, m.group(1), float(m.group(2)))
             for i, l in enumerate(lines)
             for m in [re.match(r"\s*Schedule ([IVX]+)\s*[-\u2013]\s*([\d.]+)\s*%", l)] if m]
    entries, notes = [], []
    for k, (start, roman, ctrate) in enumerate(heads):
        if roman == "VII":
            notes.append("Schedule VII (14%) omitted w.e.f. 01.02.2026 - its goods (pan "
                         "masala, 2401-2404) are now in Schedule III at 20% CT / 40% IGST")
            continue
        end = heads[k + 1][0] if k + 1 < len(heads) else len(lines)
        seg = lines[start:end]
        for j, l in enumerate(seg):
            m = re.match(r"^\s*(\d{1,3})\.\s*$", l)
            if not m or j + 1 >= len(seg):
                continue
            cell = seg[j + 1].strip()
            desc = " ".join(x.strip() for x in seg[j + 2:j + 5] if x.strip())[:400]
            inc, inc_r, exc, exc_r, catchall = parse_cell(cell)
            entries.append(dict(sno=int(m.group(1)), sched=roman, ctrate=ctrate, cell=cell,
                                desc=desc, inc=inc, inc_r=inc_r, exc=exc, exc_r=exc_r,
                                catchall=catchall, igst=CT_TO_IGST[ctrate],
                                src=f"9/2025-CT(R) Sch {roman} S.No {int(m.group(1))}",
                                kind="schedule"))
    return entries, notes


def parse_10_2025():
    t = open(f"{RAW}/notif-10-2025-ctr.txt", encoding="utf8").read()
    rows = re.findall(r"^\|\s*(\d+)\.\s*\|\s*([^|]+?)\s*\|(.*?)\|\s*$", t, re.M)
    seen, entries = set(), []
    for sno, cell, desc in rows:
        if sno in seen:
            continue
        seen.add(sno)
        inc, inc_r, exc, exc_r, catchall = parse_cell(cell)
        entries.append(dict(sno=int(sno), cell=cell.strip(), desc=desc.strip()[:400],
                            inc=inc, inc_r=inc_r, exc=exc, exc_r=exc_r, catchall=catchall,
                            igst=0.0, src=f"10/2025-CT(R) S.No {int(sno)}", kind="exempt"))
    return entries


# ---------------------------------------------------------------- matching

def entry_is_narrow(e):
    if not e["inc"]:
        return False
    if e["desc"].lower().startswith("all goods"):
        return False
    return bool(NARROW_RE.search(e["desc"]))


def build_table(entries):
    """prefix -> entry dict; exemption wins over a schedule at equal prefix length."""
    tbl = {}
    for e in entries:
        for p in e["inc"]:
            cur = tbl.get(p)
            if cur is None or (e["kind"] == "exempt" and cur["kind"] != "exempt"):
                tbl[p] = e
    return tbl


def in_range(code, lo, hi):
    return len(lo) == len(hi) and len(code) >= len(lo) and lo <= code[:len(lo)] <= hi


def excluded(code, e):
    if any(x == "ANY" for x in e["exc"]):
        return True
    if any(code.startswith(x) for x in e["exc"]):
        return True
    return any(in_range(code, lo, hi) for lo, hi in e["exc_r"])


def resolve(code, tbl, range_entries):
    """Longest prefix wins. A narrow entry only applies at item level (prefix >= 6)."""
    skipped_narrow = []
    for ln in range(len(code), 1, -1):
        p = code[:ln]
        e = tbl.get(p)
        if e is None or excluded(code, e):
            continue
        narrow = entry_is_narrow(e)
        if narrow and len(p) < 6:
            skipped_narrow.append(e)
            continue
        return (e["igst"], e["src"], bool(COND_RE.search(e["desc"])), e["kind"], p,
                "B" if narrow else "A", skipped_narrow)
    for e in range_entries:
        for lo, hi in e["inc_r"]:
            if in_range(code, lo, hi):
                return (e["igst"], e["src"], False, e["kind"], f"{lo}-{hi}", "A", skipped_narrow)
    return (RESIDUAL_IGST, "9/2025-CT(R) Sch II S.No 639 (residual)", False, "residual", "-",
            "R", skipped_narrow)


def main():
    e9, notes = parse_9_2025()
    e10 = parse_10_2025()
    print(f"parsed: 9/2025 entries={len(e9)}  10/2025 exempt entries={len(e10)}")
    for n in notes:
        print("  note:", n)

    entries = e9 + e10
    tbl = build_table(entries)
    narrow_4 = sorted({(e["sno"], e["src"], e["cell"], e["desc"][:90])
                       for e in entries if entry_is_narrow(e) and all(len(p) < 6 for p in e["inc"])})
    print(f"prefixes: {len(tbl)}  widths={dict(sorted(collections.Counter(len(p) for p in tbl).items()))}")
    print(f"narrow entries that cannot be applied by prefix (need review): {len(narrow_4)}")

    with open("rates_by_prefix.csv", "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["prefix", "igst_rate", "cgst_rate", "sgst_rate", "kind", "tier",
                    "conditional", "source_ref", "cell", "description"])
        for p in sorted(tbl, key=lambda x: (len(x), x)):
            e = tbl[p]
            tier = "B" if entry_is_narrow(e) else ("A" if len(p) >= 6 else "A")
            w.writerow([p, e["igst"], round(e["igst"] / 2, 3), round(e["igst"] / 2, 3),
                        e["kind"], tier, int(bool(COND_RE.search(e["desc"]))), e["src"],
                        e["cell"], e["desc"][:200]])

    rows, stats, tier_counts = [], collections.Counter(), collections.Counter()
    skipped_report = collections.Counter()
    for line in open("db_codes.tsv", encoding="utf8"):
        parts = line.rstrip("\n").split("\t")
        if len(parts) < 7:
            continue
        code, c4, desc, cgst, sgst, igst, cess = parts
        igst_v, src, cond, kind, pref, tier, skipped = resolve(code, tbl, e9 + e10)
        for e in skipped:
            skipped_report[(e["src"], e["cell"], e["desc"][:70])] += 1
        stats[(tier, kind, igst_v)] += 1
        tier_counts[tier] += 1
        rows.append([code, c4, cgst, sgst, igst, igst_v, round(igst_v / 2, 3), kind, tier,
                     pref, int(cond), src, desc])

    with open("db_mapped.csv", "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["hsn_code", "hsn4", "cgst_old", "sgst_old", "igst_old", "igst_new",
                    "cgst_new", "kind", "tier", "matched_prefix", "conditional",
                    "source_ref", "description"])
        w.writerows(rows)

    with open("narrow_review.csv", "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["entry", "cell", "igst_rate_of_entry", "db_rows_in_its_head", "description"])
        for (src, cell, desc), n in sorted(skipped_report.items(), key=lambda x: -x[1]):
            w.writerow([src, cell, "", n, desc])

    print("\n-- tiers (rows) --")
    for t, n in sorted(tier_counts.items()):
        print(f"  tier {t}: {n}")
    print("\n-- tier/kind/rate --")
    for (t, k, r), n in sorted(stats.items()):
        print(f"  {t} {k:9s} igst={r:<6} {n}")
    print("\n-- rate distribution of the new values --")
    for r, n in sorted(collections.Counter(x[5] for x in rows).items()):
        print(f"  IGST {r:6}% {n:6d}")
    print(f"\ncondition-dependent rows: {sum(1 for x in rows if x[10])}")
    print(f"rows changed vs stored value: {sum(1 for x in rows if float(x[4]) != x[5])}")


if __name__ == "__main__":
    main()
