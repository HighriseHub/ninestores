#!/usr/bin/env python3
"""Turn the parsed notifications into a per-HSN-code rate mapping.

A notification entry like "3926 - Other articles of plastics" covers a whole heading,
but "3926 - Plastic bangles" or "3304 - Kajal, Kumkum, Bindi" covers one article inside
it. Applying an entry's rate to the whole heading would put 0% on all plastics. So every
(cell, entry) pair becomes a rule whose kind is decided by comparing the entry's wording
with the heading's own tariff definition (the DB's 4-digit row, which carries the exact
CBIC heading text):

  item  (B)  cell is a 6/8-digit tariff item      -> applies to that item only
  head  (A)  wording is the heading's definition   -> applies to the head and children
  sub   (C)  wording names specific articles       -> applied only to the child rows
                                                    whose description matches; listed
                                                    in review_sub_placements.csv
  res   (R)  goods not specified in any Schedule   -> 18% (9/2025 Sch II S.No 639)
"""
import re, csv, collections
import build_rates as B

PACKAGED_POLICY = "taxed"   # taxed | nil : how a pre-packaged / not-pre-packaged pair is read

STOP = set("""and or the for with other than not any all goods of to in by including whether
containing etc name names called namely such as purpose purposes use used from on at a an
is are be been being having made make whatever it its their thereof under over into this
that these those which who whose will shall may can also there where when but if then so no
yes specified specified elsewhere included excluded case may""".split())

COND_PHRASES = [
    r"pre\s*-?\s*packaged(\s+and\s+labelled)?", r"other than pre\s*-?\s*packaged and labelled",
    r"other than fresh or chilled", r"fresh or chilled", r"unit container",
    r"sale value not exceeding[^,;.]*", r"branded or otherwise", r"brand(ed)? name",
    r"by whatever name (it is )?known", r"of all types", r"whether or not[^,;.]*",
    r"not exceeding[^,;.]*", r"put up in[^,;.]*", r"labelled", r"packaged",
]
HEAD_WIDE_PREFIX = re.compile(
    r"^\s*(all\s+goods|goods\s+other\s+than|other\s+goods|goods|others\b|all\b|the\s+following)",
    re.I)


def clean(s):
    s = s.lower()
    for p in COND_PHRASES:
        s = re.sub(p, " ", s)
    s = re.sub(r"\(.*?\)", " ", s)
    s = re.sub(r"[^a-z0-9 ]+", " ", s)
    return s


def toks(s):
    out = set()
    for w in clean(s).split():
        if len(w) > 2 and w not in STOP:
            out.add(w[:-1] if w.endswith("s") and len(w) > 4 else w)
    return out


def phrases(s):
    return [p for p in re.split(r"[;,.]| and | or ", clean(s)) if p.strip()]


def load_db():
    rows = []
    for line in open("db_codes.tsv", encoding="utf8"):
        p = line.rstrip("\n").split("\t")
        if len(p) < 7:
            continue
        rows.append(dict(code=p[0], c4=p[1], desc=p[2], old=(p[3], p[4], p[5]),
                         tokens=toks(p[2]), assign=None, ambiguous=False))
    return rows, {r["code"]: r for r in rows}


def in_range(code, lo, hi):
    return len(lo) == len(hi) and len(code) >= len(lo) and lo <= code[:len(lo)] <= hi


def excluded(code, e):
    if any(x == "ANY" for x in e["exc"]):
        return True
    if any(code.startswith(x) for x in e["exc"]):
        return True
    return any(in_range(code, lo, hi) for lo, hi in e["exc_r"])


# ---------------------------------------------------------------- rule build

def build_rules(entries, by_code):
    """(prefix, entry, kind, score) for every prefix of every entry."""
    rules = []
    for e in entries:
        for p in e["inc"]:
            if len(p) >= 6:
                rules.append((p, e, "item", 1.0))
                continue
            head = by_code.get(p)
            D = head["tokens"] if head else set()
            E = toks(e["desc"])
            if not E or HEAD_WIDE_PREFIX.match(e["desc"]):
                rules.append((p, e, "head", 1.0))
                continue
            score = len(E & D) / len(E)
            if score >= 0.6 or (len(E) >= 3 and score >= 0.45):
                rules.append((p, e, "head", score))
            elif score >= 0.3:
                rules.append((p, e, "sub", score))   # uncertain -> conservative
            else:
                rules.append((p, e, "sub", score))
    return rules


def rank(kind):
    return {"item": 3, "sub": 2, "head": 1, "res": 0}[kind]


def better(new, cur):
    """new/cur = dict(kind, prefix, igst, cond, score, src)"""
    if cur is None:
        return True
    if rank(new["rkind"]) != rank(cur["rkind"]):
        return rank(new["rkind"]) > rank(cur["rkind"])
    if len(new["prefix"]) != len(cur["prefix"]):
        return len(new["prefix"]) > len(cur["prefix"])
    if abs(new["score"] - cur["score"]) > 0.1:
        return new["score"] > cur["score"]
    # genuine collision at the same specificity
    if new["ratekind"] == "exempt" and not new["cond"] and not (cur["ratekind"] == "exempt" and not cur["cond"]):
        return True
    return False


def main():
    e9, notes = B.parse_9_2025()
    e10 = B.parse_10_2025()
    entries = e9 + e10
    for e in entries:
        e["desc"] = re.split(r"\s+\d{1,3}\.\s+\d{2,8}\s*$", e["desc"])[0].strip()
        e["cond"] = bool(B.COND_RE.search(e["desc"]))

    rows, by_code = load_db()
    rules = build_rules(entries, by_code)
    kinds = collections.Counter(k for _, _, k, _ in rules)
    print(f"db rows={len(rows)} entries={len(entries)} rules={len(rules)} {dict(kinds)}")

    def mk(e, kind, prefix, score):
        return dict(ratekind=e["kind"], tier={"item": "B", "sub": "C", "head": "A",
                                             "fallback": "M"}[kind],
                    igst=e["igst"], src=e["src"], cond=e["cond"], prefix=prefix,
                    score=score, rkind=kind)

    def is_packaged(e):
        return bool(re.search(r"pre\s*-?\s*packaged", e["desc"], re.I)) and \
               not re.search(r"other than pre\s*-?\s*packaged", e["desc"], re.I)

    def is_loose(e):
        return bool(re.search(r"other than pre\s*-?\s*packaged", e["desc"], re.I))

    # ---- headings the law splits between several entries with different rates.
    # Filler = the entry whose wording is the heading's own definition (kind "head").
    #   * exactly one filler -> it keeps filling the remainder (tier A);
    #   * a pre-packaged / not-pre-packaged pair -> decided by PACKAGED_POLICY;
    #   * any other collision -> no filler; every entry is placed by description and
    #     the leftovers take the lowest rate in the heading, flagged (tier M).
    per_head = collections.defaultdict(list)
    for i, (p, e, k, s) in enumerate(rules):
        if k in ("head", "sub"):
            per_head[p].append(i)
    fallback, conflict_heads = {}, {}
    for p, idxs in per_head.items():
        heads = [i for i in idxs if rules[i][2] == "head"]
        rates = {rules[i][1]["igst"] for i in heads}
        if len(rates) <= 1:
            continue
        pk = [i for i in heads if is_packaged(rules[i][1])]
        lo = [i for i in heads if is_loose(rules[i][1])]
        if len(pk) == 1 and len(lo) == 1:
            keep = pk[0] if PACKAGED_POLICY == "taxed" else lo[0]
            fallback[p] = ("head", keep)
            mode = f"packaged-pair->{PACKAGED_POLICY}"
        else:
            fallback[p] = ("fallback", min(rules[i][1]["igst"] for i in heads))
            mode = "fallback"
        conflict_heads[p] = dict(
            rates=sorted({rules[i][1]["igst"] for i in idxs}),
            entries=sorted({rules[i][1]["src"] for i in idxs}), mode=mode)
    for p, idxs in per_head.items():
        if p not in fallback or fallback[p][0] != "fallback":
            continue
        for i in idxs:
            pfx, e, k, s = rules[i]
            if k == "head":
                rules[i] = (pfx, e, "sub", s)
    print(f"headings whose entries disagree on the rate: {len(conflict_heads)}  "
          f"(packaged pairs resolved by policy: "
          f"{sum(1 for v in conflict_heads.values() if v['mode'].startswith('packaged'))})")

    # ---- B: item-level
    for p, e, kind, score in sorted([r for r in rules if r[2] == "item"],
                                    key=lambda x: -len(x[0])):
        for r in rows:
            if r["code"].startswith(p) and not excluded(r["code"], e):
                cand = mk(e, kind, p, score)
                if better(cand, r["assign"]):
                    if r["assign"] and r["assign"]["igst"] != cand["igst"]:
                        r["ambiguous"] = True
                    r["assign"] = cand

    # ---- C: narrow entries placed against child descriptions
    sub_rules = [r for r in rules if r[2] == "sub"]
    placements, unplaced = collections.Counter(), []
    GENERIC_WORD = set("""wood stone plastic paper metal iron steel cotton glass rubber
    article articles material materials product products preparation preparations other
    including part parts sort kinds kind made make used use general""".split())

    for p, e, kind, score in sorted(sub_rules, key=lambda x: -len(x[0])):
        touched = 0
        if len(p) < 4:          # a Chapter-level cell is too broad for description matching
            unplaced.append(e)
            continue
        for ph in phrases(e["desc"]):
            T = toks(ph)
            if len(T) < 2 or T <= GENERIC_WORD:
                continue
            for r in rows:
                if not r["code"].startswith(p) or excluded(r["code"], e):
                    continue
                inter = len(T & r["tokens"])
                ok = inter / len(T) >= 0.75 and inter >= 2
                if ok:
                    cand = mk(e, kind, p, score)
                    if better(cand, r["assign"]):
                        r["assign"] = cand
                    touched += 1
        placements[e["src"]] += touched
        if touched == 0:
            unplaced.append(e)

    # ---- A: head-wide entries fill the remainder
    for p, e, kind, score in sorted([r for r in rules if r[2] == "head"], key=lambda x: -len(x[0])):
        if p in fallback and fallback[p][0] != "head":
            continue
        for r in rows:
            if r["assign"] or not r["code"].startswith(p) or excluded(r["code"], e):
                continue
            r["assign"] = mk(e, kind, p, score)

    # ---- M: split headings - children that matched no sub rule take the lowest rate
    m_rows = 0
    for p, (mode, kept) in fallback.items():
        if mode != "fallback":
            continue
        base = next(r for r in rules if r[0] == p)
        for r in rows:
            if r["assign"] or not r["code"].startswith(p):
                continue
            r["assign"] = dict(ratekind="split-head", tier="M", igst=kept,
                               src=f"split heading {p}: " + "; ".join(conflict_heads[p]["entries"])[:120],
                               cond=False, prefix=p, score=0.0, rkind="fallback")
            r["ambiguous"] = True
            m_rows += 1
    print(f"rows resolved by the split-head fallback: {m_rows}")

    # ---- R: residual
    for r in rows:
        if not r["assign"]:
            r["assign"] = dict(ratekind="residual", tier="R", igst=B.RESIDUAL_IGST,
                               src="9/2025-CT(R) Sch II S.No 639 (residual)", cond=False,
                               prefix="-", score=0.0, rkind="res")

    # ---------------------------------------------------------------- output
    with open("final_mapping.csv", "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["hsn_code", "hsn4", "igst_old", "igst_new", "cgst_new", "sgst_new",
                    "kind", "tier", "matched_prefix", "conditional", "ambiguous",
                    "source_ref", "description"])
        for r in rows:
            a = r["assign"]
            w.writerow([r["code"], r["c4"], r["old"][2], a["igst"], round(a["igst"] / 2, 3),
                        round(a["igst"] / 2, 3), a["ratekind"], a["tier"], a["prefix"],
                        int(a["cond"]), int(r["ambiguous"]), a["src"], r["desc"][:200]])

    with open("review_head_conflicts.csv", "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["heading", "rates_in_play", "resolution", "entries"])
        for p_, v in sorted(conflict_heads.items()):
            w.writerow([p_, "/".join(str(x) for x in v["rates"]), v["mode"], " | ".join(v["entries"])])

    with open("review_unplaced_sub_entries.csv", "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["entry", "cell", "entry_igst", "description"])
        for e in sorted(unplaced, key=lambda x: x["src"]):
            w.writerow([e["src"], e["cell"], e["igst"], e["desc"][:250]])

    tier = collections.Counter(r["assign"]["tier"] for r in rows)
    print("rows by tier:", dict(tier))
    print("rows by tier/kind:")
    for k, v in sorted(collections.Counter((r["assign"]["tier"], r["assign"]["ratekind"]) for r in rows).items()):
        print(f"   {k}: {v}")
    print("new rate distribution:")
    for rate, n in sorted(collections.Counter(r["assign"]["igst"] for r in rows).items()):
        print(f"   IGST {rate:6}% {n:6d}")
    print(f"conditional rows={sum(1 for r in rows if r['assign']['cond'])}  "
          f"ambiguous rows={sum(1 for r in rows if r['ambiguous'])}")
    print(f"sub rules={len(sub_rules)} placed_entries={sum(1 for v in placements.values() if v)} "
          f"unplaced_entries={len(unplaced)}")
    print(f"split-head fallback rows={m_rows}  conflict headings={len(conflict_heads)}")


if __name__ == "__main__":
    main()
