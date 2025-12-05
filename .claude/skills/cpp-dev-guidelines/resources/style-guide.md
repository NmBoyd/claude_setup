# C++ Style Guide

## Table of Contents

- [Overview](#overview)
- [Severity Levels](#severity-levels)
- [A. TODO Comments, Temporary Code, and Debug Code](#a-todo-comments-temporary-code-and-debug-code)
- [B. std::string_view](#b-stdstring_view)
- [C. [[nodiscard]]](#c-nodiscard)
- [D. Include Statement Dividers](#d-include-statement-dividers)
- [E. Apollo YAML Configuration Files](#e-apollo-yaml-configuration-files)
- [F. assert vs static_assert](#f-assert-vs-static_assert)
- [G. Personal/Team Configuration Files](#g-personalteam-configuration-files)
- [H. Error Chaining with Tristate Operator](#h-error-chaining-with-tristate-operator)
- [Quick Reference](#quick-reference)
- [Related Resources](#related-resources)

---

## Overview

We follow the [Google C++ Style Guide](https://google.github.io/styleguide/cppguide.html) with the additional rules documented below.

---

## Severity Levels

| Level | Meaning |
|-------|---------|
| **DO NOT** | Never do this. Exemptions require tech lead approval. |
| **AVOID** | We prefer you not do this, but exceptions exist. |
| **CONSIDER** | We prefer you do this, but exceptions exist. |
| **DO** | Always do this. Exemptions require tech lead approval. |

---

## A. TODO Comments, Temporary Code, and Debug Code

We do mainline development—as soon as you merge, your code is live. Internal testers and coworkers are users. Treat all merges as "push to production."

### Dead Code

**DO** delete dead code.

Source control remembers the past. Do not:
- Include dead code in comments
- Hide it behind `#if 0`

```cpp
// ❌ NEVER: Commented out code
// int oldValue = calculateOld();

// ❌ NEVER: Hidden behind preprocessor
#if 0
int oldValue = calculateOld();
#endif

// ✅ ALWAYS: Delete it. Leave a SHA reference if needed.
// See git SHA abc123f for previous implementation
```

Dead code creates search hits that cause confusion. Delete it aggressively.

### TODO Comments

**DO** use TODO comments with Jira tickets.

Never leave a TODO without tracking. Format: `TODO(TICKET-ID)`

```cpp
// ✅ CORRECT: Tracked TODO
int number = 0; // TODO(SWC-123) Constant for now. Needs to be read from config.

// ❌ WRONG: Untracked TODO (linter will complain)
int number = 0; // TODO: fix this later
```

### Temporary Code

**AVOID** merging temporary code.

If you must merge temporary code, use `BEGIN`/`END` markers with a Jira ticket:

```cpp
// TODO(SWC-123) Remove this temporary code when we build a real timing delay system.
// BEGIN temporary code
static int counter = 0;
if (++counter < 3) return;
// END temporary code
```

### Debug Code

#### Level 1: `#ifdef DEBUG`

**DO** use `#ifdef DEBUG` for debug code that doesn't significantly slow execution.

```cpp
err = err ? err : rtc.Init();
#ifdef DEBUG
std::cout << "RTC Initialized" << std::endl;
#endif
err = err ? err : rtc.Execute();
```

#### Level 2: `#if 0` Blocks (Sparse Use)

For debug code useful sometimes but not always (e.g., startup delays). Use **very sparingly**. Do not use to comment out code.

```cpp
#if 0 // NOLINT(readability-avoid-unconditional-preprocessor-if)
// Change 0 to 1 to enable this block. Pauses program for debugger attachment.
std::cout << "Type any non-empty string then ENTER to continue: ";
std::string junk;
std::cin >> junk;
UNUSED(junk);
#endif // 0
```

#### Level 3: Feature-Level Debug Code

For expensive debug features scattered across the codebase (e.g., graphical timeline analyzers):

```cpp
// In header or common location
#define DEBUG_SEQUENCE_DIAGRAM 0

// Throughout codebase
#if DEBUG_SEQUENCE_DIAGRAM
analyzer.RecordEvent(event);
#endif
```

Merge with value `0`. Developers enable locally as needed.

---

## B. std::string_view

**AVOID** `std::string_view` without tech lead approval.

We should use `std::string_view` more, but there are gotchas. Talk to a tech lead before adding any to the codebase.

### The Problem

Using `std::string_view` for constants because it's `constexpr` seems good, but:

```cpp
// ❌ BAD: Creates temporary string every time passed to const std::string&
static constexpr std::string_view kName = "robot";

void Process(const std::string& name);
Process(kName); // Constructs temporary std::string each call!

// ✅ GOOD: For final constants used by other code
static const std::string kName = "robot";

// ✅ ACCEPTABLE: For intermediate parts used to build strings at compile time
static constexpr std::string_view kPrefix = "robot_";
static constexpr std::string_view kSuffix = "_v2";
static const std::string kFullName = std::string(kPrefix) + "arm" + std::string(kSuffix);
```

---

## C. `[[nodiscard]]`

**DO** use `[[nodiscard]]` for all functions returning `std::error_code`.

```cpp
// ✅ REQUIRED: Compiler fails if return value ignored
[[nodiscard]] std::error_code Initialize();
[[nodiscard]] std::error_code Execute();

// Usage - compiler enforces checking
auto err = Initialize(); // ✅ OK
Initialize();            // ❌ Compiler error
```

**CONSIDER** using `[[nodiscard]]` for other return values.

Most return values are intended to be used. Forgetting to use them is generally a bug. However, it adds noise, so we don't require it everywhere.

```cpp
// Consider for important returns
[[nodiscard]] std::optional<Config> LoadConfig();
[[nodiscard]] bool IsValid() const;
```

---

## D. Include Statement Dividers

**DO** use standard divider comments for `#include` statements.

All `.h` and `.cc` files must organize includes with these section dividers:

```cpp
// System
#include <memory>
#include <string>
#include <vector>

// 3rdPartyLibs
#include <eigen3/Eigen/Core>
#include <spdlog/spdlog.h>

// Atk
#include "atk/core/error.h"
#include "atk/math/transform.h"

// Art
#include "art/control/controller.h"
#include "art/sensors/imu.h"
```

**Include all four dividers even if sections are empty**—this documents that you believe you have no dependencies of that kind:

```cpp
// System
#include <string>

// 3rdPartyLibs

// Atk
#include "atk/core/error.h"

// Art
```

These dividers keep includes organized when using `Ctrl+Shift+I` to autoformat.

---

## E. Apollo YAML Configuration Files

**DO NOT** divide `apollo.yaml` files into segments or create shared include files.

The `*.apollo.yaml` files define runtime robot configuration. Each application loads exactly one file:
- Apollo2: One each for NIO, APP, and RTC
- ApolloNXG: One file for the whole computer

### Why No Shared Files?

You may be tempted to:
- Create parallel lists with only settings you care about
- Create an `#include` system so one edit updates all configurations

**DO NOT** do these things.

When changing a field, you must change it in each configuration. This forces consideration of each configuration.

### Background

NASA and SpaceX studied this extensively. Far fewer bugs were introduced by having people consider each configuration compared to bugs where someone forgot to update a given configuration.

When a common section is extracted, changes to that section tend to only consider the cases the developer cares about—not all affected configurations.

---

## F. `assert` vs `static_assert`

**DO NOT** use `assert`.

```cpp
// ❌ NEVER: Runtime assert can terminate the application
assert(joint_angle >= 0);

// ✅ ALWAYS: Return error code
if (joint_angle < 0) {
    return make_error_code(ErrorCode::InvalidJointAngle);
}

// ✅ ALWAYS: Raise a fault for system response
if (joint_angle < 0) {
    fault_manager.Raise(FaultCode::InvalidJointAngle);
    return;
}
```

### Why?

If our walking robot falls over, that's bad—it breaks. We cannot claim any safety system will execute if a minor subsystem can terminate the application at any moment.

`assert` is a runtime threat. Instead:
- Return `std::error_code` to caller
- Raise a fault for the system to respond to

**`static_assert` is fine**—those are checked at compile time:

```cpp
// ✅ OK: Compile-time check
static_assert(sizeof(JointState) == 32, "JointState size changed");
```

---

## G. Personal/Team Configuration Files

**CONSIDER** storing personal/team debug and development `apollo.yaml` files in the repo.

Benefits:
- Makes specialized configs available to others
- Protects you from breaking changes—your file will be visited when configs change
- If a feature you use gets cut, you'll be consulted first

```
config/
├── apollo_production.yaml
├── apollo_test.yaml
├── apollo_dev_stephen.yaml     # Personal debug config
└── apollo_dev_perception.yaml  # Team config
```

---

## H. Error Chaining with Tristate Operator

**CONSIDER** using the tristate (`? :`) operator for error chaining.

```cpp
// ✅ RECOMMENDED: Tristate chaining
std::error_code err = foo();
err = err ? err : bar();
err = err ? err : baz();
return err;

// Also acceptable: Early return pattern
if (auto err = foo()) return err;
if (auto err = bar()) return err;
if (auto err = baz()) return err;
return {};

// Also acceptable: Explicit if-else
std::error_code err = foo();
if (!err) {
    err = bar();
}
if (!err) {
    err = baz();
}
return err;
```

The tristate pattern is concise and shows the sequence clearly. Use what is right for your code.

---

## Quick Reference

| Rule | Level | Summary |
|------|-------|---------|
| Delete dead code | **DO** | Don't comment out or `#if 0` |
| TODO with Jira ticket | **DO** | `TODO(SWC-123)` format |
| Temporary code markers | **AVOID** | Use `BEGIN`/`END` if you must |
| `std::string_view` | **AVOID** | Talk to tech lead first |
| `[[nodiscard]]` on `error_code` | **DO** | Always |
| Include dividers | **DO** | System/3rdPartyLibs/Atk/Art |
| Split apollo.yaml | **DO NOT** | No shared includes |
| `assert` | **DO NOT** | Use error codes or faults |
| `static_assert` | OK | Compile-time checks are fine |
| Personal config in repo | **CONSIDER** | Protects against breaking changes |
| Tristate error chaining | **CONSIDER** | `err = err ? err : func()` |

---

## Related Resources

- [Google C++ Style Guide](https://google.github.io/styleguide/cppguide.html)
- [cpp-dev-guidelines SKILL.md](../SKILL.md) - Main C++ skill
- [memory-management.md](memory-management.md) - Smart pointers and RAII
- [cmake-guide.md](cmake-guide.md) - Build system patterns