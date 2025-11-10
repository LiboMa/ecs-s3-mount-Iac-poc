# Vue MVVM Framework - Architectural Code Generation Prompt

## Framework Overview
Generate a Vue.js MVVM framework that implements the Model-View-ViewModel pattern with reactive data binding, command patterns, and structured state management.

## Core Architecture Requirements

### 1. BaseModel Class
```javascript
// Requirements:
- Reactive data container using Vue's reactive()
- Built-in validation system with field-level validators
- Error tracking and validation state management
- JSON serialization capabilities
- Immutable data access patterns
```

### 2. BaseViewModel Class
```javascript
// Requirements:
- Command pattern implementation for user actions
- Loading/error state management
- Model integration and lifecycle management
- Async operation handling with proper error boundaries
- Initialization and cleanup lifecycle hooks
```

### 3. CommandManager Class
```javascript
// Requirements:
- Command registration and execution system
- CanExecute validation before command execution
- Async command support with error handling
- Command lifecycle management (register/unregister)
- Parameter passing and validation
```

### 4. MVVMComponent Mixin/Composable
```javascript
// Requirements:
- Vue 3 Composition API integration
- Automatic ViewModel injection and lifecycle management
- Command execution helpers with event emission
- Reactive state exposure to templates
- Cleanup on component unmount
```

## Implementation Patterns

### Data Flow Pattern
```
User Input → Command → ViewModel → Model → Reactive Update → View
```

### Command Pattern Structure
```javascript
// Each command should have:
{
  execute: async (...args) => result,
  canExecute: (...args) => boolean
}
```

### Validation Pattern
```javascript
// Field validators return:
true // for valid
"Error message" // for invalid
```

### State Management Pattern
```javascript
// ViewModel state structure:
{
  loading: boolean,
  error: string | null,
  initialized: boolean
}
```

## Code Generation Guidelines

### 1. Vue 3 Compatibility
- Use Composition API exclusively
- Leverage reactive(), computed(), and ref()
- Implement proper lifecycle hooks (onMounted, onUnmounted)
- Support both Options API and Composition API usage

### 2. TypeScript Support (Optional)
- Generic type support for Models and ViewModels
- Interface definitions for commands and validators
- Proper type inference for reactive properties

### 3. Error Handling
- Graceful error boundaries in all async operations
- Validation error aggregation and display
- Command execution error propagation
- Loading state management during operations

### 4. Performance Considerations
- Minimal reactive overhead
- Efficient command registration/lookup
- Lazy initialization patterns
- Memory leak prevention in cleanup

## Usage Patterns to Support

### 1. Simple Model-ViewModel Binding
```javascript
const model = new UserModel()
const viewModel = new UserViewModel(model)
```

### 2. Component Integration
```vue
<template>
  <form @submit.prevent="executeCommand('saveUser')">
    <input v-model="viewModel.user.name" />
    <button :disabled="!canExecuteCommand('saveUser')">Save</button>
  </form>
</template>
```

### 3. Command Registration
```javascript
viewModel.registerCommand('saveUser', 
  async () => await api.saveUser(this.model.data),
  () => this.model.isValid && !this.isLoading
)
```

### 4. Validation Integration
```javascript
model.addValidator('email', (value) => 
  /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value) || 'Invalid email'
)
```

## Framework Features to Implement

1. **Reactive Data Binding**: Seamless Vue reactivity integration
2. **Command Pattern**: Structured user action handling
3. **Validation System**: Field-level validation with error tracking
4. **State Management**: Loading, error, and initialization states
5. **Lifecycle Management**: Proper setup and cleanup
6. **Event System**: Command execution events and error handling
7. **Dependency Injection**: ViewModel injection in component tree
8. **Async Support**: Promise-based command execution
9. **Error Boundaries**: Graceful error handling and recovery
10. **Memory Management**: Automatic cleanup and disposal

## Testing Considerations
- Unit testable ViewModels and Models
- Command execution testing
- Validation testing
- Reactive state testing
- Component integration testing

Generate code that follows these architectural patterns while maintaining simplicity, performance, and Vue.js best practices.