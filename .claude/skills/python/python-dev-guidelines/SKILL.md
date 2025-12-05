---
name: python-dev-guidelines
description: Python development guidelines for modern Python projects. Use when creating Python modules, classes, functions, scripts, or working with type hints, pytest, packaging (pip/poetry), virtual environments, async/await, data classes, or Python best practices. Covers project structure, typing, testing patterns, error handling, logging, and Pythonic idioms.
---

# Python Development Guidelines

## Purpose

Establish consistency and best practices for Python development, covering modern Python 3.10+ patterns, type safety, testing, and project organization.

## When to Use This Skill

Automatically activates when working on:
- Creating or modifying Python files (`.py`)
- Writing classes, functions, or modules
- Setting up Python projects (pyproject.toml, setup.py)
- Writing tests with pytest
- Working with type hints and mypy
- Async/await patterns
- Package management (pip, poetry, conda)

---

## Quick Start

### New Python Project Checklist

- [ ] **Project structure**: src layout or flat layout
- [ ] **pyproject.toml**: Modern packaging config
- [ ] **Type hints**: All public APIs typed
- [ ] **Tests**: pytest with fixtures
- [ ] **Linting**: ruff or flake8 + black
- [ ] **Virtual env**: venv, poetry, or conda
- [ ] **Documentation**: Docstrings (Google or NumPy style)

### New Module Checklist

- [ ] Module docstring at top
- [ ] Type hints on all public functions
- [ ] `__all__` export list (if applicable)
- [ ] Unit tests in `tests/` mirror structure
- [ ] Error handling with custom exceptions

---

## Project Structure

### Recommended Layout (src-layout)

```
project/
├── src/
│   └── mypackage/
│       ├── __init__.py
│       ├── core/
│       │   ├── __init__.py
│       │   └── module.py
│       ├── utils/
│       │   ├── __init__.py
│       │   └── helpers.py
│       └── py.typed          # PEP 561 marker
├── tests/
│   ├── conftest.py           # Shared fixtures
│   ├── test_core/
│   │   └── test_module.py
│   └── test_utils/
│       └── test_helpers.py
├── pyproject.toml
├── README.md
└── .python-version           # pyenv version
```

### Alternative: Flat Layout (smaller projects)

```
project/
├── mypackage/
│   ├── __init__.py
│   └── module.py
├── tests/
│   └── test_module.py
├── pyproject.toml
└── README.md
```

---

## Core Principles (7 Key Rules)

### 1. Type Everything Public

```python
# ❌ NEVER: Untyped public functions
def process_data(data):
    return data.upper()

# ✅ ALWAYS: Full type annotations
def process_data(data: str) -> str:
    return data.upper()
```

### 2. Use Dataclasses or Pydantic for Data

```python
from dataclasses import dataclass
from typing import Optional

# ✅ Dataclass for simple data containers
@dataclass
class User:
    id: int
    name: str
    email: Optional[str] = None

# ✅ Pydantic for validation
from pydantic import BaseModel, EmailStr

class UserCreate(BaseModel):
    name: str
    email: EmailStr
```

### 3. Handle Errors with Custom Exceptions

```python
# Define custom exceptions
class ValidationError(Exception):
    """Raised when validation fails."""
    pass

class NotFoundError(Exception):
    """Raised when resource not found."""
    pass

# Use them explicitly
def get_user(user_id: int) -> User:
    user = db.find(user_id)
    if not user:
        raise NotFoundError(f"User {user_id} not found")
    return user
```

### 4. Use Context Managers for Resources

```python
# ❌ NEVER: Manual resource management
f = open("file.txt")
data = f.read()
f.close()

# ✅ ALWAYS: Context managers
with open("file.txt") as f:
    data = f.read()

# ✅ Custom context managers
from contextlib import contextmanager

@contextmanager
def database_transaction():
    conn = get_connection()
    try:
        yield conn
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()
```

### 5. Prefer Composition Over Inheritance

```python
# ❌ Avoid deep inheritance
class Animal: ...
class Mammal(Animal): ...
class Dog(Mammal): ...

# ✅ Prefer composition and protocols
from typing import Protocol

class Walker(Protocol):
    def walk(self) -> None: ...

class Dog:
    def __init__(self, legs: int = 4):
        self.legs = legs

    def walk(self) -> None:
        print(f"Walking on {self.legs} legs")
```

### 6. Use Logging, Not Print

```python
import logging

logger = logging.getLogger(__name__)

# ❌ NEVER
print(f"Processing {item}")

# ✅ ALWAYS
logger.info("Processing %s", item)
logger.error("Failed to process", exc_info=True)
```

### 7. Write Testable Code

```python
# ❌ Hard to test: hidden dependencies
def send_email(user_id: int) -> None:
    user = database.get_user(user_id)  # Hidden dependency
    smtp.send(user.email, "Hello")      # Hidden dependency

# ✅ Easy to test: explicit dependencies
def send_email(
    user: User,
    email_sender: EmailSender
) -> None:
    email_sender.send(user.email, "Hello")
```

---

## Common Imports

```python
# Standard library
from __future__ import annotations
from typing import Optional, List, Dict, Any, TypeVar, Generic
from dataclasses import dataclass, field
from pathlib import Path
from collections.abc import Callable, Iterator, Sequence
import logging
from contextlib import contextmanager
from functools import lru_cache, wraps

# Type checking only
from typing import TYPE_CHECKING
if TYPE_CHECKING:
    from mypackage.models import User

# Async
import asyncio
from typing import Coroutine

# Testing
import pytest
from unittest.mock import Mock, patch, MagicMock
```

---

## Type Hints Quick Reference

```python
# Basic types
x: int = 1
name: str = "hello"
flag: bool = True
values: list[int] = [1, 2, 3]
mapping: dict[str, int] = {"a": 1}

# Optional (can be None)
from typing import Optional
value: Optional[str] = None  # or: str | None (3.10+)

# Union types (3.10+)
result: int | str = get_result()

# Callable
from collections.abc import Callable
handler: Callable[[int, str], bool]

# Generics
from typing import TypeVar, Generic
T = TypeVar('T')

class Container(Generic[T]):
    def __init__(self, value: T) -> None:
        self.value = value
```

---

## Testing Patterns

### pytest Fixtures

```python
# conftest.py
import pytest
from mypackage.models import User

@pytest.fixture
def sample_user() -> User:
    return User(id=1, name="Test", email="test@example.com")

@pytest.fixture
def mock_database(mocker):
    return mocker.patch("mypackage.db.connection")
```

### Test Structure

```python
# test_user_service.py
import pytest
from mypackage.services import UserService

class TestUserService:
    """Tests for UserService."""

    def test_create_user_success(self, mock_database):
        """Should create user with valid data."""
        service = UserService(mock_database)
        user = service.create(name="Test", email="test@example.com")

        assert user.name == "Test"
        mock_database.save.assert_called_once()

    def test_create_user_invalid_email_raises(self, mock_database):
        """Should raise ValidationError for invalid email."""
        service = UserService(mock_database)

        with pytest.raises(ValidationError, match="invalid email"):
            service.create(name="Test", email="not-an-email")
```

---

## Anti-Patterns to Avoid

❌ Mutable default arguments (`def foo(items=[])`)
❌ Bare `except:` clauses
❌ `from module import *`
❌ Global mutable state
❌ Ignoring type checker errors
❌ print() instead of logging
❌ String concatenation in loops (use join)
❌ Not using `if __name__ == "__main__":`

---

## Async Patterns

```python
import asyncio
from typing import AsyncIterator

async def fetch_data(url: str) -> dict:
    async with aiohttp.ClientSession() as session:
        async with session.get(url) as response:
            return await response.json()

async def process_items(items: list[str]) -> list[dict]:
    tasks = [fetch_data(item) for item in items]
    return await asyncio.gather(*tasks)

# Async generator
async def stream_data() -> AsyncIterator[bytes]:
    async with aiofiles.open("large.bin", "rb") as f:
        while chunk := await f.read(8192):
            yield chunk
```

---

## Resource Files

### [style-guide.md](resources/style-guide.md)
Google Python Style Guide + PEP 8 practices, naming, docstrings, imports

<!-- ### [project-setup.md](resources/project-setup.md)
pyproject.toml, poetry, pip, virtual environments

### [typing-guide.md](resources/typing-guide.md)
Advanced type hints, generics, protocols, mypy configuration

### [testing-patterns.md](resources/testing-patterns.md)
pytest fixtures, mocking, parameterization, coverage

### [async-patterns.md](resources/async-patterns.md)
asyncio, aiohttp, async context managers

### [packaging.md](resources/packaging.md)
Building packages, publishing to PyPI, versioning -->

---

## Related Skills

- **cpp-dev-guidelines** - C++ development patterns
- **error-tracking** - Sentry integration for Python
- **skill-developer** - Creating and managing skills

---

**Skill Status**: INITIAL ✅
**Line Count**: < 500 ✅
**Progressive Disclosure**: Resource files for details ✅
