# Creational Design Patterns

Patterns that deal with object creation mechanisms.

---

## Factory Method

**Purpose:** Create objects without specifying the exact class.

**Use when:**
- You don't know ahead of time which class you need
- You want to delegate creation to subclasses
- You need a plugin system

### Python

```python
from abc import ABC, abstractmethod

class Controller(ABC):
    @abstractmethod
    def execute(self) -> None: ...

class JointController(Controller):
    def execute(self) -> None:
        print("Executing joint control")

class CartesianController(Controller):
    def execute(self) -> None:
        print("Executing cartesian control")

class ControllerFactory:
    """Factory for creating controllers."""

    _controllers: dict[str, type[Controller]] = {
        "joint": JointController,
        "cartesian": CartesianController,
    }

    @classmethod
    def create(cls, controller_type: str) -> Controller:
        if controller_type not in cls._controllers:
            raise ValueError(f"Unknown controller: {controller_type}")
        return cls._controllers[controller_type]()

    @classmethod
    def register(cls, name: str, controller_class: type[Controller]) -> None:
        """Register a new controller type."""
        cls._controllers[name] = controller_class

# Usage
controller = ControllerFactory.create("joint")
```

### C++

```cpp
#include <memory>
#include <string>
#include <unordered_map>
#include <functional>

class Controller {
public:
    virtual ~Controller() = default;
    virtual void Execute() = 0;
};

class JointController : public Controller {
public:
    void Execute() override { /* joint control */ }
};

class CartesianController : public Controller {
public:
    void Execute() override { /* cartesian control */ }
};

class ControllerFactory {
public:
    using Creator = std::function<std::unique_ptr<Controller>()>;

    static std::unique_ptr<Controller> Create(const std::string& type) {
        auto it = creators_.find(type);
        if (it == creators_.end()) {
            throw std::invalid_argument("Unknown controller: " + type);
        }
        return it->second();
    }

    static void Register(const std::string& name, Creator creator) {
        creators_[name] = std::move(creator);
    }

private:
    static inline std::unordered_map<std::string, Creator> creators_ = {
        {"joint", []() { return std::make_unique<JointController>(); }},
        {"cartesian", []() { return std::make_unique<CartesianController>(); }},
    };
};

// Usage
auto controller = ControllerFactory::Create("joint");
```

---

## Builder

**Purpose:** Construct complex objects step by step.

**Use when:**
- Object has many optional parameters
- Construction requires multiple steps
- You want readable object creation

### Python

```python
from dataclasses import dataclass

@dataclass
class RobotConfig:
    name: str
    joint_count: int
    max_velocity: float = 1.0
    max_acceleration: float = 2.0
    enable_collision: bool = True
    log_level: str = "INFO"

class RobotConfigBuilder:
    """Builder for RobotConfig with fluent interface."""

    def __init__(self, name: str, joint_count: int) -> None:
        self._name = name
        self._joint_count = joint_count
        self._max_velocity = 1.0
        self._max_acceleration = 2.0
        self._enable_collision = True
        self._log_level = "INFO"

    def with_velocity(self, velocity: float) -> "RobotConfigBuilder":
        self._max_velocity = velocity
        return self

    def with_acceleration(self, accel: float) -> "RobotConfigBuilder":
        self._max_acceleration = accel
        return self

    def with_collision(self, enabled: bool) -> "RobotConfigBuilder":
        self._enable_collision = enabled
        return self

    def with_log_level(self, level: str) -> "RobotConfigBuilder":
        self._log_level = level
        return self

    def build(self) -> RobotConfig:
        return RobotConfig(
            name=self._name,
            joint_count=self._joint_count,
            max_velocity=self._max_velocity,
            max_acceleration=self._max_acceleration,
            enable_collision=self._enable_collision,
            log_level=self._log_level,
        )

# Usage - readable and self-documenting
config = (
    RobotConfigBuilder("Apollo", joint_count=7)
    .with_velocity(2.0)
    .with_collision(False)
    .build()
)
```

### C++

```cpp
class RobotConfig {
public:
    class Builder;

    std::string name;
    int joint_count;
    double max_velocity = 1.0;
    double max_acceleration = 2.0;
    bool enable_collision = true;

private:
    RobotConfig() = default;
    friend class Builder;
};

class RobotConfig::Builder {
public:
    Builder(std::string name, int joints) : config_{} {
        config_.name = std::move(name);
        config_.joint_count = joints;
    }

    Builder& WithVelocity(double v) { config_.max_velocity = v; return *this; }
    Builder& WithAcceleration(double a) { config_.max_acceleration = a; return *this; }
    Builder& WithCollision(bool c) { config_.enable_collision = c; return *this; }

    [[nodiscard]] RobotConfig Build() { return config_; }

private:
    RobotConfig config_;
};

// Usage
auto config = RobotConfig::Builder("Apollo", 7)
    .WithVelocity(2.0)
    .WithCollision(false)
    .Build();
```

---

## Singleton (Use Sparingly!)

**Purpose:** Ensure exactly one instance exists.

**Use when:**
- Hardware interface that must be unique
- Global configuration
- Resource pools

**Warning:** Singletons make testing difficult and hide dependencies. Prefer dependency injection.

### Python

```python
class HardwareInterface:
    """Singleton for hardware access."""

    _instance: "HardwareInterface | None" = None

    def __new__(cls) -> "HardwareInterface":
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance._initialized = False
        return cls._instance

    def __init__(self) -> None:
        if self._initialized:
            return
        self._initialized = True
        # Actual initialization here

# Better alternative: Module-level instance
_hardware: HardwareInterface | None = None

def get_hardware() -> HardwareInterface:
    global _hardware
    if _hardware is None:
        _hardware = HardwareInterface()
    return _hardware
```

### C++

```cpp
class HardwareInterface {
public:
    static HardwareInterface& Instance() {
        static HardwareInterface instance;  // Thread-safe in C++11+
        return instance;
    }

    // Delete copy/move
    HardwareInterface(const HardwareInterface&) = delete;
    HardwareInterface& operator=(const HardwareInterface&) = delete;

private:
    HardwareInterface() = default;
};

// Usage
auto& hw = HardwareInterface::Instance();
```

---

## Abstract Factory

**Purpose:** Create families of related objects.

**Use when:**
- System needs to be independent of how products are created
- System needs to work with multiple families of products

### Python

```python
from abc import ABC, abstractmethod

class Motor(ABC):
    @abstractmethod
    def move(self, position: float) -> None: ...

class Sensor(ABC):
    @abstractmethod
    def read(self) -> float: ...

# Concrete products for simulation
class SimMotor(Motor):
    def move(self, position: float) -> None:
        print(f"Sim motor moving to {position}")

class SimSensor(Sensor):
    def read(self) -> float:
        return 0.0

# Concrete products for hardware
class HardwareMotor(Motor):
    def move(self, position: float) -> None:
        # Real hardware call
        ...

class HardwareSensor(Sensor):
    def read(self) -> float:
        # Real hardware call
        ...

# Abstract factory
class HardwareFactory(ABC):
    @abstractmethod
    def create_motor(self) -> Motor: ...
    @abstractmethod
    def create_sensor(self) -> Sensor: ...

class SimulationFactory(HardwareFactory):
    def create_motor(self) -> Motor:
        return SimMotor()
    def create_sensor(self) -> Sensor:
        return SimSensor()

class RealHardwareFactory(HardwareFactory):
    def create_motor(self) -> Motor:
        return HardwareMotor()
    def create_sensor(self) -> Sensor:
        return HardwareSensor()

# Usage - swap entire hardware family
def create_robot(factory: HardwareFactory):
    motor = factory.create_motor()
    sensor = factory.create_sensor()
    return Robot(motor, sensor)

robot = create_robot(SimulationFactory())  # For testing
robot = create_robot(RealHardwareFactory())  # For production
```

---

## Prototype

**Purpose:** Clone existing objects.

**Use when:**
- Creating objects is expensive
- Objects have complex initialization
- You need copies with slight variations

### Python

```python
import copy
from dataclasses import dataclass, field

@dataclass
class RobotState:
    joint_positions: list[float] = field(default_factory=list)
    joint_velocities: list[float] = field(default_factory=list)
    timestamp: float = 0.0

    def clone(self) -> "RobotState":
        """Create a deep copy."""
        return copy.deepcopy(self)

# Usage
original = RobotState(
    joint_positions=[0.1, 0.2, 0.3],
    joint_velocities=[0.0, 0.0, 0.0],
    timestamp=1.0
)

# Clone and modify
modified = original.clone()
modified.joint_positions[0] = 0.5
modified.timestamp = 2.0
```

### C++

```cpp
class RobotState {
public:
    std::vector<double> joint_positions;
    std::vector<double> joint_velocities;
    double timestamp = 0.0;

    // Prototype clone method
    [[nodiscard]] std::unique_ptr<RobotState> Clone() const {
        return std::make_unique<RobotState>(*this);
    }
};

// Usage
auto original = std::make_unique<RobotState>();
original->joint_positions = {0.1, 0.2, 0.3};

auto modified = original->Clone();
modified->joint_positions[0] = 0.5;
```

---

## Quick Reference

| Pattern | Use When | Key Benefit |
|---------|----------|-------------|
| **Factory** | Don't know exact class at compile time | Decouples creation |
| **Builder** | Complex object, many parameters | Readable construction |
| **Singleton** | Exactly one instance needed | Global access (use sparingly!) |
| **Abstract Factory** | Families of related objects | Swap product families |
| **Prototype** | Cloning is cheaper than creating | Efficient copying |

---

## Related Resources

- [design-patterns SKILL.md](../SKILL.md)
- [structural-patterns.md](structural-patterns.md)
- [behavioral-patterns.md](behavioral-patterns.md)
