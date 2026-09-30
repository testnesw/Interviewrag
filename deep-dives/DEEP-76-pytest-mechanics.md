# DEEP MECHANICS · pytest

> Level 2 — fixtures, scopes, parametrize, mocking, conftest, markers, and
> async testing.

---

## 0. The precise mental model
pytest replaces ceremony with **plain `assert`** (rewritten to give rich failure output) and a powerful **fixture** system for dependency injection of test setup/teardown. Tests are discovered by convention (`test_*`), composed from fixtures, and scaled with **parametrize** and **markers**.

---

## 1. Basics
```python
def test_add():
    assert add(2, 3) == 5        # plain assert; pytest rewrites for rich diffs
```
- Discovery: files `test_*.py`, functions `test_*`, classes `Test*`.
- Failure shows introspected values (no `assertEqual` needed).

## 2. Fixtures = DI for tests
```python
@pytest.fixture
def db():
    conn = connect()
    yield conn          # setup before yield, teardown after
    conn.close()

def test_query(db):     # requested by name → injected
    assert db.ping()
```
- **`yield`** = setup/teardown in one place.
- Fixtures can depend on other fixtures (composable graph).

## 3. Fixture scopes
- `function` (default, per test), `class`, `module`, `package`, `session` (once per run).
- Use broader scope for expensive resources (DB container, app) → speed; beware **shared mutable state** across tests.
- `autouse=True` → applied without being requested (use sparingly).

## 4. Parametrize (data-driven)
```python
@pytest.mark.parametrize("inp,exp", [(2,4),(3,9),(0,0)])
def test_sq(inp, exp):
    assert sq(inp) == exp
```
- One test → many cases, each reported separately. Stack decorators for combinations.

## 5. conftest.py
- Central place for **shared fixtures + hooks**, auto-discovered by directory (no import needed).
- Fixtures apply to all tests in that dir/subdirs → DRY.

## 6. Mocking
- `unittest.mock` / `pytest-mock`'s **`mocker`** fixture; `monkeypatch` fixture to patch attrs/env/dict.
- **Patch where it's *used*, not where defined** (`patch("mymodule.requests.get")`).
- Assert interactions: `mock.assert_called_once_with(...)`.

## 7. Markers & selection
- Built-in: `@pytest.mark.skip`, `skipif`, `xfail`.
- Custom markers (`@pytest.mark.slow`) + register in config; select with `-m "not slow"`.
- Select by name `-k "login and not admin"`.

## 8. Extras
- **Coverage**: `pytest-cov` (`--cov`).
- **Async**: `pytest-asyncio` (`@pytest.mark.asyncio`).
- **Fixtures for temp files/dirs**: `tmp_path`; capture output: `capsys`.
- Exceptions: `with pytest.raises(ValueError): ...`.

## 9. The hard follow-ups (with answers)
1. **"Fixtures vs setup/teardown methods?"** → fixtures are composable, DI'd by name, scoped, with `yield` teardown — more flexible than xUnit setUp. (§2)
2. **"Expensive DB setup once?"** → `scope="session"` fixture (watch shared state). (§3)
3. **"Test 50 input cases?"** → `@pytest.mark.parametrize`. (§4)
4. **"Where to put shared fixtures?"** → **conftest.py** (auto-discovered per directory). (§5)
5. **"Common mock mistake?"** → patching where defined not where **used**. (§6)
6. **"Run only fast tests?"** → markers + `-m "not slow"` (or `-k`). (§7)
7. **"Test async code?"** → `pytest-asyncio` + `@pytest.mark.asyncio`. (§8)

## 10. One-screen recall
- **Plain `assert`** (rewritten), convention discovery `test_*`.
- **Fixtures** = DI setup/teardown via `yield`; composable; **scopes** function→session.
- **parametrize** = data-driven cases.
- **conftest.py** = shared fixtures/hooks, auto-discovered.
- **Mock**: `mocker`/`monkeypatch`; **patch where used**; `assert_called_*`.
- **Markers**: skip/xfail/custom + `-m`, select `-k`.
- **Extras**: pytest-cov, pytest-asyncio, `tmp_path`, `pytest.raises`.

> Next: Unit testing.
