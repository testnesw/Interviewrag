# 77 · Unit Testing

> Domain: Python / FastAPI · Level: Principal Backend Architect

## 1. Beginner Explanation
Unit testing means testing the **smallest pieces of your code** (a single function or class) in isolation, to confirm each behaves correctly on its own — fast, focused, and independent of databases or networks.

## 2. Architect-Level Explanation
Unit tests verify one unit of behavior in isolation:
- **Scope**: a function/method/class with dependencies replaced by **test doubles** (mocks, stubs, fakes, spies).
- **Fast & deterministic**: no real DB/network/filesystem → milliseconds, no flakiness; the base of the **test pyramid** (many unit, fewer integration, few E2E).
- **Isolation techniques**: dependency injection + FastAPI `dependency_overrides`, `unittest.mock`/`pytest-mock` for patching, fakes for repositories/clients.
- **Design feedback**: hard-to-unit-test code signals poor design (tight coupling) → drives DI, pure functions, hexagonal/ports-and-adapters.
- **What to test**: business logic, edge cases, error paths, validation — not framework internals or third-party libs.
- **Coverage** is a guide, not a goal; assert behavior, not implementation.
- **AAA pattern**: Arrange, Act, Assert; one logical assertion per test.
- **TDD** optional but valued: red → green → refactor.

## 3. Real Enterprise Use Case
A team unit-tests domain logic (pricing rules, order validation, discount calculation) with pure functions and fakes for the repository and payment gateway — hundreds of tests run in seconds on every commit, catching regressions before slower integration tests, giving developers instant feedback.

## 4. Architecture Diagram (ASCII)
```
   Test Pyramid
        ▲ few    E2E (slow, real everything)
        │        Integration (real DB/queue)
        │ many   UNIT ── one function, doubles for deps ── ms, no I/O
   Unit test: Arrange (fakes) ─► Act (call unit) ─► Assert (behavior)
   Doubles: mock (verify calls) · stub (canned data) · fake (working lite impl)
```

## 5. Interview Questions
1. What is a unit test and what makes it "unit"?
2. Mock vs stub vs fake vs spy?
3. What belongs in unit vs integration tests?
4. How does testability relate to design?
5. What should you avoid asserting?

## 6. Strong Interview Answers
- **Unit**: "A test of one small unit of behavior in isolation, with dependencies replaced by test doubles, running fast with no external I/O. It pinpoints exactly what broke."
- **Doubles**: "A stub returns canned data; a mock also verifies interactions (was it called, with what); a fake is a lightweight working implementation (in-memory repo); a spy records calls on a real object. I prefer fakes/stubs for state-based testing and mocks sparingly for interaction verification."
- **Unit vs integration**: "Unit tests cover business logic, edge cases, and error handling in isolation. Integration tests verify real collaborations — DB queries, HTTP endpoints, message queues. Unit tests are the majority; integration catches wiring issues."
- **Testability/design**: "If a unit is hard to test, it's usually too coupled. Testability pushes you toward DI, pure functions, and ports-and-adapters — so unit testing is also a design tool."
- **Avoid asserting**: "Don't assert implementation details or framework/third-party internals — that makes tests brittle. Assert observable behavior and outputs so refactoring doesn't break tests unnecessarily."

## 7. Common Mistakes
- Hitting real DB/network in "unit" tests (slow, flaky).
- Over-mocking → tests coupled to implementation.
- Testing framework/library internals.
- Multiple unrelated assertions per test.
- Chasing 100% coverage over meaningful behavior.

## 8. Trade-offs
| Double | Pro | Con |
|--------|-----|-----|
| Fake | realistic, reusable | more code to build |
| Stub | simple | no interaction checks |
| Mock | verifies calls | brittle if overused |

## 9. Production Best Practices
- Isolate with DI/overrides + fakes; keep tests fast/deterministic.
- AAA structure; one logical assertion; clear names.
- Test edge cases + error paths, not just happy path.
- Prefer state-based (fakes) over interaction-based (mocks).
- Run on every commit; coverage as a guide + mutation testing for quality.

## 10. Security Considerations
- Negative tests for authz/validation (forbidden, invalid input).
- No real secrets in tests; use fakes.
- Test input-sanitization and error-handling paths.

## 11. Cost Optimization
- Fast unit tests → cheap, quick CI feedback.
- Fewer slow integration/E2E runs needed when units are solid.
- Parallelizable (no shared state).

## 12. Troubleshooting Scenarios
- **Flaky unit test** → hidden real I/O / time/random dependence → inject clock/seed.
- **Brittle tests break on refactor** → over-mocking implementation; assert behavior.
- **Slow "unit" suite** → real dependencies leaking in; add doubles.
- **Low value coverage** → testing getters/framework; focus on logic.

## 13. Hands-on Example
```python
from unittest.mock import MagicMock

def test_apply_discount():
    repo = MagicMock()                     # double for dependency
    repo.get_rate.return_value = 0.10      # stub behavior
    price = apply_discount(100.0, repo, code="SAVE10")
    assert price == 90.0                    # assert behavior
```

## 14. Terraform Example
```hcl
# CI stage runs unit tests before any infra/build steps (fail fast, cheap)
# azure-pipelines: - script: pytest tests/unit -q --cov=app
# (unit tests need no infrastructure — that's the point)
```

## 15. Azure Example
In the CI pipeline (GitHub Actions/Azure DevOps), the unit-test job runs first with no Azure resources provisioned; only if it passes do integration jobs spin up real dependencies — saving time and cloud cost.

## 16. FastAPI / Python Example
```python
# Pure domain logic — trivial to unit test, no framework/DB
def calculate_total(items: list[dict], tax_rate: float) -> float:
    subtotal = sum(i["price"] * i["qty"] for i in items)
    return round(subtotal * (1 + tax_rate), 2)

import pytest
@pytest.mark.parametrize("rate,expected", [(0.0, 20.0), (0.1, 22.0)])
def test_calculate_total(rate, expected):
    items = [{"price": 10.0, "qty": 2}]
    assert calculate_total(items, rate) == expected
```

## 17. AKS Example
Unit tests run in the container build stage (multi-stage Dockerfile `RUN pytest tests/unit`) so a broken unit fails the image build before it ever reaches ACR/AKS — shifting failures left, out of the cluster.

## 18. How to Remember
**"One unit, no I/O, doubles for deps, assert behavior (AAA)."** Base of the pyramid: many fast unit tests.

## 19. Real-World Analogy
Testing each car part on a bench before assembly — the spark plug, the brake pad — with simulated inputs, rather than only test-driving the finished car. If a part fails, you know exactly which one, instantly.

## 20. One-Page Cheat Sheet
- **Unit**: smallest behavior in isolation; deps replaced by doubles; fast, deterministic.
- **Doubles**: stub (canned), mock (verify calls), fake (lite impl), spy (record).
- **Pyramid**: many unit → fewer integration → few E2E.
- **Design**: hard to test = too coupled → DI, pure functions, ports/adapters.
- **Do**: AAA, edge/error cases, assert behavior; **avoid**: real I/O, over-mocking, testing internals.
- **CI**: run first/fast; coverage as guide (+ mutation testing).
