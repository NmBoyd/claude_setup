# Behavioral Design Patterns

## Table of Contents

- [Strategy](#strategy)
- [Observer](#observer)
- [Command](#command)
- [State](#state)
- [Template Method](#template-method)
- [Chain of Responsibility](#chain-of-responsibility)
- [Quick Reference](#quick-reference)
- [Related Resources](#related-resources)

---

Patterns that deal with object communication and responsibility.

---

## Strategy

**Purpose:** Swap algorithms at runtime.

**Use when:** Multiple algorithms for same task, need runtime flexibility.

### Python

```python
from typing import Protocol
import numpy as np

class TrajectoryGenerator(Protocol):
    def generate(self, start: float, end: float, duration: float) -> np.ndarray: ...

class LinearTrajectory:
    def generate(self, start: float, end: float, duration: float) -> np.ndarray:
        t = np.linspace(0, duration, 100)
        return start + (end - start) * (t / duration)

class CubicTrajectory:
    def generate(self, start: float, end: float, duration: float) -> np.ndarray:
        t = np.linspace(0, duration, 100)
        s = t / duration
        return start + (end - start) * (3 * s**2 - 2 * s**3)

class MotionController:
    def __init__(self, generator: TrajectoryGenerator) -> None:
        self._generator = generator

    def set_generator(self, generator: TrajectoryGenerator) -> None:
        self._generator = generator

    def move(self, start: float, end: float, duration: float) -> np.ndarray:
        return self._generator.generate(start, end, duration)

# Usage - swap strategies
controller = MotionController(LinearTrajectory())
controller.set_generator(CubicTrajectory())
```

---

## Observer

**Purpose:** Notify multiple objects of state changes.

**Use when:** One-to-many dependency, event systems.

### Python

```python
from typing import Protocol
from dataclasses import dataclass

class StateObserver(Protocol):
    def on_state_change(self, state: "RobotState") -> None: ...

@dataclass
class RobotState:
    position: float = 0.0
    velocity: float = 0.0

class StatePublisher:
    def __init__(self) -> None:
        self._observers: list[StateObserver] = []
        self._state = RobotState()

    def subscribe(self, observer: StateObserver) -> None:
        self._observers.append(observer)

    def unsubscribe(self, observer: StateObserver) -> None:
        self._observers.remove(observer)

    def update_state(self, state: RobotState) -> None:
        self._state = state
        for observer in self._observers:
            observer.on_state_change(self._state)

class Logger:
    def on_state_change(self, state: RobotState) -> None:
        print(f"State: pos={state.position:.2f}")

class SafetyMonitor:
    def on_state_change(self, state: RobotState) -> None:
        if abs(state.velocity) > 2.0:
            print("WARNING: Velocity limit!")

# Usage
publisher = StatePublisher()
publisher.subscribe(Logger())
publisher.subscribe(SafetyMonitor())
```

---

## Command

**Purpose:** Encapsulate requests as objects.

**Use when:** Undo/redo, queuing, logging operations.

### Python

```python
from abc import ABC, abstractmethod
from dataclasses import dataclass

class Command(ABC):
    @abstractmethod
    def execute(self) -> None: ...
    @abstractmethod
    def undo(self) -> None: ...

@dataclass
class MoveCommand(Command):
    joint: "Joint"
    target: float
    _previous: float = 0.0

    def execute(self) -> None:
        self._previous = self.joint.position
        self.joint.move_to(self.target)

    def undo(self) -> None:
        self.joint.move_to(self._previous)

class CommandHistory:
    def __init__(self) -> None:
        self._history: list[Command] = []
        self._redo_stack: list[Command] = []

    def execute(self, command: Command) -> None:
        command.execute()
        self._history.append(command)
        self._redo_stack.clear()

    def undo(self) -> None:
        if self._history:
            command = self._history.pop()
            command.undo()
            self._redo_stack.append(command)

    def redo(self) -> None:
        if self._redo_stack:
            command = self._redo_stack.pop()
            command.execute()
            self._history.append(command)

# Usage
history = CommandHistory()
history.execute(MoveCommand(joint, target=1.0))
history.undo()
history.redo()
```

---

## State

**Purpose:** Object behavior changes based on internal state.

**Use when:** Finite state machines, mode-dependent behavior.

### Python

```python
from abc import ABC, abstractmethod

class RobotState(ABC):
    @abstractmethod
    def start(self, robot: "Robot") -> None: ...
    @abstractmethod
    def stop(self, robot: "Robot") -> None: ...
    @abstractmethod
    def emergency(self, robot: "Robot") -> None: ...

class IdleState(RobotState):
    def start(self, robot: "Robot") -> None:
        print("Starting...")
        robot.state = RunningState()

    def stop(self, robot: "Robot") -> None:
        print("Already stopped")

    def emergency(self, robot: "Robot") -> None:
        robot.state = EmergencyState()

class RunningState(RobotState):
    def start(self, robot: "Robot") -> None:
        print("Already running")

    def stop(self, robot: "Robot") -> None:
        print("Stopping...")
        robot.state = IdleState()

    def emergency(self, robot: "Robot") -> None:
        print("EMERGENCY STOP!")
        robot.state = EmergencyState()

class EmergencyState(RobotState):
    def start(self, robot: "Robot") -> None:
        print("Cannot start in emergency")

    def stop(self, robot: "Robot") -> None:
        print("Cannot stop in emergency")

    def emergency(self, robot: "Robot") -> None:
        print("Already in emergency")

class Robot:
    def __init__(self) -> None:
        self.state: RobotState = IdleState()

    def start(self) -> None:
        self.state.start(self)

    def stop(self) -> None:
        self.state.stop(self)

    def emergency(self) -> None:
        self.state.emergency(self)
```

---

## Template Method

**Purpose:** Define skeleton, let subclasses fill in steps.

**Use when:** Common algorithm structure with varying steps.

### Python

```python
from abc import ABC, abstractmethod

class ControlLoop(ABC):
    """Template method pattern for control loops."""

    def run_cycle(self) -> None:
        """Template method - defines the skeleton."""
        self.read_sensors()
        self.compute_control()
        self.apply_output()
        self.log_state()

    @abstractmethod
    def read_sensors(self) -> None: ...

    @abstractmethod
    def compute_control(self) -> None: ...

    @abstractmethod
    def apply_output(self) -> None: ...

    def log_state(self) -> None:
        """Default implementation - can be overridden."""
        pass

class JointController(ControlLoop):
    def read_sensors(self) -> None:
        self.position = self.encoder.read()

    def compute_control(self) -> None:
        self.torque = self.pid.compute(self.target - self.position)

    def apply_output(self) -> None:
        self.motor.set_torque(self.torque)
```

---

## Chain of Responsibility

**Purpose:** Pass requests along a chain of handlers.

**Use when:** Multiple handlers, unknown which will handle.

### Python

```python
from abc import ABC, abstractmethod

class Handler(ABC):
    def __init__(self) -> None:
        self._next: Handler | None = None

    def set_next(self, handler: "Handler") -> "Handler":
        self._next = handler
        return handler

    def handle(self, request: dict) -> str | None:
        result = self._handle(request)
        if result is None and self._next:
            return self._next.handle(request)
        return result

    @abstractmethod
    def _handle(self, request: dict) -> str | None: ...

class AuthHandler(Handler):
    def _handle(self, request: dict) -> str | None:
        if not request.get("authenticated"):
            return "Authentication required"
        return None

class PermissionHandler(Handler):
    def _handle(self, request: dict) -> str | None:
        if not request.get("has_permission"):
            return "Permission denied"
        return None

class ExecuteHandler(Handler):
    def _handle(self, request: dict) -> str | None:
        return "Executed successfully"

# Build chain
auth = AuthHandler()
auth.set_next(PermissionHandler()).set_next(ExecuteHandler())

result = auth.handle({"authenticated": True, "has_permission": True})
```

---

## Quick Reference

| Pattern | Use When | Key Benefit |
|---------|----------|-------------|
| **Strategy** | Swap algorithms | Runtime flexibility |
| **Observer** | Event notification | Loose coupling |
| **Command** | Undo/redo, queuing | Request encapsulation |
| **State** | State machines | Clean state transitions |
| **Template Method** | Common skeleton | Code reuse |
| **Chain of Responsibility** | Multiple handlers | Decoupled handling |

---

## Related Resources

- [design-patterns SKILL.md](../SKILL.md)
- [creational-patterns.md](creational-patterns.md)
- [structural-patterns.md](structural-patterns.md)
