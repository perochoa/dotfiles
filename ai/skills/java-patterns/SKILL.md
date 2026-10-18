---
name: java-patterns
description: Java engineering patterns and standards. Use for idiomatic Java, exception handling, collections, logging, and testing conventions.
---

# Java Patterns & Standards

## Style and Conventions
- Follow standard Java naming conventions (camelCase methods, PascalCase classes)
- Use `final` for variables that should not be reassigned
- Prefer records for immutable data carriers (Java 14+)
- Use `Optional` for return types that may be absent; never return `null` from public methods
- Prefer `var` for local variables when the type is obvious from context

## Error Handling
- Use specific exception types; avoid catching `Exception` or `Throwable` broadly
- Use checked exceptions for recoverable conditions, unchecked for programming errors
- Always include context in exception messages
- Use try-with-resources for `AutoCloseable` resources

## Collections and Streams
- Prefer immutable collections (`List.of()`, `Map.of()`, `Collections.unmodifiable*`)
- Use `Stream` API for collection transformations; avoid side effects in streams
- Prefer `Map.getOrDefault()` and `Map.computeIfAbsent()` over manual null checks

## Design
- Favour composition over inheritance
- Program to interfaces, not implementations
- Use dependency injection; avoid static factories for testable components
- Keep classes focused — single responsibility principle
- Use the Builder pattern for objects with many optional parameters

## Testing
- Name test methods descriptively: `shouldReturnEmpty_whenInputIsNull()`
- Use parameterised / data-driven tests for multiple scenarios
- Use dependency injection to make code testable

### JUnit 5
- Use `@ParameterizedTest` with `@ValueSource`, `@CsvSource`, or `@MethodSource`
- Use `@Nested` classes to group related tests
- Use `@BeforeEach` / `@AfterEach` for test lifecycle

### JUnit 4
- Use `@RunWith` and `@Rule` for test configuration
- Use `@Parameterized` for data-driven tests

### Assertions
- AssertJ provides fluent assertions (`assertThat(result).isEqualTo(expected)`)
- Hamcrest matchers work with both JUnit 4 and 5
- Standard JUnit assertions are fine for simple cases

### Mocking
- Mockito is the most common mocking framework (`@Mock`, `@InjectMocks`, `when/verify`)
- Use `@ExtendWith(MockitoExtension.class)` with JUnit 5
- For integration tests, consider Spring's `@MockBean` if using Spring

## Logging
- Use SLF4J as the logging facade
- Use parameterised logging (`log.info("Processing {}", id)`) — never string concatenation
- Log at appropriate levels: ERROR for failures, WARN for recoverable issues, INFO for key events, DEBUG for diagnostics