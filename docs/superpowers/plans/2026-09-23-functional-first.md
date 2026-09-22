# Functional-First Plugin Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the `functional-first` plugin — an always-on CLAUDE.md snippet carrying six structural principles, plus a skill supplying per-language idiom, stance resolution, and review signals.

**Architecture:** The snippet is the guarantee layer: it carries Axis A in full so the principles hold even when the skill never loads. The skill supplies depth on demand. Ecosystem facts live in one JSON file rather than scattered through prose, so the "refresh before asking" mechanism has a concrete target and the fact/stance boundary can be enforced by a test.

**Tech Stack:** Markdown, JSON, Python 3 standard library only (`unittest`, `json`, `pathlib`). No third-party dependencies.

**Spec:** `docs/superpowers/specs/2026-09-23-functional-first-design.md`

## Global Constraints

- All shipped artifacts are written in **English**. Only conversation with the user is in Traditional Chinese.
- Plugin name `functional-first`; skill name `functional-first`; invocation `functional-first:functional-first`. The local repo directory stays `functimize` and is published nowhere.
- Axis A is exactly **six principles**, applied at full rigor in every language, never discounted for language capability.
- The deviation whitelist is exactly **three items**: measured hot path, framework grain, existing-codebase consistency. The third is brownfield-only and protects only Contagious Changes.
- Brownfield scope is **new files plus modified functions**. The word "module" must not appear as a scope boundary.
- Option sets: Java `{ native }`, Python `{ native }`, Scala 3 `{ ZIO 2, cats-effect 3, direct style }`, Scala 2 `{ ZIO 2, cats-effect 3, direct style }`.
- Ask rule: **set size > 1 → ask; size = 1 → proceed.** No High/Medium/Low level anywhere.
- Review signal 4 fires **only** over a sealed hierarchy at Effective Language Level 21+.
- Java tiers are **8/11**, **16/17**, **21+**. Detection reads the build target plus source evidence, never the runtime.
- Python: a strict type checker (mypy or pyright, strict, with `assert_never`) is a **precondition** for principle 4.
- `references/*.md` carry capability and idiom only. Naming a preferred library anywhere in a reference is a defect.
- Reference order: `scala-3.md` → `java.md` → `python.md`.
- Vocabulary is fixed by `CONTEXT.md`: Axis A, Axis B, Deviation, Substitution, Effective Language Level, Stance, Taste Fork, Contagious Change, Failure Signal.

Run all tests with:

```bash
python3 -m unittest discover -s tests -t . -v
```

---

### Task 1: Plugin skeleton and manifest

**Files:**
- Create: `.claude-plugin/plugin.json`
- Create: `tests/test_plugin.py`

**Interfaces:**
- Consumes: nothing
- Produces: `ROOT` resolution pattern `pathlib.Path(__file__).resolve().parent.parent` reused by every later test module; plugin directory `skills/functional-first/`

- [ ] **Step 1: Write the failing test**

Create `tests/test_plugin.py`:

```python
import json
import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parent.parent
MANIFEST = ROOT / ".claude-plugin" / "plugin.json"
SKILL_DIR = ROOT / "skills" / "functional-first"


class TestPluginManifest(unittest.TestCase):
    def test_manifest_exists(self):
        self.assertTrue(MANIFEST.is_file(), f"missing manifest at {MANIFEST}")

    def test_manifest_is_valid_json_naming_the_plugin(self):
        data = json.loads(MANIFEST.read_text(encoding="utf-8"))
        self.assertEqual(data["name"], "functional-first")
        self.assertTrue(data["description"].strip(), "description must not be empty")

    def test_skill_directory_exists(self):
        self.assertTrue(SKILL_DIR.is_dir(), f"missing skill dir at {SKILL_DIR}")


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `python3 -m unittest discover -s tests -t . -v`
Expected: FAIL — three failures, the first reading `missing manifest at .../.claude-plugin/plugin.json`

- [ ] **Step 3: Create the manifest and skill directory**

```bash
mkdir -p .claude-plugin skills/functional-first/references skills/functional-first/snippets
```

Create `.claude-plugin/plugin.json`:

```json
{
  "name": "functional-first",
  "description": "A cross-language guideline that biases architecture, planning, implementation, and library selection toward functional design.",
  "version": "0.1.0"
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `python3 -m unittest discover -s tests -t . -v`
Expected: PASS — 3 tests

- [ ] **Step 5: Commit**

```bash
git add .claude-plugin/plugin.json tests/test_plugin.py
git commit -m "feat: add functional-first plugin manifest and skeleton"
```

---

### Task 2: The CLAUDE.md snippet — Layer 1

**Files:**
- Create: `skills/functional-first/snippets/claude-md.md`
- Create: `tests/test_snippet.py`

**Interfaces:**
- Consumes: `skills/functional-first/` from Task 1
- Produces: the snippet file; the constant `MAX_CONTENT_LINES = 20` guarding its size

This is the only layer that fires unconditionally, so it carries all six principles in full rather than pointing at them. The size test exists because the spec records the risk that this block "degrades quietly if ever expanded" — the budget makes that failure loud.

- [ ] **Step 1: Write the failing test**

Create `tests/test_snippet.py`:

```python
import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parent.parent
SNIPPET = ROOT / "skills" / "functional-first" / "snippets" / "claude-md.md"
MAX_CONTENT_LINES = 20

PRINCIPLE_MARKERS = [
    "at the edges",
    "shell performs",
    "immutable",
    "unrepresentable",
    "return value",
    "passed in",
]


class TestClaudeMdSnippet(unittest.TestCase):
    def setUp(self):
        self.assertTrue(SNIPPET.is_file(), f"missing snippet at {SNIPPET}")
        self.text = SNIPPET.read_text(encoding="utf-8")

    def test_stays_within_the_context_budget(self):
        lines = [line for line in self.text.splitlines() if line.strip()]
        self.assertLessEqual(
            len(lines),
            MAX_CONTENT_LINES,
            f"snippet is {len(lines)} non-blank lines, budget is {MAX_CONTENT_LINES}; "
            "this block loads in every session, so growth must be deliberate",
        )

    def test_carries_all_six_principles(self):
        lowered = self.text.lower()
        missing = [m for m in PRINCIPLE_MARKERS if m not in lowered]
        self.assertEqual(missing, [], f"principles missing from snippet: {missing}")

    def test_requires_deviations_to_be_spoken(self):
        self.assertIn("silently", self.text.lower())

    def test_points_at_the_skill_by_its_invocation_name(self):
        self.assertIn("functional-first:functional-first", self.text)


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `python3 -m unittest discover -s tests -t . -v`
Expected: FAIL — `missing snippet at .../snippets/claude-md.md`

- [ ] **Step 3: Write the snippet**

Create `skills/functional-first/snippets/claude-md.md`:

```markdown
## Functional-first

Default to functional structure, in every language:

- I/O, database, clock, and network at the edges; decision logic pure
- The core returns a description of what should happen; the shell performs it
- Data is immutable; transformations return new values
- Illegal states unrepresentable; legal states handled exhaustively
- Expected failure is a return value, not an exception
- Dependencies — including clock, randomness, and IDs — are passed in

Deviating is allowed. Deviating silently is not: name the principle and the reason.

Designing, planning, choosing a library, or reviewing → load
`functional-first:functional-first` for per-language idiom and stance.
Applies whenever brainstorming or writing-plans runs.
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `python3 -m unittest discover -s tests -t . -v`
Expected: PASS — 7 tests

- [ ] **Step 5: Commit**

```bash
git add skills/functional-first/snippets/claude-md.md tests/test_snippet.py
git commit -m "feat: add always-on CLAUDE.md snippet carrying Axis A"
```

---

### Task 3: Ecosystem data and its invariants

**Files:**
- Create: `skills/functional-first/references/ecosystem.json`
- Create: `tests/test_ecosystem.py`

**Interfaces:**
- Consumes: `skills/functional-first/references/` from Task 1
- Produces: `ecosystem.json` with shape `{"languages": {<lang>: {"options": [str], "asks": bool, "last_verified": "YYYY-MM", "reference": "<file>.md", "notes": str}}, "build_markers": [str]}`. Task 4 cites this file by path; Tasks 6–8 add entries' reference files.

Putting option sets in data rather than prose gives the §4.3.1 refresh a concrete target and lets the ask rule be enforced as an invariant instead of restated as prose.

- [ ] **Step 1: Write the failing test**

Create `tests/test_ecosystem.py`:

```python
import datetime
import json
import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parent.parent
ECOSYSTEM = ROOT / "skills" / "functional-first" / "references" / "ecosystem.json"


class TestEcosystemData(unittest.TestCase):
    def setUp(self):
        self.assertTrue(ECOSYSTEM.is_file(), f"missing {ECOSYSTEM}")
        self.data = json.loads(ECOSYSTEM.read_text(encoding="utf-8"))
        self.languages = self.data["languages"]

    def test_no_option_set_is_empty(self):
        for lang, entry in self.languages.items():
            self.assertTrue(entry["options"], f"{lang} has an empty option set")

    def test_ask_flag_equals_set_size_greater_than_one(self):
        for lang, entry in self.languages.items():
            expected = len(entry["options"]) > 1
            self.assertEqual(
                entry["asks"],
                expected,
                f"{lang}: asks={entry['asks']} but option set has "
                f"{len(entry['options'])} members",
            )

    def test_every_entry_carries_a_parseable_verification_date(self):
        for lang, entry in self.languages.items():
            datetime.datetime.strptime(entry["last_verified"], "%Y-%m")

    def test_single_option_languages_offer_native(self):
        for lang, entry in self.languages.items():
            if len(entry["options"]) == 1:
                self.assertEqual(entry["options"], ["native"], f"{lang}")

    def test_scala_2_and_3_carry_the_same_members(self):
        self.assertEqual(
            sorted(self.languages["scala-3"]["options"]),
            sorted(self.languages["scala-2"]["options"]),
        )

    def test_build_markers_are_lowercase_and_unique(self):
        markers = self.data["build_markers"]
        self.assertEqual(markers, [m.lower() for m in markers])
        self.assertEqual(len(markers), len(set(markers)))


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `python3 -m unittest discover -s tests -t . -v`
Expected: FAIL — `missing .../references/ecosystem.json`

- [ ] **Step 3: Write the data file**

Create `skills/functional-first/references/ecosystem.json`:

```json
{
  "refresh_policy": "Re-verify a language's options by live search immediately before asking the user. The shipped set is a floor: a refresh may add an option or mark one as declining, but may never produce an empty menu or admit an option that fails Axis A.",
  "build_markers": [
    "zio",
    "cats-effect",
    "arrow-kt",
    "vavr",
    "returns",
    "effect",
    "fp-ts",
    "neverthrow"
  ],
  "languages": {
    "scala-3": {
      "options": ["ZIO 2", "cats-effect 3", "direct style"],
      "asks": true,
      "last_verified": "2026-09",
      "reference": "scala-3.md",
      "notes": "Direct style on Scala 3 has tooling (Ox, gears) that Scala 2 lacks."
    },
    "scala-2": {
      "options": ["ZIO 2", "cats-effect 3", "direct style"],
      "asks": true,
      "last_verified": "2026-09",
      "reference": "scala-2.md",
      "notes": "Both libraries cross-publish to 2.12 and 2.13. Direct style here means plain code plus discipline, since Ox requires Scala 3."
    },
    "java": {
      "options": ["native"],
      "asks": false,
      "last_verified": "2026-09",
      "reference": "java.md",
      "notes": "Axis A is reached with record, sealed, and switch patterns at 21+, or the visitor pattern at 8/11."
    },
    "python": {
      "options": ["native"],
      "asks": false,
      "last_verified": "2026-09",
      "reference": "python.md",
      "notes": "A hand-written Result of roughly twenty lines reads better than a dependency."
    }
  }
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `python3 -m unittest discover -s tests -t . -v`
Expected: PASS — 13 tests

- [ ] **Step 5: Commit**

```bash
git add skills/functional-first/references/ecosystem.json tests/test_ecosystem.py
git commit -m "feat: add ecosystem option sets with ask-rule invariants"
```

---

### Task 4: SKILL.md — contract, gate, stance, deviation

**Files:**
- Create: `skills/functional-first/SKILL.md`
- Create: `tests/test_skill_md.py`

**Interfaces:**
- Consumes: `ecosystem.json` from Task 3 (cited by relative path); the six principles from Task 2
- Produces: `SKILL.md` with frontmatter `name: functional-first` and a situational `description`; section headings `## The contract`, `## Step 1 — Classify the project`, `## Step 2 — Resolve the stance`, `## Deviation`, `## Language references`

The description is Layer 3 and must name what the user is doing, never what the guideline believes — a description phrased around "functional architecture" matches only users who already said the word.

- [ ] **Step 1: Write the failing test**

Create `tests/test_skill_md.py`:

```python
import pathlib
import re
import unittest

ROOT = pathlib.Path(__file__).resolve().parent.parent
SKILL = ROOT / "skills" / "functional-first" / "SKILL.md"

SITUATIONS = [
    "designing",
    "implementation plan",
    "choosing a library",
    "implementing",
    "reviewing",
]

REQUIRED_HEADINGS = [
    "## The contract",
    "## Step 1 — Classify the project",
    "## Step 2 — Resolve the stance",
    "## Deviation",
    "## Language references",
]


class TestSkillMd(unittest.TestCase):
    def setUp(self):
        self.assertTrue(SKILL.is_file(), f"missing {SKILL}")
        self.text = SKILL.read_text(encoding="utf-8")

    def test_frontmatter_names_the_skill(self):
        match = re.match(r"^---\n(.*?)\n---\n", self.text, re.DOTALL)
        self.assertIsNotNone(match, "SKILL.md must open with YAML frontmatter")
        self.assertIn("name: functional-first", match.group(1))

    def test_description_names_situations_not_philosophy(self):
        match = re.search(r"^description:(.*?)(?=\n[a-z_]+:|\n---)", self.text,
                          re.DOTALL | re.MULTILINE)
        self.assertIsNotNone(match, "frontmatter must carry a description")
        description = match.group(1).lower()
        missing = [s for s in SITUATIONS if s not in description]
        self.assertEqual(missing, [], f"description omits situations: {missing}")

    def test_has_the_required_structure(self):
        missing = [h for h in REQUIRED_HEADINGS if h not in self.text]
        self.assertEqual(missing, [], f"missing headings: {missing}")

    def test_states_the_removal_clause(self):
        self.assertIn("remove the skill", self.text.lower())

    def test_scope_is_the_changeset_not_a_module(self):
        # The frontmatter description legitimately says "module" as a situation
        # word ("designing a service, module, or API"). The ban applies to the
        # body, where "module" must never appear as a scope boundary.
        body = self.text.split("\n---\n", 2)[-1]
        self.assertIn("modified function", body.lower())
        self.assertNotIn("module", body.lower())

    def test_deviation_whitelist_has_exactly_three_items(self):
        section = self.text.split("## Deviation", 1)[1].split("\n## ", 1)[0]
        bullets = [ln for ln in section.splitlines() if ln.strip().startswith("1.")
                   or ln.strip().startswith("2.") or ln.strip().startswith("3.")]
        self.assertEqual(len(bullets), 3, "the whitelist is exactly three items")
        self.assertNotIn("4.", section)

    def test_cites_the_ecosystem_data_file(self):
        self.assertIn("references/ecosystem.json", self.text)


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `python3 -m unittest discover -s tests -t . -v`
Expected: FAIL — `missing .../skills/functional-first/SKILL.md`

- [ ] **Step 3: Write SKILL.md**

Create `skills/functional-first/SKILL.md`:

````markdown
---
name: functional-first
description: Use when designing a service, module, or API; when writing an implementation plan; when choosing a library or framework; when implementing backend logic; or when reviewing code — applies functional structure in any language, resolves which effect machinery a project uses, and supplies per-language idiom.
---

# Functional-First

## The contract

Adopting this skill means accepting Axis A. Only Axis B is negotiable, and only among options
that already satisfy Axis A. A team that does not want functional design should remove the
skill rather than configure it away.

**Axis A — principle rigor.** Applied at full rigor in every language. Never discounted for
language capability: where a language lacks a construct, use the Substitution given in its
reference. Rigor does not change, only form.

1. I/O, database, clock, and network at the edges; decision logic pure.
2. The core returns a description of what should happen; the shell performs it.
3. Data is immutable; transformations return new values. Mutation is confined inside one
   function, leaving it pure from the outside.
4. Illegal states unrepresentable; legal states handled exhaustively. Parse, don't validate —
   the boundary parses once into a validated type and nothing downstream re-checks it.
5. Expected failure is a return value. Exceptions are for genuine bugs and unrecoverable
   conditions.
6. Dependencies are passed in — including clock, randomness, ID generation, and environment.
   No ambient singletons, no global mutable state, no container magic.

**Axis B — abstraction weight.** Which machinery carries the effects. Resolved per project by
Step 2, never assumed.

## Step 1 — Classify the project

Read whether existing source code is present. That is the whole test — never infer it from the
language version, because new projects adopt old versions for real reasons and old projects
run on new runtimes.

**Greenfield** (no existing source): Axis A applies to everything. Framework grain is a
selection criterion — choosing an ORM that demands mutable entities signs up for that tax, so
weigh grain when picking frameworks rather than pleading it afterwards.

**Brownfield** (existing source): Axis A binds every new file and every modified function.
Code merely read or called carries no obligation. Never a global rewrite.

## Step 2 — Resolve the stance

```
brownfield with a build-file signal  → follow what is there. Never ask.
project records a Stance in CLAUDE.md → use it. Never re-ask.
otherwise                             → refresh, ask once, record
```

A signal is a build file (`build.sbt`, `pom.xml`, `build.gradle`, `pyproject.toml`) naming one
of the `build_markers` in `references/ecosystem.json`, or those types appearing broadly in
source. The marker list is a fast path, not a closed set: an unrecognised dependency that
looks like effect or FP machinery falls through to asking, never to `native`.

Option sets live in `references/ecosystem.json`. The rule is one line: **set size > 1 → ask;
size = 1 → proceed.** Before asking, re-verify that language's options by live search — the
shipped set is a floor, and a refresh may add an option or mark one as declining, but may
never produce an empty menu or admit an option failing Axis A.

`native` is a definite architecture, not an absence: an ordinary shell calling the database, a
pure core over records or frozen dataclasses, and failure travelling in a hand-written
`Result` or the language's own sum type.

**Ask about machinery, never about whether to be functional.** Every option on the menu
already satisfies Axis A. Present trade-offs rather than names, and ask at design time, never
mid-implementation.

Record the answer in the project's `CLAUDE.md`:

```markdown
## functional-first
- Axis B: cats-effect 3
- Decided: 2026-09-23 — team already ships cats/http4s services
```

The reason line decides whether the next person revisiting this is deciding or guessing.

## Deviation

Applying a principle below full rigor. Allowed only against this list, and never silently —
name the principle and the reason.

1. **Measured hot path.** Profiling data exists and the mutation is confined inside the
   function. Both halves are required.
2. **Framework grain.** The ORM demands mutable entities. Brownfield only as a plea; in
   greenfield it was a choice. Keep framework types out of the core rather than fighting the
   framework.
3. **Existing-codebase consistency.** Brownfield only, and it protects only Contagious
   Changes — those forcing others to learn something or modify code they own. Adopting an
   effect library is contagious. Adding a `record` or a `sealed interface` is not, so any
   native construct the build target supports is used regardless of surrounding style.

**Substitution is not Deviation.** "This language has no sum type" is not a licence to relax;
the reference gives the substitute form and rigor is unchanged.

## Language references

Load the one matching the language being implemented. They carry capability and idiom only —
what the language and its ecosystem can do, and what idiomatic code looks like. Stance lives
here in `SKILL.md`, never in a reference.

| Language | Reference |
|---|---|
| Scala 3 | `references/scala-3.md` |
| Scala 2 | `references/scala-2.md` |
| Java | `references/java.md` |
| Python | `references/python.md` |

For review, load `references/review-signals.md`.
````

- [ ] **Step 4: Run the test to verify it passes**

Run: `python3 -m unittest discover -s tests -t . -v`
Expected: PASS — 20 tests

- [ ] **Step 5: Commit**

```bash
git add skills/functional-first/SKILL.md tests/test_skill_md.py
git commit -m "feat: add SKILL.md with contract, gate, stance resolution, deviation"
```

---

### Task 5: Review signals reference

**Files:**
- Create: `skills/functional-first/references/review-signals.md`
- Modify: `tests/test_references.py` (created here, extended by Tasks 6–8)

**Interfaces:**
- Consumes: the six principles from Task 4's `SKILL.md`
- Produces: `tests/test_references.py` with `REFERENCE_DIR`, `BANNED_STANCE_PHRASES`, and `iter_reference_files()`, all reused by Tasks 6–8

The stance ban is enforced mechanically here because the spec records that the fact/stance line "is not self-enforcing" — a future edit adding "prefer X" to a reference would otherwise look harmless.

- [ ] **Step 1: Write the failing test**

Create `tests/test_references.py`:

```python
import json
import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parent.parent
REFERENCE_DIR = ROOT / "skills" / "functional-first" / "references"
ECOSYSTEM = REFERENCE_DIR / "ecosystem.json"

BANNED_STANCE_PHRASES = [
    "we recommend",
    "you should use",
    "the best choice",
    "prefer zio",
    "prefer cats",
    "is the right choice",
]


def iter_reference_files():
    return sorted(p for p in REFERENCE_DIR.glob("*.md"))


class TestReferenceHygiene(unittest.TestCase):
    def test_no_reference_states_a_stance(self):
        offenders = []
        for path in iter_reference_files():
            lowered = path.read_text(encoding="utf-8").lower()
            offenders += [
                f"{path.name}: {phrase}"
                for phrase in BANNED_STANCE_PHRASES
                if phrase in lowered
            ]
        self.assertEqual(offenders, [], f"stance language in references: {offenders}")

    def test_every_reference_marks_minimum_versions(self):
        for path in iter_reference_files():
            if path.name == "review-signals.md":
                continue
            self.assertIn("since:", path.read_text(encoding="utf-8"),
                          f"{path.name} carries no version markers")


class TestReviewSignals(unittest.TestCase):
    def setUp(self):
        self.path = REFERENCE_DIR / "review-signals.md"
        self.assertTrue(self.path.is_file(), f"missing {self.path}")
        self.text = self.path.read_text(encoding="utf-8")

    def test_has_one_signal_per_principle(self):
        for n in range(1, 7):
            self.assertIn(f"### Signal {n}", self.text)

    def test_signal_four_is_scoped_to_sealed_and_21(self):
        section = self.text.split("### Signal 4", 1)[1].split("### Signal 5", 1)[0]
        lowered = section.lower()
        self.assertIn("sealed", lowered)
        self.assertIn("21", section)
        self.assertIn("non-sealed", lowered)


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `python3 -m unittest discover -s tests -t . -v`
Expected: FAIL — `missing .../references/review-signals.md`

- [ ] **Step 3: Write the reference**

Create `skills/functional-first/references/review-signals.md`:

````markdown
# Review Signals

Review runs on observable markers, not on judgement questions. "Is this function pure enough"
cannot be checked; "a `Repository` type appears in a decision function's parameters" can be
grepped.

A signal is a prompt, not a verdict. Signals over-fire and under-fire by nature — read the
code before concluding.

### Signal 1 — Core/shell

A module holding decision logic imports a database, HTTP, or time package.

```java
// trips the signal — the decision and the fetch are in one place
BigDecimal total(OrderId id) { return repo.load(id).lines()...; }

// clean — the caller loads, this decides
BigDecimal total(List<Line> lines) { ... }
```

### Signal 2 — Decide/execute

A function both computes and writes, or returns `void`/`Unit` while carrying meaning.

### Signal 3 — Immutability

A parameter mutated in place, a setter, or a shared mutable collection escaping a function.

### Signal 4 — Types

The same validation repeating across layers.

Also: on Java **21+**, a `default` branch in a `switch` over a **sealed** hierarchy — it
discards the exhaustiveness check that sealing exists to provide.

The scope matters, because the same construct is correct in two of the three places it
appears:

| Effective Language Level | Selector | `default` branch |
|---|---|---|
| 21+ | sealed | **violation** — defeats exhaustiveness |
| 16 / 17 | sealed | correct — the prescribed idiom, matching is an `instanceof` chain |
| any | non-sealed | correct — ordinary code |

### Signal 5 — Errors

Expected failure raised as an exception and caught as control flow; or a swallowed `catch`.

### Signal 6 — Dependencies

`Instant.now()`, `UUID.randomUUID()`, `new XxxClient()`, `datetime.now()`, or a global
singleton referenced inside a function body rather than passed in.
````

- [ ] **Step 4: Run the test to verify it passes**

Run: `python3 -m unittest discover -s tests -t . -v`
Expected: PASS — 24 tests

- [ ] **Step 5: Commit**

```bash
git add skills/functional-first/references/review-signals.md tests/test_references.py
git commit -m "feat: add review signals reference with stance-hygiene tests"
```

---

### Task 6: Scala 3 reference

**Files:**
- Create: `skills/functional-first/references/scala-3.md`
- Modify: `tests/test_references.py` (append `TestScala3`)

**Interfaces:**
- Consumes: `REFERENCE_DIR` and `ECOSYSTEM` from Task 5's `tests/test_references.py`; the option set for `scala-3` from Task 3's `ecosystem.json`. The hygiene tests from Task 5 begin covering this file automatically once it exists.
- Produces: a reference documenting all three options' idiom, consumed by no later task

This reference documents ZIO, cats-effect, and direct style **even-handedly** — describing how each is written is a fact; saying which to pick is stance and belongs in `SKILL.md`.

- [ ] **Step 1: Verify the ecosystem facts before writing them**

The spec records that ecosystem claims are the fastest-moving content in this project and were recalled rather than verified. Before writing, search for the current state of: ZIO 2's latest line and Scala 3 support; cats-effect 3's latest line; whether Ox is still the active direct-style library for Scala 3; and whether Scala 3 `enum` exhaustiveness checking in `match` has changed.

Record what you find in the file's `last-verified` line, and if any finding contradicts `ecosystem.json`, update that file and re-run its tests before continuing.

- [ ] **Step 2: Write the failing test**

Append to `tests/test_references.py`, before the `if __name__` block:

```python
class TestScala3(unittest.TestCase):
    def setUp(self):
        self.path = REFERENCE_DIR / "scala-3.md"
        self.assertTrue(self.path.is_file(), f"missing {self.path}")
        self.text = self.path.read_text(encoding="utf-8")

    def test_covers_every_option_in_the_ecosystem_set(self):
        data = json.loads(ECOSYSTEM.read_text(encoding="utf-8"))
        for option in data["languages"]["scala-3"]["options"]:
            self.assertIn(option, self.text, f"scala-3.md omits {option}")

    def test_documents_native_adt_and_error_forms(self):
        for marker in ["enum", "Either", "opaque type"]:
            self.assertIn(marker, self.text)

    def test_carries_a_verification_date(self):
        self.assertIn("last-verified:", self.text)
```

- [ ] **Step 3: Run the test to verify it fails**

Run: `python3 -m unittest discover -s tests -t . -v`
Expected: FAIL — `missing .../references/scala-3.md`

- [ ] **Step 4: Write the reference**

Create `skills/functional-first/references/scala-3.md`, structured as:

- A header line `last-verified: YYYY-MM` recording Step 1's findings.
- **Native capability** — `enum` for ADTs (`since: 3.0`), `case class` for immutable records, `opaque type` for wrapper types without runtime cost (`since: 3.0`), `given`/`using` for explicit dependency passing (`since: 3.0`), compiler exhaustiveness checking over `enum` and `sealed` in `match`, `Either` for errors as values. Show one worked ADT-plus-decision example using `enum` and `Either`, with the decision function pure and the caller performing effects.
- **ZIO 2 idiom** — `ZIO[R, E, A]` carrying environment, typed error, and result; `ZLayer` for dependency wiring; where principle 2 is satisfied structurally because a `ZIO` value is itself a description. One worked example of the same decision expressed in ZIO.
- **cats-effect 3 idiom** — `IO`, `Resource`, `Ref`; constructor injection or tagless final for principle 6; typical companions (`http4s`, `fs2`, `doobie`). The same worked example in cats-effect.
- **Direct style idiom** — the same example with no effect monad: pure `enum`-based core, `Either` for failure, effects performed by ordinary code at the edge, and the concurrency tooling noted with its `since:` marker per Step 1's findings.
- **Substitutions** — none required; Scala 3 expresses every Axis A principle natively.

Each idiom section carries `since:` markers on any construct that is not available in every supported Scala 3 release. No section states or implies a preference.

- [ ] **Step 5: Run the test to verify it passes**

Run: `python3 -m unittest discover -s tests -t . -v`
Expected: PASS — 27 tests

- [ ] **Step 6: Commit**

```bash
git add skills/functional-first/references/scala-3.md tests/test_references.py
git commit -m "feat: add Scala 3 reference covering all three machinery options"
```

---

### Task 7: Java reference

**Files:**
- Create: `skills/functional-first/references/java.md`
- Modify: `tests/test_references.py` (append `TestJava`)

**Interfaces:**
- Consumes: `REFERENCE_DIR` and `ECOSYSTEM` from Task 5's `tests/test_references.py`; the `java` entry from Task 3
- Produces: the three-tier capability table referenced by `review-signals.md` Signal 4

- [ ] **Step 1: Verify the ecosystem facts before writing them**

Search for the current state of: Vavr's release activity and whether 1.0 has shipped; whether any Java-native effect library has gained meaningful adoption; and Java pattern-matching features finalized after 21. If a Java effect library has become mainstream, `ecosystem.json`'s `{ native }` for Java must change to a multi-member set — update it and re-run its tests before continuing.

- [ ] **Step 2: Write the failing test**

Append to `tests/test_references.py`, before the `if __name__` block:

```python
class TestJava(unittest.TestCase):
    def setUp(self):
        self.path = REFERENCE_DIR / "java.md"
        self.assertTrue(self.path.is_file(), f"missing {self.path}")
        self.text = self.path.read_text(encoding="utf-8")

    def test_documents_all_three_tiers(self):
        for tier in ["8 / 11", "16 / 17", "21+"]:
            self.assertIn(tier, self.text)

    def test_offers_the_visitor_substitution_for_the_oldest_tier(self):
        self.assertIn("visitor", self.text.lower())

    def test_reads_the_build_target_not_the_runtime(self):
        lowered = self.text.lower()
        self.assertIn("maven.compiler.release", lowered)
        self.assertIn("sourcecompatibility", lowered)
        self.assertIn("never the runtime", lowered)

    def test_carries_a_verification_date(self):
        self.assertIn("last-verified:", self.text)
```

- [ ] **Step 3: Run the test to verify it fails**

Run: `python3 -m unittest discover -s tests -t . -v`
Expected: FAIL — `missing .../references/java.md`

- [ ] **Step 4: Write the reference**

Create `skills/functional-first/references/java.md`, structured as:

- A header line `last-verified: YYYY-MM`.
- **Reading the Effective Language Level** — from `maven.compiler.release` or `sourceCompatibility` plus evidence in source (does `record` or `sealed` appear anywhere), stated explicitly as never the runtime. Note that a project may compile at 21 and be written entirely in Java 8 style.
- **Capability by tier**, as a table with columns `Effective level | record | sealed | switch patterns + exhaustiveness`, rows `8 / 11`, `16 / 17`, `21+`.
- **Tier 21+ idiom** (`since: 21`) — `record` plus `sealed interface` for the ADT, `switch` with record patterns for exhaustive handling. One worked decision example.
- **Tier 16/17 idiom** (`since: 16` for `record`, `since: 17` for `sealed`) — the same ADT, matched with an `instanceof` chain closing on `default -> throw new AssertionError()`, with exhaustiveness noted as unchecked.
- **Tier 8/11 Substitution** — no `record`, no `sealed`. Immutability via hand-written final fields or an annotation processor; the **visitor pattern** as the only construction giving compiler-checked exhaustiveness, because adding a case to the visitor interface breaks every implementor at compile time. One worked visitor example.
- **Errors as values across all tiers** — a sealed or visitor-based result type rather than checked exceptions.
- **Dependencies** — constructor parameters including a `Clock`, contrasted against `Instant.now()` in a method body.

- [ ] **Step 5: Run the test to verify it passes**

Run: `python3 -m unittest discover -s tests -t . -v`
Expected: PASS — 31 tests

- [ ] **Step 6: Commit**

```bash
git add skills/functional-first/references/java.md tests/test_references.py
git commit -m "feat: add Java reference with 8/17/21 capability tiers"
```

---

### Task 8: Python reference

**Files:**
- Create: `skills/functional-first/references/python.md`
- Modify: `tests/test_references.py` (append `TestPython`)

**Interfaces:**
- Consumes: `REFERENCE_DIR` and `ECOSYSTEM` from Task 5's `tests/test_references.py`; the `python` entry from Task 3
- Produces: the strict-checker precondition wording, the last reference in this plan

- [ ] **Step 1: Verify the ecosystem facts before writing them**

Search for the current state of: whether `returns` or another Python FP library has gained mainstream adoption; the current strict-mode flags for mypy and pyright; and any typing features after 3.12 affecting sum-type modelling. If a Python FP library has become mainstream, update `ecosystem.json` and re-run its tests before continuing.

- [ ] **Step 2: Write the failing test**

Append to `tests/test_references.py`, before the `if __name__` block:

```python
class TestPython(unittest.TestCase):
    def setUp(self):
        self.path = REFERENCE_DIR / "python.md"
        self.assertTrue(self.path.is_file(), f"missing {self.path}")
        self.text = self.path.read_text(encoding="utf-8")

    def test_states_the_strict_checker_precondition(self):
        lowered = self.text.lower()
        self.assertIn("precondition", lowered)
        self.assertIn("assert_never", lowered)
        self.assertTrue("mypy" in lowered and "pyright" in lowered)

    def test_says_what_happens_without_a_checker(self):
        self.assertIn("documentation value only", self.text.lower())

    def test_carries_a_verification_date(self):
        self.assertIn("last-verified:", self.text)
```

- [ ] **Step 3: Run the test to verify it fails**

Run: `python3 -m unittest discover -s tests -t . -v`
Expected: FAIL — `missing .../references/python.md`

- [ ] **Step 4: Write the reference**

Create `skills/functional-first/references/python.md`, structured as:

- A header line `last-verified: YYYY-MM`.
- **The precondition**, stated first because it governs everything below: a strict type checker (mypy or pyright in strict mode, with `typing.assert_never`) is a precondition for principle 4. Unlike Java 8, which has the visitor pattern, Python has **no** built-in construction turning a missing case into an error. Where a project has no strict checker, say plainly that principle 4 carries **documentation value only** in that project and degrade — silence here is worse than absence, because rigorous-looking models with zero enforcement mislead readers into believing they are protected.
- **Native capability** — `@dataclass(frozen=True)` for immutable records, tagged unions via `Literal` discriminants plus `Union` (or `X | Y`, `since: 3.10`), `match`/`case` structural pattern matching (`since: 3.10`), `assert_never` for exhaustiveness (`since: 3.11`, with the `typing_extensions` fallback noted).
- **A hand-written `Result`** — roughly twenty lines of generic frozen dataclasses `Ok` and `Err` with a `Union` alias, shown in full, and noted as reading more like Python than a dependency would.
- **A worked example** — a tagged-union domain model, a pure decision function returning `Result`, `match` with an `assert_never` fallthrough, and effects performed by the caller.
- **Dependencies** — a clock passed as a parameter, contrasted against `datetime.now()` in a function body.
- **Substitutions** — `Literal` discriminants standing in for real sum types, with the limitation stated: the guarantee comes from the checker, not the language.

- [ ] **Step 5: Run the test to verify it passes**

Run: `python3 -m unittest discover -s tests -t . -v`
Expected: PASS — 34 tests

- [ ] **Step 6: Commit**

```bash
git add skills/functional-first/references/python.md tests/test_references.py
git commit -m "feat: add Python reference with strict-checker precondition"
```

---

### Task 9: README, installation, and end-to-end verification

**Files:**
- Create: `README.md`
- Create: `tests/test_readme.py`

**Interfaces:**
- Consumes: every artifact from Tasks 1–8
- Produces: the shipped repository

The verification scenarios below are behavioural and cannot be unit-tested. They are run by hand, in a fresh session, and their results recorded — not asserted.

- [ ] **Step 1: Write the failing test**

Create `tests/test_readme.py`:

```python
import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parent.parent
README = ROOT / "README.md"


class TestReadme(unittest.TestCase):
    def setUp(self):
        self.assertTrue(README.is_file(), f"missing {README}")
        self.text = README.read_text(encoding="utf-8")

    def test_documents_both_adoption_modes(self):
        self.assertIn("~/.claude/CLAUDE.md", self.text)
        self.assertIn("project `CLAUDE.md`", self.text)

    def test_states_the_invocation_name(self):
        self.assertIn("functional-first:functional-first", self.text)

    def test_says_the_snippet_is_the_guarantee_layer(self):
        self.assertIn("even when the skill never loads", self.text)


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `python3 -m unittest discover -s tests -t . -v`
Expected: FAIL — `missing .../README.md`

- [ ] **Step 3: Write the README**

Create `README.md` covering: what the guideline is in two sentences; the contract, quoted from `SKILL.md`; installing the plugin; installing the snippet, with the two adoption modes as a table (`~/.claude/CLAUDE.md` for an individual, all their projects; project `CLAUDE.md` for a team, everyone on the repo) and the sentence that the snippet carries the principles so they hold **even when the skill never loads**; the invocation name `functional-first:functional-first`; how a project records its Stance; and how to run the tests.

- [ ] **Step 4: Run the test to verify it passes**

Run: `python3 -m unittest discover -s tests -t . -v`
Expected: PASS — 37 tests

- [ ] **Step 5: Run the full suite and verify it is green**

Run: `python3 -m unittest discover -s tests -t . -v`
Expected: PASS — 37 tests, 0 failures, 0 errors

- [ ] **Step 6: Run the behavioural verification scenarios by hand**

Install the plugin and the snippet, then in a **fresh session** for each scenario record what actually happened. These check the layers the tests cannot reach.

| # | Scenario | Expected |
|---|---|---|
| 1 | "Design an order service in Scala 3" in an empty directory | Skill loads without the word "functional" appearing; classifies greenfield; asks once between ZIO 2, cats-effect 3, and direct style with trade-offs shown |
| 2 | Same prompt, in a directory whose `build.sbt` lists `dev.zio::zio` | Does **not** ask; follows ZIO |
| 3 | Same prompt, with a Stance already recorded in the project `CLAUDE.md` | Does **not** ask; uses the recorded stance |
| 4 | "Design an order service in Java" in an empty directory | Does **not** ask — the option set has one member |
| 5 | "Add a retry to this handler" on an existing file, with the snippet installed but the skill not loading | The six principles still shape the change; this is the Layer 1 guarantee |
| 6 | "Review this file" on a Java 21 file with a `default` branch over a sealed hierarchy | Signal 4 fires; on a non-sealed selector it does not |

Record each result. Scenario 1 failing to load is the single most important failure mode in this design — if it does not fire, the description is wrong, not the principles.

- [ ] **Step 7: Commit**

```bash
git add README.md tests/test_readme.py
git commit -m "docs: add README with installation and adoption modes"
```

---

## Notes for the executor

- **References are facts, never stance.** `tests/test_references.py` enforces this with a phrase blacklist, but the blacklist is not exhaustive — if a sentence tells the reader which library to pick, it belongs in `SKILL.md` or nowhere.
- **Verify before writing ecosystem facts.** Tasks 6–8 each open with a search step. These claims were flagged in the spec as recalled rather than verified; treat a contradiction with `ecosystem.json` as a finding to fix there first, not as an inconvenience.
- **The snippet has a line budget.** If a principle will not fit, that is a signal to sharpen its wording, not to raise `MAX_CONTENT_LINES`.
- **Tasks 6–8 specify their files as structured outlines rather than literal content, deliberately.** Every other step in this plan carries the exact text to write. These three cannot: their content depends on the search performed in their own Step 1, and writing it out in advance would mean fabricating the very ecosystem facts the step exists to verify — baking in stale claims and making the verification theatre. The outlines name every section, construct, and worked example required, so nothing is left to taste; only the facts wait for verification.
- **`scala-2.md` is out of scope here.** `ecosystem.json` references it and `SKILL.md` links it; the file arrives in a later plan. Only `test_references.py::test_every_reference_marks_minimum_versions` would cover it, and it skips files that do not exist.
