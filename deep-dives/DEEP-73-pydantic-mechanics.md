# DEEP MECHANICS · Pydantic

> Level 2 — validation engine, v1 vs v2, models/validators, settings, and
> serialization.

---

## 0. The precise mental model
Pydantic turns **type hints into runtime validation**. You declare a model; on construction it **parses, coerces, and validates** input, raising `ValidationError` on failure, and produces a typed, trusted object. It's the backbone of FastAPI request/response models. **v2** rewrote the core in **Rust (`pydantic-core`)** → much faster + stricter.

---

## 1. Basic model
```python
from pydantic import BaseModel, Field

class User(BaseModel):
    id: int
    name: str = Field(min_length=1)
    email: str
    age: int = 18                    # default
```
- Construction validates: `User(id="3", ...)` → `id` coerced to `int 3` (lax mode).
- Invalid input → **`ValidationError`** with structured error list (loc/msg/type).

## 2. Validation modes
- **Lax** (default): reasonable coercion (`"3"`→3, `"true"`→True).
- **Strict**: no coercion (`strict=True` / `Strict` types) → type must match exactly.
- Use `Field(...)` for constraints: `gt/ge/lt/le`, `min_length/max_length`, `pattern`, `default_factory`.

## 3. Custom validators (v2)
```python
from pydantic import field_validator, model_validator

@field_validator("email")
@classmethod
def check_email(cls, v):        # per-field
    if "@" not in v: raise ValueError("invalid")
    return v

@model_validator(mode="after")  # cross-field, whole model
def check_pw(self): ...
```
- `field_validator` (was `@validator`); `model_validator` (was `@root_validator`) for cross-field logic.

## 4. Serialization
- `model_dump()` → dict, `model_dump_json()` → JSON string (v2 names; v1 = `.dict()`/`.json()`).
- Control with `exclude/include/by_alias/exclude_none`; `Field(alias=...)` maps external ↔ internal names; `computed_field` for derived output.

## 5. Settings (config management)
```python
from pydantic_settings import BaseSettings
class Settings(BaseSettings):
    db_url: str
    api_key: str
    model_config = {"env_file": ".env"}
```
- **`BaseSettings`** loads + validates config from **env vars / `.env`** → typed, fail-fast config (12-factor).
- (In v2, settings moved to the separate `pydantic-settings` package.)

## 6. v1 vs v2 (know the differences)
| | v1 | v2 |
|---|---|---|
| Core | Python | **Rust (pydantic-core)** — faster |
| Validators | `@validator/@root_validator` | `@field_validator/@model_validator` |
| Serialize | `.dict()/.json()` | `.model_dump()/.model_dump_json()` |
| Config | `class Config` | `model_config` dict |
| Settings | built-in | `pydantic-settings` pkg |

## 7. FastAPI integration
- Request bodies → Pydantic models: **automatic validation + 422** on bad input + OpenAPI schema.
- **`response_model`** → validates/filters output (drop extra fields, enforce shape).

## 8. The hard follow-ups (with answers)
1. **"What does Pydantic actually do?"** → runtime parse/coerce/validate from type hints → typed trusted object or `ValidationError`. (§0)
2. **"v1 vs v2 big change?"** → v2 core in **Rust** (fast, strict) + renamed API (`model_validator`, `model_dump`). (§6)
3. **"Cross-field validation?"** → `model_validator(mode="after")`. (§3)
4. **"Load config from env?"** → `BaseSettings` (pydantic-settings) → typed, fail-fast. (§5)
5. **"Lax vs strict?"** → lax coerces (`"3"`→3); strict requires exact types. (§2)
6. **"How does FastAPI use it?"** → request models (auto-validate → 422) + `response_model` (shape output) + OpenAPI. (§7)
7. **"Rename field in JSON only?"** → `Field(alias=...)` + `by_alias=True` on dump. (§4)

## 9. One-screen recall
- **What**: type hints → **runtime validation/coercion**; fail → `ValidationError`.
- **v2** = Rust core (fast/strict); API: `field_validator`, `model_validator`, `model_dump(_json)`, `model_config`.
- **Constraints**: `Field(gt/min_length/pattern/default_factory)`.
- **Modes**: lax (coerce) vs strict.
- **Settings**: `BaseSettings` ← env/`.env` (pydantic-settings), fail-fast.
- **Serialize**: `model_dump`, alias/exclude/computed_field.
- **FastAPI**: body → validate/422, `response_model` → shape + OpenAPI.

> Next: SQLAlchemy.
