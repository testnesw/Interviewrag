# DEEP MECHANICS · Unit Testing

> Level 2 — isolation, test doubles, AAA, FIRST principles, coverage, and what
> makes a *good* unit test.

---

## 0. The precise mental model
A unit test verifies **one unit of behavior in isolation** — fast, deterministic, no external dependencies (DB/network/filesystem). You replace collaborators with **test doubles** so a failure points to exactly one place. Good unit tests test **behavior/contracts, not implementation details**, so they survive refactors.

---

## 1. What "unit" and "isolated" mean
- **Unit** = smallest testable behavior (a function/method/class responsibility) — not necessarily one function.
- **Isolated** = no real I/O; dependencies stubbed/mocked → deterministic + fast (ms).
- Isolation also = tests don't depend on each other or order.

## 2. AAA structure
```
Arrange  → set up inputs + doubles
Act      → call the unit
Assert   → verify output/behavior
```
- One logical assertion/behavior per test → clear failure meaning.

## 3. FIRST principles
- **F**ast · **I**solated/Independent · **R**epeatable (deterministic) · **S**elf-validating (pass/fail, no manual check) · **T**imely (written with/before code).

## 4. Test doubles (know the distinctions)
| Double | Purpose |
|---|---|
| **Dummy** | placeholder, never used |
| **Stub** | returns canned data (state) |
| **Spy** | stub + records calls |
| **Mock** | pre-programmed w/ expectations; verifies **interactions** |
| **Fake** | working lightweight impl (in-memory DB) |
- **State verification** (stub → check result) vs **interaction verification** (mock → check calls made).

## 5. What to test / not test
- Test: business logic, branches, edge cases, error paths, boundaries.
- Don't test: language/framework internals, trivial getters, or **implementation details** (over-mocking couples tests to code → brittle).
- Prefer testing **public behavior**; if a private method needs direct testing it may want extracting.

## 6. Coverage
- **Line/branch coverage** = a guide, not a goal. 100% line coverage ≠ correct (can cover without asserting).
- Aim for **meaningful assertions on critical paths**; low coverage flags risk, high coverage doesn't prove quality.

## 7. Design for testability
- **DI** (inject deps → substitutable), pure functions, small responsibilities (SRP), depend on abstractions.
- Hard-to-test code usually signals poor design (hidden deps, side effects).

## 8. The hard follow-ups (with answers)
1. **"Unit vs integration test?"** → unit = one behavior isolated with doubles (fast, no I/O); integration = real components/DB together. (§1)
2. **"Mock vs stub?"** → stub returns data (state verification); mock verifies **interactions** (expected calls). (§4)
3. **"Why can over-mocking be bad?"** → couples tests to implementation → brittle, breaks on refactor; test behavior instead. (§5)
4. **"Is 100% coverage enough?"** → no — coverage ≠ correctness; need meaningful assertions. (§6)
5. **"Code is hard to unit test — why?"** → hidden deps/side effects → refactor with DI + SRP. (§7)
6. **"Structure a test?"** → **AAA** (Arrange-Act-Assert), one behavior. (§2)
7. **"FIRST?"** → Fast, Isolated, Repeatable, Self-validating, Timely. (§3)

## 9. One-screen recall
- **Unit** = one behavior **isolated** (doubles, no I/O), fast + deterministic + independent.
- **AAA** structure; **FIRST** principles.
- **Doubles**: dummy/stub/spy/**mock**/fake; state vs **interaction** verification.
- **Test behavior, not implementation** → survives refactor; avoid over-mocking.
- **Coverage** = guide not goal; meaningful asserts matter.
- **Testable design** = DI + pure functions + SRP.

> Next: Integration testing.
