# 73 · Pydantic

> Domain: Python / FastAPI · Level: Principal Backend Architect

## 1. Beginner Explanation
Pydantic is a Python library that validates and parses data using type hints. You define a model class with typed fields, and Pydantic ensures incoming data matches — converting types and raising clear errors when it doesn't.

## 2. Architect-Level Explanation
Pydantic is the data-validation/serialization layer powering FastAPI:
- **Models**: `BaseModel` subclasses with typed fields → parse, validate, coerce, and serialize.
- **v2 performance**: core rewritten in **Rust (pydantic-core)** → very fast validation/serialization.
- **Validation**: type coercion, constraints (`Field(gt=0, max_length=...)`), custom validators (`@field_validator`, `@model_validator`), computed fields.
- **Settings**: `pydantic-settings` (`BaseSettings`) loads/validates config from env/files — typed configuration.
- **Serialization**: `model_dump()` / `model_dump_json()`, aliases, include/exclude, by_alias.
- **Schema**: generates JSON Schema → drives FastAPI's OpenAPI docs.
- **Strictness**: strict vs lax mode; `ConfigDict` controls behavior (extra fields, frozen, etc.).
- Separate **API schemas** from ORM models (don't reuse SQLAlchemy models as request bodies).

## 3. Real Enterprise Use Case
A service defines strict request/response Pydantic models with field constraints and custom validators (e.g., valid currency, positive amounts), loads typed settings from env via `BaseSettings`, and returns clear 422 validation errors. The models auto-generate OpenAPI schemas for the API contract and client SDKs.

## 4. Architecture Diagram (ASCII)
```
   Raw JSON ─► Pydantic model (BaseModel)
                 ├─ type coercion ("5"→5)
                 ├─ constraints (gt=0, max_length)
                 ├─ @field_validator / @model_validator
                 └─ valid object  OR  422 with error details
   model_dump_json() ─► response (aliases, exclude)
   JSON Schema ─► FastAPI OpenAPI /docs
   BaseSettings ─► typed config from env/Key Vault
```

## 5. Interview Questions
1. What does Pydantic do and why with FastAPI?
2. What changed in Pydantic v2?
3. How do you add custom validation?
4. How do you manage config with Pydantic?
5. Why separate API schemas from ORM models?

## 6. Strong Interview Answers
- **What/why**: "Pydantic validates and parses data from type hints — coercing types, enforcing constraints, and producing clear errors. FastAPI uses it to validate requests, serialize responses, and generate OpenAPI automatically."
- **v2**: "The validation core was rewritten in Rust (pydantic-core), making it much faster. APIs changed: `model_dump`/`model_validate` replace `dict`/`parse_obj`, `@field_validator` replaces `@validator`, and `ConfigDict` replaces the inner `Config` class."
- **Custom validation**: "`@field_validator` for single-field rules, `@model_validator` for cross-field logic, plus `Field(...)` constraints (gt, max_length, pattern) and computed fields. Raising ValueError yields a structured 422."
- **Config**: "`pydantic-settings` `BaseSettings` loads config from env vars/`.env`/secrets with type validation and defaults — typed, validated configuration instead of scattered `os.getenv` calls."
- **Schemas vs ORM**: "API schemas (Pydantic) define the external contract; ORM models (SQLAlchemy) define persistence. Reusing ORM models as request bodies leaks internal fields and couples API to DB — keep them separate and map between them."

## 7. Common Mistakes
- Reusing SQLAlchemy models as API schemas.
- Using v1 APIs/patterns in v2 (deprecated).
- No constraints/validators → weak validation.
- Scattered `os.getenv` instead of BaseSettings.
- Allowing arbitrary extra fields unintentionally.

## 8. Trade-offs
| Choice | Pro | Con |
|--------|-----|-----|
| Strict mode | catches bad data | less lenient coercion |
| Rich validators | safe contracts | more code |
| Separate schemas | clean boundary | mapping boilerplate |

## 9. Production Best Practices
- Separate request/response/DB models; map explicitly.
- Field constraints + custom validators for invariants.
- `BaseSettings` for typed config (env + Key Vault).
- Control extra fields (`extra="forbid"` for strict inputs).
- Use v2 APIs; leverage generated JSON Schema.

## 10. Security Considerations
- Validation blocks malformed/oversized/injection payloads.
- `extra="forbid"` prevents mass-assignment of unexpected fields.
- Exclude sensitive fields from responses (`exclude`, `SecretStr`).
- Constrain string lengths/patterns to limit abuse.

## 11. Cost Optimization
- v2 Rust core → less CPU per request.
- Reject bad input early (cheap 422 vs downstream work).
- Efficient serialization reduces payload/egress.

## 12. Troubleshooting Scenarios
- **Unexpected 422** → input violates schema/constraint; inspect error detail.
- **Silent type coercion** → use strict mode where needed.
- **Deprecation warnings** → migrate v1→v2 APIs.
- **Leaked fields** → ORM reused as schema; separate + exclude.
- **Config missing** → BaseSettings env var name/alias mismatch.

## 13. Hands-on Example
```python
from pydantic import BaseModel, Field, field_validator

class Order(BaseModel):
    total: float = Field(gt=0)
    currency: str = Field(pattern="^[A-Z]{3}$")

    @field_validator("currency")
    @classmethod
    def known(cls, v):
        if v not in {"USD", "EUR", "INR"}:
            raise ValueError("unsupported currency")
        return v

Order(total=42, currency="USD")   # ok; total="42" also coerces
```

## 14. Terraform Example
```hcl
# Provide typed settings via env; BaseSettings validates them at startup
resource "kubernetes_config_map" "cfg" {
  metadata { name = "api-settings" namespace = "app" }
  data = { APP_ENV = "prod", MAX_ITEMS = "100" }
}
```

## 15. Azure Example
```python
# BaseSettings pulling from env; secrets injected via Key Vault CSI mount
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    app_env: str = "dev"
    max_items: int = 50
    openai_endpoint: str
    class Config: env_file = ".env"
settings = Settings()   # validated, typed config
```

## 16. FastAPI / Python Example
```python
from fastapi import FastAPI
app = FastAPI()

class CreateUser(BaseModel):        # request schema
    email: str = Field(pattern=r"^[^@]+@[^@]+$")
    age: int = Field(ge=0, le=120)
    model_config = {"extra": "forbid"}   # reject unexpected fields

@app.post("/users")
async def create(u: CreateUser):    # auto-validated → 422 on bad input
    return {"email": u.email}
```

## 17. AKS Example
`BaseSettings` reads ConfigMap env vars and Key Vault CSI-mounted secrets at pod startup, failing fast (crash + restart) if required config is missing or invalid — surfacing misconfiguration immediately in AKS rather than at first request.

## 18. How to Remember
**"Type hints → validated models + JSON Schema."** v2 = Rust-fast, `model_dump`/`field_validator`; BaseSettings for config; separate schemas from ORM.

## 19. Real-World Analogy
A strict customs officer with a checklist (the model): every item (field) must match the declared type and rules; anything malformed or contraband (invalid/extra fields) is rejected with a clear reason (422), and approved goods are neatly re-packaged for delivery (serialization).

## 20. One-Page Cheat Sheet
- **What**: type-hint-driven validation, parsing, and serialization; powers FastAPI + OpenAPI.
- **v2**: Rust core (fast); `model_dump`/`model_validate`, `@field_validator`, `ConfigDict`.
- **Validate**: `Field(gt=, max_length=, pattern=)`, field/model validators, computed fields.
- **Config**: `pydantic-settings` `BaseSettings` (typed env/secret config).
- **Boundaries**: separate API schemas from ORM models; `extra="forbid"` for strict inputs.
- **Payoff**: clear 422 errors, auto JSON Schema, less CPU, safer contracts.
