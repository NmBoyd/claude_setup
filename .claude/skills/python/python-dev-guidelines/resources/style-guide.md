# Python Style Guide

## Overview

We follow the [Google Python Style Guide](https://google.github.io/styleguide/pyguide.html) and [PEP 8](https://peps.python.org/pep-0008/) with the additional rules documented below.

---

## Severity Levels

| Level | Meaning |
|-------|---------|
| **DO NOT** | Never do this. Exemptions require tech lead approval. |
| **AVOID** | We prefer you not do this, but exceptions exist. |
| **CONSIDER** | We prefer you do this, but exceptions exist. |
| **DO** | Always do this. Exemptions require tech lead approval. |

---

## A. Type Hints

**DO** use type hints for all public functions and methods.

```python
# ✅ CORRECT: Fully typed public API
def calculate_torque(joint_angle: float, velocity: float) -> float:
    """Calculate joint torque from angle and velocity."""
    return joint_angle * velocity * GAIN

# ✅ CORRECT: Complex types
def get_joint_states(robot_id: int) -> dict[str, JointState]:
    """Return mapping of joint names to states."""
    ...

# ❌ WRONG: Untyped public function
def calculate_torque(joint_angle, velocity):
    return joint_angle * velocity * GAIN
```

**CONSIDER** using type hints for private functions and local variables when it aids readability.

```python
# Helpful for complex types
_joint_cache: dict[str, list[JointState]] = {}

# Not necessary for obvious types
count = 0  # int is obvious
```

---

## B. Docstrings

**DO** use Google-style docstrings for all public modules, classes, and functions.

```python
def send_command(
    joint_id: int,
    position: float,
    velocity: float | None = None,
) -> CommandResult:
    """Send a position command to a joint.

    Sends the specified position to the joint controller. If velocity
    is provided, it will be used as a velocity limit.

    Args:
        joint_id: The unique identifier of the joint.
        position: Target position in radians.
        velocity: Optional velocity limit in rad/s.

    Returns:
        CommandResult containing success status and any error info.

    Raises:
        JointNotFoundError: If joint_id doesn't exist.
        CommandTimeoutError: If the command doesn't complete in time.

    Example:
        >>> result = send_command(joint_id=1, position=1.57)
        >>> if result.success:
        ...     print("Command sent successfully")
    """
```

**DO** include a module-level docstring at the top of every file.

```python
"""Joint control utilities for robot arm manipulation.

This module provides functions for sending commands to joints and
reading joint state feedback. It interfaces with the low-level
hardware abstraction layer.

Typical usage:
    from robot.control import joint_utils

    state = joint_utils.get_state(joint_id=1)
    joint_utils.send_command(joint_id=1, position=state.position + 0.1)
"""
```

---

## C. Imports

**DO** organize imports in three groups, separated by blank lines:

1. Standard library
2. Third-party packages
3. Local/project imports

```python
# Standard library
import logging
import os
from collections.abc import Callable, Sequence
from dataclasses import dataclass
from pathlib import Path
from typing import TYPE_CHECKING

# Third-party
import numpy as np
from pydantic import BaseModel, Field

# Local
from robot.control.joint import JointController
from robot.utils.math import normalize_angle

if TYPE_CHECKING:
    from robot.core.state import RobotState
```

**DO NOT** use wildcard imports.

```python
# ❌ NEVER
from numpy import *
from robot.utils import *

# ✅ ALWAYS: Explicit imports
from numpy import array, zeros, ones
from robot.utils import normalize_angle, clamp
```

**CONSIDER** using `from __future__ import annotations` for forward references.

```python
from __future__ import annotations

from dataclasses import dataclass

@dataclass
class Node:
    value: int
    children: list[Node]  # Works without quotes due to future import
```

---

## D. Naming Conventions

**DO** follow PEP 8 naming conventions:

| Type | Convention | Example |
|------|------------|---------|
| Modules | `snake_case` | `joint_controller.py` |
| Packages | `snake_case` | `robot_control` |
| Classes | `PascalCase` | `JointController` |
| Functions | `snake_case` | `get_joint_state()` |
| Variables | `snake_case` | `joint_angle` |
| Constants | `UPPER_SNAKE_CASE` | `MAX_VELOCITY` |
| Private | `_leading_underscore` | `_internal_cache` |
| "Very private" | `__double_leading` | `__internal_state` |

```python
# ✅ CORRECT
MAX_JOINT_VELOCITY = 2.0  # Module constant

class JointController:
    """Controls a single robot joint."""

    def __init__(self, joint_id: int) -> None:
        self._joint_id = joint_id  # Private attribute
        self.__state_cache = {}    # Name-mangled attribute

    def get_position(self) -> float:
        """Return current joint position."""
        ...

# ❌ WRONG
maxJointVelocity = 2.0        # Not snake_case
class joint_controller: ...    # Not PascalCase
def GetPosition(): ...         # Not snake_case
```

---

## E. Error Handling

**DO** use specific exception types.

```python
# ✅ CORRECT: Specific exceptions
try:
    result = controller.send_command(cmd)
except CommandTimeoutError:
    logger.warning("Command timed out, retrying...")
    result = controller.send_command(cmd, timeout=10.0)
except JointNotFoundError as e:
    logger.error("Joint not found: %s", e.joint_id)
    raise

# ❌ WRONG: Bare except
try:
    result = controller.send_command(cmd)
except:  # Catches everything including KeyboardInterrupt!
    pass

# ❌ WRONG: Too broad
try:
    result = controller.send_command(cmd)
except Exception:  # Too broad, hides bugs
    pass
```

**DO** define custom exceptions for your domain.

```python
class RobotError(Exception):
    """Base exception for robot errors."""

class JointNotFoundError(RobotError):
    """Raised when a joint ID doesn't exist."""

    def __init__(self, joint_id: int) -> None:
        self.joint_id = joint_id
        super().__init__(f"Joint {joint_id} not found")

class CommandTimeoutError(RobotError):
    """Raised when a command times out."""
```

**DO NOT** use exceptions for flow control.

```python
# ❌ WRONG: Exception for expected case
def get_user(user_id: int) -> User | None:
    try:
        return users[user_id]
    except KeyError:
        return None

# ✅ CORRECT: Check explicitly
def get_user(user_id: int) -> User | None:
    return users.get(user_id)
```

---

## F. Logging

**DO** use the `logging` module, not `print()`.

```python
import logging

logger = logging.getLogger(__name__)

# ✅ CORRECT: Structured logging
logger.info("Starting joint controller for joint %d", joint_id)
logger.warning("Joint %d approaching limit: %.2f rad", joint_id, position)
logger.error("Failed to send command", exc_info=True)

# ❌ WRONG: Print statements
print(f"Starting joint controller for joint {joint_id}")
print(f"Warning: Joint {joint_id} approaching limit")
```

**DO** use lazy formatting with `%s` style, not f-strings in log calls.

```python
# ✅ CORRECT: Lazy evaluation (string only built if level enabled)
logger.debug("Processing %d items: %s", len(items), items)

# ❌ WRONG: Eager evaluation (f-string always built)
logger.debug(f"Processing {len(items)} items: {items}")
```

---

## G. Classes and Data Structures

**DO** use `@dataclass` for simple data containers.

```python
from dataclasses import dataclass, field

@dataclass
class JointState:
    """Represents the state of a single joint."""

    joint_id: int
    position: float
    velocity: float
    effort: float = 0.0
    timestamp: float = field(default_factory=time.time)
```

**CONSIDER** using `pydantic.BaseModel` when you need validation.

```python
from pydantic import BaseModel, Field, field_validator

class JointCommand(BaseModel):
    """Command to send to a joint with validation."""

    joint_id: int = Field(ge=0, description="Joint identifier")
    position: float = Field(description="Target position in radians")
    velocity: float = Field(default=1.0, gt=0, description="Velocity limit")

    @field_validator("position")
    @classmethod
    def validate_position(cls, v: float) -> float:
        if not -3.14159 <= v <= 3.14159:
            raise ValueError("Position must be within [-π, π]")
        return v
```

**DO NOT** use mutable default arguments.

```python
# ❌ WRONG: Mutable default
def add_joint(joints: list[Joint] = []) -> None:
    joints.append(Joint())  # Same list shared across calls!

# ✅ CORRECT: None default with creation inside
def add_joint(joints: list[Joint] | None = None) -> None:
    if joints is None:
        joints = []
    joints.append(Joint())
```

---

## H. Context Managers and Resources

**DO** use context managers for resource management.

```python
# ✅ CORRECT: Context manager
with open("config.yaml") as f:
    config = yaml.safe_load(f)

# ❌ WRONG: Manual resource management
f = open("config.yaml")
config = yaml.safe_load(f)
f.close()  # May not run if exception occurs
```

**DO** create context managers for your own resources.

```python
from contextlib import contextmanager

@contextmanager
def joint_lock(joint_id: int):
    """Lock a joint for exclusive access."""
    lock = acquire_joint_lock(joint_id)
    try:
        yield lock
    finally:
        release_joint_lock(lock)

# Usage
with joint_lock(joint_id=1) as lock:
    controller.send_command(cmd)
```

---

## I. Testing

**DO** use `pytest` for testing.

```python
import pytest
from robot.control.joint import JointController, JointNotFoundError

class TestJointController:
    """Tests for JointController."""

    @pytest.fixture
    def controller(self) -> JointController:
        """Create a controller for testing."""
        return JointController(joint_id=1)

    def test_get_position_returns_current_position(
        self, controller: JointController
    ) -> None:
        """Should return the current joint position."""
        position = controller.get_position()
        assert isinstance(position, float)
        assert -3.15 <= position <= 3.15

    def test_send_command_invalid_joint_raises(self) -> None:
        """Should raise JointNotFoundError for invalid joint."""
        controller = JointController(joint_id=999)
        with pytest.raises(JointNotFoundError, match="Joint 999"):
            controller.send_command(position=0.0)

    @pytest.mark.parametrize(
        "position,expected",
        [
            (0.0, 0.0),
            (1.57, 1.57),
            (-1.57, -1.57),
        ],
    )
    def test_send_command_various_positions(
        self, controller: JointController, position: float, expected: float
    ) -> None:
        """Should accept various valid positions."""
        result = controller.send_command(position=position)
        assert result.target_position == expected
```

---

## J. TODO Comments and Temporary Code

**DO** use TODO comments with Jira tickets (same as C++ guide).

```python
# ✅ CORRECT: Tracked TODO
joint_limit = 1.57  # TODO(SWC-123) Read from config instead of hardcoding

# ❌ WRONG: Untracked TODO
joint_limit = 1.57  # TODO: fix this later
```

**AVOID** merging temporary code. If you must, use markers:

```python
# TODO(SWC-456) Remove this temporary code when real calibration is ready
# BEGIN temporary code
CALIBRATION_OFFSET = 0.05
# END temporary code
```

---

## Quick Reference

| Rule | Level | Summary |
|------|-------|---------|
| Type hints on public APIs | **DO** | All public functions/methods |
| Google-style docstrings | **DO** | Modules, classes, public functions |
| Organized imports | **DO** | stdlib / third-party / local |
| Wildcard imports | **DO NOT** | Never `from x import *` |
| Specific exceptions | **DO** | Catch specific, define custom |
| Bare except | **DO NOT** | Never `except:` |
| Logging over print | **DO** | Use `logging` module |
| Dataclasses for data | **DO** | Simple containers |
| Mutable default args | **DO NOT** | Use `None` default |
| Context managers | **DO** | For all resources |
| pytest for testing | **DO** | With fixtures and parametrize |
| TODO with Jira ticket | **DO** | `TODO(SWC-123)` format |

---

## Tools Configuration

### pyproject.toml

```toml
[tool.ruff]
line-length = 100
target-version = "py311"

[tool.ruff.lint]
select = [
    "E",    # pycodestyle errors
    "W",    # pycodestyle warnings
    "F",    # pyflakes
    "I",    # isort
    "B",    # flake8-bugbear
    "C4",   # flake8-comprehensions
    "UP",   # pyupgrade
]

[tool.mypy]
python_version = "3.11"
strict = true
warn_return_any = true
warn_unused_ignores = true

[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = "-v --tb=short"
```

---

## Related Resources

- [Google Python Style Guide](https://google.github.io/styleguide/pyguide.html)
- [PEP 8 -- Style Guide for Python Code](https://peps.python.org/pep-0008/)
- [PEP 257 -- Docstring Conventions](https://peps.python.org/pep-0257/)
- [python-dev-guidelines SKILL.md](../SKILL.md) - Main Python skill
