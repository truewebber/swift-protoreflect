# Contributing to SwiftProtoReflect

Thank you for your interest in contributing to SwiftProtoReflect! This document provides guidelines and instructions for contributing.

## Code Style

SwiftProtoReflect follows the [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/) and uses SwiftLint to enforce consistent code style.

Key style points:
- Use 4 spaces for indentation
- Keep line length to 100 characters or less
- Use camelCase for variable and function names
- Use PascalCase for type names
- Include comprehensive documentation comments for all public APIs

## Development Workflow

1. **Write tests first (TDD approach)**
   - Create tests that define the expected behavior
   - Ensure tests fail initially (red phase)
   - Implement code to make tests pass (green phase)
   - Refactor while keeping tests passing (refactor phase)

2. **Implementation**
   - Follow the Swift API Design Guidelines
   - Keep functions small and focused
   - Use clear, descriptive naming
   - Add documentation comments for all public APIs

3. **Quality Assurance**
   - Ensure code coverage meets requirements (90%+ for new code)
   - Run SwiftLint and address any issues
   - Check for memory leaks
   - Verify performance meets requirements

4. **Documentation**
   - Document your code with DocC comments
   - Update README if necessary
   - Add examples for new functionality
   - Update migration guides if applicable

## Pull Request Process

1. Fork the repository and create your branch from `main`
2. If you've added code that should be tested, add tests
3. Ensure all tests pass and the code lints without errors
4. Update the documentation if needed
5. Submit a pull request using the provided template

When submitting a pull request, please:
- Describe the changes you've made
- Link to any related issues
- Indicate the type of change (bugfix, feature, etc.)
- Verify that you've completed the checklist items

## Reporting Issues

When reporting issues, please include:

- A clear and descriptive title
- A detailed description of the issue
- Steps to reproduce the behavior
- Expected behavior
- Actual behavior
- Environment information (Swift version, OS, etc.)

## Testing Guidelines

- Write unit tests for all new functionality
- Include both positive and negative test cases
- Test edge cases and boundary conditions
- For performance-critical code, include performance tests
- Aim for at least 90% code coverage

## Documentation Guidelines

- Use DocC comment format for all public APIs
- Include examples in documentation where appropriate
- Document parameters, return values, and thrown errors
- Note any important considerations or limitations
- Follow the examples in the Documentation Examples file

## License

By contributing to SwiftProtoReflect, you agree that your contributions will be licensed under the project's MIT license. 