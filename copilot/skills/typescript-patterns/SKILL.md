---
name: typescript-patterns
description: TypeScript engineering patterns & standards. Use for strict typing, async safety, modern TS idioms, and test conventions.
---

# TypeScript Patterns & Standards

## Style and Conventions
- Enable `strict` mode in `tsconfig.json`
- Use explicit type annotations for function parameters and return types
- Prefer `interface` for object shapes; use `type` for unions, intersections, and mapped types
- Use `const` by default; use `let` only when reassignment is necessary; never use `var`
- Prefer `readonly` properties and `Readonly<T>` for immutable data

## Types
- Avoid `any`; use `unknown` when the type is truly not known, then narrow with type guards
- Use discriminated unions for state machines and variant types
- Use `as const` for literal type inference
- Prefer `Record<K, V>` over index signatures where keys are known
- Use template literal types for string patterns where appropriate

## Error Handling
- Use typed error handling; define custom error classes extending `Error`
- Prefer `Result` or `Either` patterns over throwing for expected failure cases
- Always handle Promise rejections; avoid unhandled promise rejections

## Functions
- Use arrow functions for callbacks and inline functions
- Use named function declarations for top-level exported functions
- Prefer destructured parameters for functions with multiple options

## Async
- Use `async/await` over raw Promises and `.then()` chains
- Use `Promise.all()` for concurrent independent operations
- Always handle errors in async functions with try/catch

## Testing
- Use `describe` / `it` or `test` blocks with descriptive names
- Mock external dependencies; test business logic in isolation

### Jest
- Use `jest.mock()` for module mocking
- Use `beforeEach` / `afterEach` for test lifecycle
- Use `jest.fn()` and `jest.spyOn()` for function mocking
- Use snapshot tests sparingly — prefer explicit assertions

### Vitest
- API-compatible with Jest; same patterns apply
- Use `vi.mock()`, `vi.fn()`, and `vi.spyOn()`
- Preferred for Vite-based projects due to native ESM support

### Mocha + Chai
- Use `describe` / `it` with Chai's `expect` or `assert` style
- Use `sinon` for stubs, spies, and mocks

### Playwright / Cypress
- Use for E2E testing of web applications
- Prefer Playwright's `test` / `expect` API for new projects
- Keep E2E tests focused on critical user flows