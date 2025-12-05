# Structural Design Patterns

Patterns that deal with object composition and relationships.

---

## Adapter

**Purpose:** Make incompatible interfaces work together.

**Use when:** Integrating third-party libraries, working with legacy code.

### Python

```python
from typing import Protocol

class PositionSensor(Protocol):
    def get_position(self) -> float: ...

class LegacyEncoder:
    def read_counts(self) -> int:
        return 12345

class EncoderAdapter:
    def __init__(self, encoder: LegacyEncoder, counts_per_rad: float) -> None:
        self._encoder = encoder
        self._counts_per_rad = counts_per_rad

    def get_position(self) -> float:
        return self._encoder.read_counts() / self._counts_per_rad

# Usage
adapter = EncoderAdapter(LegacyEncoder(), counts_per_rad=1000.0)
```

---

## Decorator

**Purpose:** Add behavior without modifying existing classes.

**Use when:** Adding logging, caching, validation, retry logic.

### Python

```python
from functools import wraps
import time
import logging

logger = logging.getLogger(__name__)

def timing(func):
    @wraps(func)
    def wrapper(*args, **kwargs):
        start = time.perf_counter()
        result = func(*args, **kwargs)
        logger.debug("%s took %.3fs", func.__name__, time.perf_counter() - start)
        return result
    return wrapper

def retry(max_attempts: int = 3):
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            for attempt in range(max_attempts):
                try:
                    return func(*args, **kwargs)
                except Exception as e:
                    if attempt == max_attempts - 1:
                        raise
                    time.sleep(1.0)
        return wrapper
    return decorator

@timing
@retry(max_attempts=3)
def send_command(joint_id: int, position: float) -> bool:
    ...
```

---

## Facade

**Purpose:** Provide a simple interface to a complex subsystem.

**Use when:** Simplifying complex library usage, creating unified APIs.

### Python

```python
class RobotFacade:
    def __init__(self) -> None:
        self._motion = MotionPlanner()
        self._collision = CollisionChecker()
        self._controller = JointController()
        self._safety = SafetyMonitor()

    def move_to(self, target: Pose) -> bool:
        if not self._safety.is_safe():
            return False
        trajectory = self._motion.plan(target)
        if trajectory is None or self._collision.check(trajectory):
            return False
        return self._controller.execute(trajectory)

# Usage - simple interface
robot = RobotFacade()
robot.move_to(target_pose)
```

---

## Composite

**Purpose:** Treat individual objects and compositions uniformly.

**Use when:** Tree structures, part-whole hierarchies.

### Python

```python
from abc import ABC, abstractmethod

class Component(ABC):
    @abstractmethod
    def get_mass(self) -> float: ...

class Joint(Component):
    def __init__(self, name: str, mass: float) -> None:
        self.name = name
        self.mass = mass

    def get_mass(self) -> float:
        return self.mass

class Link(Component):
    def __init__(self, name: str, own_mass: float) -> None:
        self.name = name
        self.own_mass = own_mass
        self.children: list[Component] = []

    def add(self, component: Component) -> None:
        self.children.append(component)

    def get_mass(self) -> float:
        return self.own_mass + sum(c.get_mass() for c in self.children)

# Usage
arm = Link("arm", own_mass=5.0)
arm.add(Joint("shoulder", mass=2.0))
arm.add(Joint("elbow", mass=1.5))
total = arm.get_mass()
```

---

## Proxy

**Purpose:** Control access to an object.

**Use when:** Lazy initialization, access control, caching.

### Python

```python
class HeavyResource:
    def __init__(self) -> None:
        time.sleep(2)  # Expensive

    def process(self) -> str:
        return "Processed!"

class LazyProxy:
    def __init__(self) -> None:
        self._resource: HeavyResource | None = None

    def process(self) -> str:
        if self._resource is None:
            self._resource = HeavyResource()
        return self._resource.process()
```

---

## Bridge

**Purpose:** Separate abstraction from implementation.

**Use when:** Multiple orthogonal dimensions of variation.

### Python

```python
from abc import ABC, abstractmethod

class MotorDriver(ABC):
    @abstractmethod
    def set_position(self, pos: float) -> None: ...

class CANDriver(MotorDriver):
    def set_position(self, pos: float) -> None:
        print(f"CAN: {pos}")

class EtherCATDriver(MotorDriver):
    def set_position(self, pos: float) -> None:
        print(f"EtherCAT: {pos}")

class Joint(ABC):
    def __init__(self, driver: MotorDriver) -> None:
        self._driver = driver

class RevoluteJoint(Joint):
    def move_to(self, position: float) -> None:
        self._driver.set_position(position)

# Mix and match
joint1 = RevoluteJoint(CANDriver())
joint2 = RevoluteJoint(EtherCATDriver())
```

---

## Quick Reference

| Pattern | Use When | Key Benefit |
|---------|----------|-------------|
| **Adapter** | Incompatible interfaces | Integration |
| **Decorator** | Add behavior dynamically | Runtime extension |
| **Facade** | Complex subsystem | Simplified API |
| **Composite** | Tree structures | Uniform treatment |
| **Proxy** | Control access | Lazy init, caching |
| **Bridge** | Multiple dimensions | Decouple abstraction/impl |

---

## Related Resources

- [design-patterns SKILL.md](../SKILL.md)
- [creational-patterns.md](creational-patterns.md)
- [behavioral-patterns.md](behavioral-patterns.md)
