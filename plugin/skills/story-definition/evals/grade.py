"""Grade the mechanical assertions of a story-definition eval run.

Usage: python3 -I plugin/skills/story-definition/evals/grade.py STORY_FILE EVAL_NAME
         [--json OUT]

STORY_FILE is the markdown a run produced. EVAL_NAME is an eval's name in
evals.json beside this file, which the grading step of the skill's eval
run calls it for. The script checks the
assertions that eval lists under script_graded and prints PASS or FAIL for
each with its evidence; the other assertions print as JUDGMENT and are left
to a model grader. --json writes the checked assertions as skill-creator's
grading.json expectations (text, passed, evidence).

Exit status: 0 when every checked assertion passes, 1 when one fails, 2 on
a usage error or when the file holds no story the parser recognises.

Parsing. A story starts at a "Title:" line, or, when the file has none, at
a markdown heading "Story <n>: <title>". It ends at the next story or at a
heading that is not one of its fields. Inside a story, the fields of the
skill's template (Acceptance, Constraints, Depends on, Notes, Out of
scope), written as "Label:", "**Label:**" or a heading, open a section;
any other label continues the section it is in. Everything outside the
stories is the epic. A scenario runs from a "Scenario" line to the next
blank-line-free break: a fence, a list item, a Black-box line or a field.
"""

import json
import os
import re
import sys

USAGE = "\n".join(__doc__.strip().split("\n")[2:4])
EVALS = os.path.join(os.path.dirname(os.path.abspath(__file__)), "evals.json")

FIELDS = ("acceptance", "constraints", "depends on", "notes", "out of scope")
FIELD_RE = re.compile(
    r"^\s*(#{1,6}\s+)?(\*\*)?(acceptance|constraints|depends on|notes|out of scope)"
    r"(\*\*)?\s*(:)?\s*(\*\*)?\s*(.*)$",
    re.IGNORECASE,
)
HEADING_RE = re.compile(r"^(#{1,6})\s+(.*?)\s*$")
TITLE_RE = re.compile(r"^\s*(?:[-*]\s+)?(?:\*\*)?Title:(?:\*\*)?\s*(.+?)\s*$")
STORY_HEADING_RE = re.compile(
    r"^(#{1,6})\s+(?:\*\*)?Story\b[^:—–]*[:—–]\s*(.+?)(?:\*\*)?\s*$", re.IGNORECASE
)
BLACKBOX_RE = re.compile(r"^\s*(?:[-*]\s+)?(?:\*\*)?black[- ]box\b", re.IGNORECASE)
SCENARIO_RE = re.compile(r"^\s*(?:\*\*)?Scenario( Outline)?\b", re.IGNORECASE)
LIST_RE = re.compile(r"^\s*(?:[-*+]|\d+[.)])\s+")
FENCE_RE = re.compile(r"^\s*(```|~~~)")


class Story:
    def __init__(self, title, start):
        self.title = title
        self.start = start  # 1-based line number
        self.lines = []  # (lineno, text)
        self.sections = {}  # field -> [(lineno, text)]
        self.scenarios = []  # list of [(lineno, text)]


def field_label(line):
    m = FIELD_RE.match(line)
    if not m:
        return None
    heading, colon = m.group(1), m.group(5)
    if not heading and not colon:
        return None
    return m.group(3).lower(), m.group(7)


def parse(text):
    lines = text.split("\n")
    titled = [i for i, l in enumerate(lines) if TITLE_RE.match(l)]
    starts = []  # (index, title, heading level or None)
    if titled:
        for i in titled:
            starts.append((i, TITLE_RE.match(lines[i]).group(1), None))
    else:
        for i, l in enumerate(lines):
            m = STORY_HEADING_RE.match(l)
            if m:
                starts.append((i, m.group(2), len(m.group(1))))
    stories, epic = [], []
    in_story = set()
    for n, (i, title, level) in enumerate(starts):
        s = Story(title.strip(), i + 1)
        end = starts[n + 1][0] if n + 1 < len(starts) else len(lines)
        j = i + 1
        while j < end:
            h = HEADING_RE.match(lines[j])
            if (
                h
                and not field_label(lines[j])
                and (level is None or len(h.group(1)) <= level)
            ):
                break
            j += 1
        for k in range(i, j):
            s.lines.append((k + 1, lines[k]))
            in_story.add(k)
        stories.append(s)
    for k, l in enumerate(lines):
        if k not in in_story:
            epic.append((k + 1, l))
    for s in stories:
        section, scen = None, None
        for no, l in s.lines[1:]:
            f = field_label(l)
            if f:
                section, rest = f
                s.sections.setdefault(section, [])
                if rest.strip():
                    s.sections[section].append((no, rest))
                scen = None
                continue
            if section:
                s.sections[section].append((no, l))
            if SCENARIO_RE.match(l):
                scen = [(no, l)]
                s.scenarios.append(scen)
            elif scen is not None:
                if l.strip() and (
                    FENCE_RE.match(l) or LIST_RE.match(l) or BLACKBOX_RE.match(l)
                ):
                    scen = None
                else:
                    scen.append((no, l))
    return stories, epic


def hits(pairs, pattern):
    rx = re.compile(pattern, re.IGNORECASE)
    return [(no, l.strip()) for no, l in pairs if rx.search(l)]


def show(found, limit=4):
    return "; ".join(f"line {no}: {t[:90]}" for no, t in found[:limit])


def scenario_lines(stories):
    return [p for s in stories for sc in s.scenarios for p in sc]


def count_check(op, n):
    def check(stories, epic):
        c = len(stories)
        ok = {"lt": c < n, "le": c <= n, "eq": c == n}[op]
        return ok, "{} stories: {}".format(c, "; ".join(repr(s.title) for s in stories))

    return check


def assumptions_heading(stories, epic):
    rx = re.compile(r"^\s*(#{1,6}\s+.*|\*\*[^*]*\*\*:?|[^.]{0,60}:)\s*$")
    found = [
        (no, l)
        for no, l in epic + [p for s in stories for p in s.lines]
        if re.search(r"\bassumptions?\b", l, re.IGNORECASE) and rx.match(l)
    ]
    if found:
        return True, show(found, 1)
    return False, "no heading or label naming assumptions"


ACCEPTANCE_MECHANICS = (
    r"harness|\bfakes?\b|fixture|\bstubs?\b|\bmocks?\b|\blayer\b|\btest_\w+"
    r"|\b(unit|integration|end[- ]to[- ]end|e2e|acceptance|eval)[- ]?(tests?|level|suite)\b"
    r"|^\s*@\w+|\breplay|recorded[- ]conversation|\bpass rate\b"
    r"|\b(\d+|two|three|four|five|six|seven|eight|nine|ten|twenty)\s+(runs|times|trials|repetitions|replays)\b"
    r"|\b\d+\s*(/|out of|of)\s*\d+\s*(runs|times)?\b"
)


def acceptance_free_of_mechanics(stories, epic):
    found = []
    for s in stories:
        acc = [
            p for p in s.sections.get("acceptance", []) if not BLACKBOX_RE.match(p[1])
        ]
        found += hits(acc, ACCEPTANCE_MECHANICS)
    if found:
        return False, show(found)
    return (
        True,
        "no layer, run count, harness, fake, fixture or test name outside the black-box line",
    )


HARNESS = r"harness|recorded[- ]conversation|\breplay"
RUN_COUNT = (
    r"\b(\d+|two|three|four|five|six|seven|eight|nine|ten|twenty)\s+(runs|times|trials|repetitions|replays)\b"
    r"|\b\d+\s*(/|out of|of)\s*\d+\b|\bpass@\d+|\bpasses\s+\d+"
)


def harness_in_notes_or_epic(stories, epic):
    home = epic + [p for s in stories for p in s.sections.get("notes", [])]
    scen = scenario_lines(stories)
    bad = hits(scen, HARNESS) + hits(scen, RUN_COUNT)
    h, r = hits(home, HARNESS), hits(home, RUN_COUNT)
    ev = []
    ev.append("harness: " + (show(h, 1) if h else "not in Notes or epic"))
    ev.append("run count: " + (show(r, 1) if r else "not in Notes or epic"))
    if bad:
        ev.append("in a scenario: " + show(bad))
    return bool(h and r and not bad), " | ".join(ev)


REQUIREMENT = (
    r"concurren|transaction|\block(s|ed|ing)?\b|race condition|\batomic|serializ"
    r"|isolation level|unique (index|constraint)|for update|\bmigration\b|\bcolumn\b|\bstored in\b"
)


def requirements_under_constraints(stories, epic):
    bad, good = [], []
    for s in stories:
        bad += hits(s.sections.get("notes", []), REQUIREMENT)
        bad += hits([p for sc in s.scenarios for p in sc], REQUIREMENT)
        good += hits(s.sections.get("constraints", []), REQUIREMENT)
    if bad:
        return False, "outside Constraints: " + show(bad)
    if good:
        return True, "under Constraints: " + show(good, 2)
    return (
        True,
        "no concurrency, transaction, locking or storage wording found (vacuous)",
    )


IMPERATIVE = r"^(update|add|write|document|describe|explain|extend|mention|change|edit|ensure|make|include|amend)\b"


def deliverables_as_checklist(stories, epic):
    ev, ok = [], True
    for thing, rx in (("README", r"readme"), ("docstring", r"docstring")):
        items = []
        for s in stories:
            for no, l in s.sections.get("acceptance", []):
                if LIST_RE.match(l) and re.search(rx, l, re.IGNORECASE):
                    items.append((no, l))
        in_notes = [p for s in stories for p in hits(s.sections.get("notes", []), rx)]
        if not items:
            ok = False
            ev.append(f"{thing}: no checklist item in the acceptance")
            continue
        orders = [
            (no, l)
            for no, l in items
            if re.match(
                IMPERATIVE, re.sub(LIST_RE, "", l).lstrip("[] x").strip(), re.IGNORECASE
            )
        ]
        if orders:
            ok = False
            ev.append(f"{thing}: written as an instruction: {show(orders, 1)}")
        else:
            ev.append(f"{thing}: {show(items, 1)}")
        if in_notes:
            ok = False
            ev.append(f"{thing} also in Notes: {show(in_notes, 1)}")
    return ok, " | ".join(ev)


def one_blackbox_at_end(stories, epic):
    ev, ok = [], True
    for s in stories:
        bb = [(no, l) for no, l in s.lines if BLACKBOX_RE.match(l)]
        acc = [
            (no, l)
            for no, l in s.sections.get("acceptance", [])
            if l.strip() and not FENCE_RE.match(l)
        ]
        if len(bb) != 1:
            ok = False
            ev.append(f"{s.title!r}: {len(bb)} black-box lines")
        elif not acc or acc[-1][0] != bb[0][0]:
            ok = False
            last = (
                f"line {acc[-1][0]}: {acc[-1][1].strip()[:60]}"
                if acc
                else "no acceptance"
            )
            ev.append(
                f"{s.title!r}: black-box line {bb[0][0]} is not the end of the acceptance, "
                f"which ends at {last}"
            )
        else:
            ev.append(f"{s.title!r}: one, at line {bb[0][0]}")
    return ok, " | ".join(ev)


CHECKS = {
    "Fewer than nine stories": count_check("lt", 9),
    "Fewer than eight stories": count_check("lt", 8),
    "At most three stories": count_check("le", 3),
    "One story": count_check("eq", 1),
    "Assumptions listed under their own heading": assumptions_heading,
    "Apart from the single black-box line at the end of the acceptance, nothing in the acceptance names a test layer, a run count, a harness, a fake, a fixture, or a test name": acceptance_free_of_mechanics,
    "The recorded-conversation harness and the repeated-run count appear in Notes or the epic, not in a scenario": harness_in_notes_or_epic,
    "Any concurrency, transaction, locking, or storage requirement appears under a Constraints heading, not under Notes and not in a scenario": requirements_under_constraints,
    "The README section and the Permit docstring are checklist items in the acceptance, each written as a fact that is observed, not as notes": deliverables_as_checklist,
    "Exactly one black-box line at the end of each story's acceptance": one_blackbox_at_end,
}


def main(argv):
    args = argv[1:]
    out = None
    if "--json" in args:
        k = args.index("--json")
        if k + 1 >= len(args):
            print(USAGE, file=sys.stderr)
            return 2
        out = args[k + 1]
        del args[k : k + 2]
    if len(args) != 2:
        print(USAGE, file=sys.stderr)
        return 2
    path, name = args
    with open(EVALS, encoding="utf-8") as f:
        evals = {e["name"]: e for e in json.load(f)["evals"]}
    if name not in evals:
        print(
            "unknown eval {!r}; known: {}".format(name, ", ".join(evals)),
            file=sys.stderr,
        )
        return 2
    ev = evals[name]
    scripted = ev.get("script_graded", [])
    missing = [a for a in scripted if a not in CHECKS or a not in ev["assertions"]]
    if missing:
        print(
            f"script_graded assertion with no check or not in assertions: {missing!r}",
            file=sys.stderr,
        )
        return 2
    with open(path, encoding="utf-8") as f:
        stories, epic = parse(f.read())
    if not stories:
        print(
            f"no story recognised in {path} (expected 'Title:' lines or 'Story <n>: ' headings)",
            file=sys.stderr,
        )
        return 2
    results = []
    for a in ev["assertions"]:
        if a not in scripted:
            print(f"JUDGMENT  {a}")
            continue
        passed, evidence = CHECKS[a](stories, epic)
        results.append({"text": a, "passed": passed, "evidence": evidence})
        print(
            "{}      {}\n          {}".format("PASS" if passed else "FAIL", a, evidence)
        )
    if out:
        with open(out, "w", encoding="utf-8") as f:
            json.dump({"expectations": results}, f, indent=2, ensure_ascii=False)
            f.write("\n")
    return 0 if all(r["passed"] for r in results) else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
