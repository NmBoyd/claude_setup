# C++ Idioms Guide

## Overview

Essential C++ idioms for writing robust, maintainable, and efficient code. These patterns solve common problems and represent accumulated wisdom from the C++ community.

Reference: [More C++ Idioms](https://en.wikibooks.org/wiki/More_C%2B%2B_Idioms)

---

## Quick Reference

| Idiom | Purpose | Use When |
|-------|---------|----------|
| **RAII** | Resource management | Always for resources |
| **PIMPL** | ABI stability, compile time | Public APIs, large headers |
| **CRTP** | Static polymorphism | Avoiding virtual dispatch |
| **Copy-and-Swap** | Exception-safe assignment | Custom resource classes |
| **SFINAE** | Conditional compilation | Template constraints |
| **Tag Dispatch** | Overload selection | Algorithm variants |
| **Type Erasure** | Runtime polymorphism without inheritance | Generic containers |
| **NVI** | Control interface extension | Framework classes |

---

## RAII (Resource Acquisition Is Initialization)

**Purpose:** Tie resource lifetime to object lifetime for automatic cleanup.

**Use when:** Managing any resource (memory, files, locks, connections).

```cpp
// ✅ RAII wrapper for file handle
class FileHandle {
public:
    explicit FileHandle(const std::string& path)
        : handle_(std::fopen(path.c_str(), "r")) {
        if (!handle_) {
            throw std::runtime_error("Failed to open file");
        }
    }

    ~FileHandle() {
        if (handle_) {
            std::fclose(handle_);
        }
    }

    // Non-copyable, movable
    FileHandle(const FileHandle&) = delete;
    FileHandle& operator=(const FileHandle&) = delete;

    FileHandle(FileHandle&& other) noexcept
        : handle_(std::exchange(other.handle_, nullptr)) {}

    FileHandle& operator=(FileHandle&& other) noexcept {
        if (this != &other) {
            if (handle_) std::fclose(handle_);
            handle_ = std::exchange(other.handle_, nullptr);
        }
        return *this;
    }

    FILE* get() const { return handle_; }

private:
    FILE* handle_;
};

// ✅ RAII lock guard
class ScopedLock {
public:
    explicit ScopedLock(std::mutex& mtx) : mutex_(mtx) {
        mutex_.lock();
    }
    ~ScopedLock() {
        mutex_.unlock();
    }

    ScopedLock(const ScopedLock&) = delete;
    ScopedLock& operator=(const ScopedLock&) = delete;

private:
    std::mutex& mutex_;
};

// Usage - resources automatically cleaned up
void process() {
    FileHandle file("data.txt");
    ScopedLock lock(mutex_);
    // ... use file and lock
}  // Automatic cleanup, even on exception
```

---

## PIMPL (Pointer to Implementation)

**Purpose:** Hide implementation details, reduce compile dependencies, maintain ABI stability.

**Use when:** Public APIs, large header dependencies, need ABI stability.

```cpp
// widget.hpp - Public header (minimal includes)
#pragma once
#include <memory>
#include <string>

class Widget {
public:
    Widget();
    ~Widget();

    // Move operations
    Widget(Widget&&) noexcept;
    Widget& operator=(Widget&&) noexcept;

    // Public interface
    void DoSomething();
    [[nodiscard]] std::string GetName() const;

private:
    class Impl;  // Forward declaration only
    std::unique_ptr<Impl> pimpl_;
};

// widget.cpp - Implementation (heavy includes here)
#include "widget.hpp"
#include <vector>
#include <map>
#include <heavy_dependency.hpp>  // Only needed in .cpp

class Widget::Impl {
public:
    void DoSomething() {
        // Complex implementation using heavy dependencies
    }

    std::string GetName() const { return name_; }

private:
    std::string name_;
    std::vector<int> data_;
    std::map<std::string, int> cache_;
    HeavyDependency heavy_;  // Users don't need this header
};

Widget::Widget() : pimpl_(std::make_unique<Impl>()) {}
Widget::~Widget() = default;
Widget::Widget(Widget&&) noexcept = default;
Widget& Widget::operator=(Widget&&) noexcept = default;

void Widget::DoSomething() { pimpl_->DoSomething(); }
std::string Widget::GetName() const { return pimpl_->GetName(); }
```

**Benefits:**
- Changing `Impl` doesn't require recompiling users
- Faster compilation (fewer header dependencies)
- ABI stability for shared libraries

---

## CRTP (Curiously Recurring Template Pattern)

**Purpose:** Static polymorphism without virtual function overhead.

**Use when:** Performance-critical code, mixin functionality, static interfaces.

```cpp
// Base template that uses derived class
template <typename Derived>
class Controller {
public:
    void Execute() {
        // Static dispatch - no virtual call
        static_cast<Derived*>(this)->ExecuteImpl();
    }

    void Initialize() {
        static_cast<Derived*>(this)->InitializeImpl();
    }

    // Default implementation (can be overridden)
    void InitializeImpl() {
        // Default behavior
    }
};

// Derived class passes itself as template argument
class JointController : public Controller<JointController> {
public:
    void ExecuteImpl() {
        // Joint-specific execution
    }

    void InitializeImpl() {
        // Override default initialization
    }
};

class CartesianController : public Controller<CartesianController> {
public:
    void ExecuteImpl() {
        // Cartesian-specific execution
    }
    // Uses default InitializeImpl()
};

// Usage - no virtual dispatch overhead
template <typename T>
void RunController(Controller<T>& ctrl) {
    ctrl.Initialize();
    ctrl.Execute();
}

JointController joint;
RunController(joint);  // Static dispatch
```

**CRTP for Mixins:**
```cpp
// Counter mixin using CRTP
template <typename Derived>
class Countable {
public:
    static int GetCount() { return count_; }

protected:
    Countable() { ++count_; }
    ~Countable() { --count_; }

private:
    static inline int count_ = 0;
};

class Robot : public Countable<Robot> {
    // Automatically counted
};

class Sensor : public Countable<Sensor> {
    // Separately counted
};

// Each derived class has its own counter
Robot r1, r2;
Sensor s1;
Robot::GetCount();   // 2
Sensor::GetCount();  // 1
```

---

## Copy-and-Swap Idiom

**Purpose:** Exception-safe copy assignment operator.

**Use when:** Classes managing resources that need copy semantics.

```cpp
class Buffer {
public:
    explicit Buffer(size_t size)
        : size_(size)
        , data_(new int[size]) {}

    ~Buffer() {
        delete[] data_;
    }

    // Copy constructor
    Buffer(const Buffer& other)
        : size_(other.size_)
        , data_(new int[other.size_]) {
        std::copy(other.data_, other.data_ + size_, data_);
    }

    // Move constructor
    Buffer(Buffer&& other) noexcept
        : size_(other.size_)
        , data_(other.data_) {
        other.size_ = 0;
        other.data_ = nullptr;
    }

    // Unified assignment using copy-and-swap
    Buffer& operator=(Buffer other) noexcept {  // Pass by value!
        swap(*this, other);
        return *this;
    }

    // Friend swap for ADL
    friend void swap(Buffer& a, Buffer& b) noexcept {
        using std::swap;
        swap(a.size_, b.size_);
        swap(a.data_, b.data_);
    }

private:
    size_t size_;
    int* data_;
};

// Usage
Buffer b1(100);
Buffer b2(200);
b1 = b2;              // Copy assignment (copy made, then swapped)
b1 = std::move(b2);   // Move assignment (move made, then swapped)
```

**Why it works:**
1. Parameter is passed by value (copy/move happens here)
2. Swap is noexcept (cannot fail)
3. Old resources destroyed when parameter goes out of scope
4. Strong exception guarantee

---

## SFINAE (Substitution Failure Is Not An Error)

**Purpose:** Enable/disable template overloads based on type properties.

**Use when:** Conditional template instantiation, type constraints.

```cpp
#include <type_traits>

// Enable only for integral types
template <typename T>
typename std::enable_if<std::is_integral<T>::value, T>::type
Process(T value) {
    return value * 2;
}

// Enable only for floating-point types
template <typename T>
typename std::enable_if<std::is_floating_point<T>::value, T>::type
Process(T value) {
    return value * 2.5;
}

// C++17: More readable with if constexpr
template <typename T>
T ProcessModern(T value) {
    if constexpr (std::is_integral_v<T>) {
        return value * 2;
    } else if constexpr (std::is_floating_point_v<T>) {
        return value * 2.5;
    } else {
        static_assert(false, "Unsupported type");
    }
}

// C++20: Use concepts instead (preferred)
template <std::integral T>
T ProcessConcept(T value) {
    return value * 2;
}

template <std::floating_point T>
T ProcessConcept(T value) {
    return value * 2.5;
}

// Detect if type has a method
template <typename T, typename = void>
struct HasExecute : std::false_type {};

template <typename T>
struct HasExecute<T, std::void_t<decltype(std::declval<T>().Execute())>>
    : std::true_type {};

template <typename T>
void MaybeExecute(T& obj) {
    if constexpr (HasExecute<T>::value) {
        obj.Execute();
    }
}
```

---

## Tag Dispatch

**Purpose:** Select function overloads based on type traits at compile time.

**Use when:** Algorithm variants, iterator categories, optimization paths.

```cpp
#include <iterator>

namespace detail {
    // Tag types
    struct FastPath {};
    struct SlowPath {};

    template <typename Iter>
    void AdvanceImpl(Iter& it, int n, std::random_access_iterator_tag) {
        it += n;  // O(1)
    }

    template <typename Iter>
    void AdvanceImpl(Iter& it, int n, std::input_iterator_tag) {
        while (n-- > 0) ++it;  // O(n)
    }
}

template <typename Iter>
void Advance(Iter& it, int n) {
    // Dispatch based on iterator category
    detail::AdvanceImpl(it, n,
        typename std::iterator_traits<Iter>::iterator_category{});
}

// Custom tag dispatch for algorithms
namespace detail {
    template <typename T>
    void SerializeImpl(const T& obj, FastPath) {
        // Use memcpy for trivially copyable types
        std::memcpy(buffer, &obj, sizeof(T));
    }

    template <typename T>
    void SerializeImpl(const T& obj, SlowPath) {
        // Use member-by-member serialization
        obj.Serialize(buffer);
    }
}

template <typename T>
void Serialize(const T& obj) {
    using Tag = std::conditional_t<
        std::is_trivially_copyable_v<T>,
        detail::FastPath,
        detail::SlowPath
    >;
    detail::SerializeImpl(obj, Tag{});
}
```

---

## Type Erasure

**Purpose:** Store objects of different types with common interface without inheritance.

**Use when:** Generic containers, callbacks, avoiding template proliferation.

```cpp
#include <memory>
#include <functional>

// Type-erased callable (simplified std::function)
class Task {
public:
    template <typename F>
    Task(F&& func)
        : impl_(std::make_unique<Model<F>>(std::forward<F>(func))) {}

    void operator()() {
        impl_->Call();
    }

private:
    // Concept (interface)
    struct Concept {
        virtual ~Concept() = default;
        virtual void Call() = 0;
    };

    // Model (implementation for specific type)
    template <typename F>
    struct Model : Concept {
        F func_;
        explicit Model(F&& f) : func_(std::forward<F>(f)) {}
        void Call() override { func_(); }
    };

    std::unique_ptr<Concept> impl_;
};

// Type-erased shape (classic example)
class Shape {
public:
    template <typename T>
    Shape(T shape)
        : impl_(std::make_shared<Model<T>>(std::move(shape))) {}

    void Draw() const { impl_->Draw(); }
    double Area() const { return impl_->Area(); }

private:
    struct Concept {
        virtual ~Concept() = default;
        virtual void Draw() const = 0;
        virtual double Area() const = 0;
    };

    template <typename T>
    struct Model : Concept {
        T shape_;
        explicit Model(T s) : shape_(std::move(s)) {}
        void Draw() const override { shape_.Draw(); }
        double Area() const override { return shape_.Area(); }
    };

    std::shared_ptr<const Concept> impl_;
};

// Any shape with Draw() and Area() works - no inheritance required
struct Circle {
    double radius;
    void Draw() const { /* ... */ }
    double Area() const { return 3.14159 * radius * radius; }
};

struct Rectangle {
    double width, height;
    void Draw() const { /* ... */ }
    double Area() const { return width * height; }
};

// Usage
std::vector<Shape> shapes;
shapes.push_back(Circle{5.0});
shapes.push_back(Rectangle{3.0, 4.0});

for (const auto& s : shapes) {
    s.Draw();
}
```

---

## NVI (Non-Virtual Interface)

**Purpose:** Control how derived classes extend functionality.

**Use when:** Framework classes, enforcing pre/post conditions.

```cpp
class Controller {
public:
    // Public non-virtual interface
    void Execute() {
        PreExecute();      // Framework code
        DoExecute();       // Customization point
        PostExecute();     // Framework code
    }

    void Initialize() {
        ValidateConfig();  // Framework code
        DoInitialize();    // Customization point
        LogInitialized();  // Framework code
    }

    virtual ~Controller() = default;

private:
    // Private virtual functions - customization points
    virtual void DoExecute() = 0;
    virtual void DoInitialize() = 0;

    // Non-virtual framework code
    void PreExecute() {
        // Logging, timing, safety checks
    }

    void PostExecute() {
        // Cleanup, metrics
    }

    void ValidateConfig() {
        // Check configuration
    }

    void LogInitialized() {
        // Log initialization complete
    }
};

class JointController : public Controller {
private:
    // Only override the customization points
    void DoExecute() override {
        // Joint-specific logic
    }

    void DoInitialize() override {
        // Joint-specific initialization
    }
};
```

**Benefits:**
- Framework controls pre/post conditions
- Derived classes can't bypass framework code
- Clear separation of interface and customization

---

## Attorney-Client Idiom

**Purpose:** Grant selective private access to specific classes.

**Use when:** Need fine-grained friend access without exposing everything.

```cpp
class SecretData {
public:
    void PublicMethod() { /* ... */ }

private:
    void PrivateMethod() { /* ... */ }
    int secret_value_ = 42;

    // Attorney has access, grants selective access to clients
    friend class SecretDataAttorney;
};

class SecretDataAttorney {
private:
    // Only TrustedClient can use these
    static void CallPrivateMethod(SecretData& data) {
        data.PrivateMethod();
    }

    static int GetSecretValue(const SecretData& data) {
        return data.secret_value_;
    }

    friend class TrustedClient;
};

class TrustedClient {
public:
    void DoWork(SecretData& data) {
        // Can access private members through attorney
        SecretDataAttorney::CallPrivateMethod(data);
        int val = SecretDataAttorney::GetSecretValue(data);
    }
};

class UntrustedClient {
public:
    void DoWork(SecretData& data) {
        data.PublicMethod();  // OK
        // SecretDataAttorney::CallPrivateMethod(data);  // Error!
    }
};
```

---

## Quick Reference Table

| Idiom | Problem Solved | Key Benefit |
|-------|----------------|-------------|
| RAII | Resource leaks | Automatic cleanup |
| PIMPL | Compile coupling | ABI stability |
| CRTP | Virtual overhead | Static polymorphism |
| Copy-and-Swap | Exception safety | Strong guarantee |
| SFINAE | Conditional compilation | Type-based dispatch |
| Tag Dispatch | Algorithm selection | Compile-time choice |
| Type Erasure | Storing heterogeneous types | No inheritance needed |
| NVI | Extension control | Framework enforcement |
| Attorney-Client | Selective access | Fine-grained friends |

---

## Related Resources

- [More C++ Idioms](https://en.wikibooks.org/wiki/More_C%2B%2B_Idioms)
- [cpp-dev-guidelines SKILL.md](../SKILL.md) - Main C++ skill
- [style-guide.md](style-guide.md) - C++ style guide
- [design-patterns](../../shared/design-patterns/SKILL.md) - Design patterns
