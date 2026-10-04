#!/usr/bin/env python3
"""Read-only verification of the generated migration against the live table.

For every rule in the migration file it asks MySQL which HSN_CODEs that rule's WHERE
clause actually matches (LIKE / = against the real table, real collation), applies the
rules in file order, and diffs the result against final_mapping.csv. Nothing is written.
"""
import csv, re, subprocess, sys

LISP = "/home/ubuntu/ninestores/installation/upgrades/nst-dbu-hsnrates.lisp"
DB = ["mysql", "-u", "hhubuser", "-pWelcome$123", "-N", "-B", "hhubdb"]


def rules_from_lisp():
    src = open(LISP).read()
    body = src.split("*hsn-rate-rules-2026oct*", 1)[1].split("'(", 1)[1].split("\n    ))", 1)[0]
    return [(m, float(r)) for m, r in re.findall(r'\("([^"]+)"\s*\.\s*([\d.]+)\)', body)]


def main():
    rules = rules_from_lisp()
    print(f"rules in the migration: {len(rules)}")
    sql = ["SET SESSION group_concat_max_len = 4000000;"]
    for i, (m, _) in enumerate(rules):
        where = f"HSN_CODE LIKE '{m}'" if m.endswith("%") else f"HSN_CODE = '{m}'"
        sql.append(f"SELECT {i}, GROUP_CONCAT(HSN_CODE) FROM DOD_GST_HSN_CODES WHERE {where};")
    r = subprocess.run(DB, input="\n".join(sql), capture_output=True, text=True)
    if r.returncode != 0:
        print(r.stderr[-1500:])
        sys.exit(1)

    hit = {}
    for line in r.stdout.split("\n"):
        p = line.split("\t")
        if len(p) == 2 and p[1]:
            hit[int(p[0])] = p[1].split(",")
    print(f"rules that matched at least one row: {len(hit)} / {len(rules)}")

    table = {}
    for i, (m, rate) in enumerate(rules):          # file order = the order the Lisp applies
        for code in hit.get(i, []):
            table[code] = rate

    want = {row["hsn_code"]: float(row["igst_new"])
            for row in csv.DictReader(open("final_mapping.csv"))}
    print(f"rows matched by the rules in the live table: {len(table)}  expected: {len(want)}")
    missing = sorted(set(want) - set(table))
    extra = sorted(set(table) - set(want))
    diff = {c: (want[c], table[c]) for c in set(want) & set(table) if abs(want[c] - table[c]) > 1e-9}
    print(f"not covered by any rule: {len(missing)}   covered but unexpected: {len(extra)}"
          f"   rate mismatches: {len(diff)}")
    for c in missing[:5]:
        print("   uncovered", c)
    for c in extra[:5]:
        print("   extra", c)
    for c, v in list(diff.items())[:8]:
        print("   mismatch", c, "expected", v[0], "got", v[1])
    print("RESULT:", "PASS" if not missing and not extra and not diff else "FAIL")


if __name__ == "__main__":
    main()
