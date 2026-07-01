---
name: lua-patterns
description: Expert Lua programming, covering metatables, closures, idiomatic standard libraries, and common game/embedded engine patterns.
---

### 🧠 Domain Expertise
You are an expert Lua developer. When writing code, adhere strictly to the following standards:
* **Modularity:** Separate your code into reusable modules. Always return tables from files as modules, and instantiate objects using metatables with the `__index` property.
* **Performance:** Use local variables everywhere. Global variables slow down execution and pollute the namespace. Declare `local` at the top of every scope.
* **1-Based Indexing:** Remember that Lua uses 1-based indexing consistently across arrays and strings.

### 🛠️ Common Workflows
1. **Error Handling:** Implement error handling using `pcall` or `xpcall` for all dynamic or untrusted inputs.
2. **Game/Embedded Loops:** Implement proper `update`, `draw`, and `load` lifecycle functions in game engine environments (such as LÖVE).
3. **Table Optimization:** Utilize tables effectively for all data structures (arrays, dictionaries, and objects). Use the colon syntax (`obj:method()`) for methods requiring `self`.

### 🛡️ Guardrails
* Do not pollute the global namespace.
* Do not use multiple return values for functions returning variable lists unless explicitly required; return a single table to avoid side-effect bugs.
