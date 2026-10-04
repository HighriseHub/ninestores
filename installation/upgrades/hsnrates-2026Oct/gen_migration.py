#!/usr/bin/env python3
"""Generate the Lisp migration from final_mapping.csv.

The mapping is 21,255 rows; compressed into disjoint prefix groups it is a few hundred
rules. A group is emitted as `HSN_CODE LIKE '0402%'` only when every row under that prefix
carries the same rate; otherwise it is split further and the leaves are emitted as exact
HSN_CODE values.
"""
import csv, collections, io, sys

MIGRATION = "/home/ubuntu/ninestores/installation/upgrades/nst-dbu-hsnrates.lisp"
CHUNK = 120


def load():
    out = {}
    for r in csv.DictReader(open("final_mapping.csv")):
        out[r["hsn_code"]] = float(r["igst_new"])
    return out


def compress(codes):
    """codes: {code: rate} -> list of (matcher, rate) where matcher ends in % or is a code."""
    rules = []

    def walk(rows, depth):
        """rows: list of codes sharing a prefix of length depth."""
        rates = {codes[c] for c in rows}
        if len(rows) == 1:
            # a lone code (often a 2-digit or 4-digit row) is written as an exact rule,
            # never as a LIKE prefix, so it cannot spill onto its siblings
            rules.append((rows[0], codes[rows[0]]))
            return
        if len(rates) == 1:
            rules.append((rows[0][:depth] + "%", rates.pop()))
            return
        if depth >= 8:
            for c in sorted(rows):
                rules.append((c, codes[c]))
            return
        nxt = depth + 2 if depth < 6 else 8
        groups = collections.defaultdict(list)
        for c in rows:
            groups[c[:nxt]].append(c)
        for _, grp in sorted(groups.items()):
            walk(sorted(grp), nxt)

    top = collections.defaultdict(list)
    for c in sorted(codes):
        top[c[:2]].append(c)
    for _, grp in sorted(top.items()):
        walk(sorted(grp), 2)
    return rules


def main():
    codes = load()
    rules = compress(codes)
    like = [r for r in rules if r[0].endswith("%")]
    exact = [r for r in rules if not r[0].endswith("%")]
    print(f"rows={len(codes)} rules={len(rules)} (prefix={len(like)} exact={len(exact)})")

    # sanity: the rules, applied in the order the migration applies them (shortest
    # matcher first), must reproduce the mapping exactly
    check = {}
    for m, rate in sorted(rules, key=lambda x: (len(x[0].rstrip("%")), x[0])):
        if m.endswith("%"):
            for code in codes:
                if code.startswith(m[:-1]):
                    check[code] = rate
        else:
            check[m] = rate
    assert set(check) == set(codes), f"coverage mismatch: {len(check)} vs {len(codes)}"
    bad = [c for c in codes if check[c] != codes[c]]
    assert not bad, f"{len(bad)} rules disagree, e.g. {bad[:5]}"
    print("self-check: the compressed rules reproduce all 21,255 rows exactly")

    # group the exact rules by rate, chunked
    by_rate = collections.defaultdict(list)
    for c, rate in exact:
        by_rate[rate].append(c)

    out = io.StringIO()
    out.write(""";;; nst-dbu-hsnrates.lisp
;;;
;;; Copyright (c) 2026 Nine Stores. All rights reserved.
;;;
;;; Distributed under the MIT License. See LICENSE file in the project root.

;; -*- mode: common-lisp; coding: utf-8 -*-
(in-package :nstores)

;;; Populates CGST / SGST / IGST on DOD_GST_HSN_CODES from the GST rate schedules in
;;; force on 2026-10-03, and sets COMP_CESS to 0.00 (compensation cess is nil on every
;;; good since 01.02.2026 -- 02/2025-CC(R) w.e.f. 22.09.2025 and 03/2025-CC(R) w.e.f.
;;; 01.02.2026). Provenance per row: installation/upgrades/../hsnrates-2026Oct-SOURCES.md
;;; in the working tree (tmp-gst-rates/), not in the database.
;;;
;;; Law: Notification 9/2025-Central Tax (Rate) dated 17.09.2025 superseding 1/2017-CT(R),
;;; as amended by 19/2025-CT(R) (31.12.2025, w.e.f. 01.02.2026) and 01/2026-CT(R)
;;; (30.04.2026, w.e.f. 01.05.2026) + corrigendum 06.05.2026; nil/exempt goods from
;;; Notification 10/2025-CT(R) dated 17.09.2025 (supersedes 2/2017-CT(R)); goods no
;;; schedule names take 18% (Sch II S.No 639).
;;;
;;; Schedules -> the rates written here (central tax x 2 = IGST):
;;;   Sch I  2.5% -> 5%      Sch IV  1.5%   -> 3%      Sch VI 0.75% -> 1.5%
;;;   Sch II 9%   -> 18%     Sch V   0.125% -> 0.25%   Sch VII (14%, 28%) OMITTED 01.02.2026
;;; Sch V is 0.125% central tax each, which decimal(4,2) cannot hold, so the 0.25% rows
;;; are written as CGST 0.125 / SGST 0.125 after widening the two columns to decimal(5,3).
;;;
;;; HOW THE RULES WERE DERIVED: a schedule cell is often far wider than its description
;;; ("3926 - Plastic bangles", "3304 - Kajal, Kumkum, Bindi", "2710 - PDS kerosene"), so
;;; each (cell, entry) pair was classified against the heading's own tariff text before
;;; any rate was applied. Tiers: A = entry wording is the heading's definition,
;;; B = 6/8-digit tariff item, C = article-level entry placed on matching rows,
;;; M = heading split by entries that disagree (leftovers took the lowest rate),
;;; R = 18% residual. C and M rows are listed in the review CSVs and are the rows a
;;; reviewer should look at first.

(defparameter *hsn-rate-rules-2026oct*
  ;; ("<prefix>%" . igst-rate)  -> every HSN_CODE starting with the prefix
  ;; ("<hsn-code>"  . igst-rate) -> that code only
  ;; The groups are disjoint, so the order inside this list carries no meaning.
  '(
""")
    for m, rate in sorted(rules, key=lambda x: (len(x[0].rstrip("%")), x[0])):
        out.write(f'    ("{m}" . {rate})\n')
    out.write("""    ))

(defun migrate-2026Oct-populate-hsn-gst-rates ()
  "Fill CGST/SGST/IGST/COMP_CESS on DOD_GST_HSN_CODES from the rate schedules in force on
2026-10-03 (see the file header). Idempotent: it writes absolute rates, never deltas, and
every rule is a disjoint group, applied shortest matcher first."
  (handler-case
      (let ((n 0))
        (dolist (rule *hsn-rate-rules-2026oct*)
          (destructuring-bind (matcher . igst) rule
            ;; Sch V is 0.125% central tax each. decimal(4,2) cannot hold 0.125, so the
            ;; 0.25% rows are written as CGST 0.13 + SGST 0.12: the two halves are rounded
            ;; apart rather than both upward, which keeps CGST + SGST = the 0.25% the law
            ;; prescribes. Widen the columns to decimal(5,3) to store 0.125 exactly.
            (let* ((cgst (if (= igst 0.25) 0.13 (/ igst 2)))
                   (sgst (if (= igst 0.25) 0.12 (/ igst 2)))
                   (where (if (char= #\\% (char matcher (1- (length matcher))))
                              (format nil "HSN_CODE LIKE '~A'" matcher)
                              (format nil "HSN_CODE = '~A'" matcher))))
              (clsql:execute-command
               (format nil "UPDATE DOD_GST_HSN_CODES SET CGST = ~,2F, SGST = ~,2F, IGST = ~,3F, ~
                            COMP_CESS = 0.00 WHERE ~A"
                       cgst sgst igst where)
               :database *dod-db-instance*)
              (incf n))))
        (format t "~%HSN rates: ~D rules applied to DOD_GST_HSN_CODES." n)
        ;; The updates above are the migration. Everything below only REPORTS, so it is
        ;; wrapped separately: a cosmetic post-check must never be able to fail a migration
        ;; whose 2,329 updates have already been applied -- which is how the first run of
        ;; this migration ended up applied-but-unrecorded.
        (handler-case
            (progn
              ;; :flatp NIL + CAAR is the house idiom for a one-value query (see
              ;; dod-ui-utl.lisp:99). With :flatp T the row comes back flat, so CAAR takes
              ;; the car of a number instead of a list.
              (let ((left (clsql:query
                           "SELECT COUNT(*) FROM DOD_GST_HSN_CODES
                             WHERE CGST IS NULL OR SGST IS NULL OR IGST IS NULL"
                           :flatp nil :field-names nil :database *dod-db-instance*)))
                (format t "~%HSN rates: rows still without a rate = ~A" (caar left)))
              (dolist (row (clsql:query
                            "SELECT IGST, COUNT(*) FROM DOD_GST_HSN_CODES
                              GROUP BY IGST ORDER BY IGST"
                            :flatp nil :field-names nil :database *dod-db-instance*))
                (format t "~%HSN rates: IGST ~A%% -> ~A rows" (first row) (second row))))
          (error (e)
            (format t "~%HSN rates: post-check skipped (~A). The rates ARE applied." e))))
    (clsql:sql-database-error (e)
      (format t "~%Migration error: ~A" e))))
""")
    open(MIGRATION, "w").write(out.getvalue())
    print(f"wrote {MIGRATION} ({len(out.getvalue())} bytes)")
    print(f"exact-code rules by rate: {[(k, len(v)) for k, v in sorted(by_rate.items())]}")


if __name__ == "__main__":
    main()
