# Vue MVVM Framework

A lightweight MVVM (Model-View-ViewModel) framework built on top of Vue.js that provides structured data binding, command patterns, and reactive state management.

## Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│      Model      │◄──►│   ViewModel     │◄──►│      View       │
│   (Data Layer)  │    │ (Logic Layer)   │    │  (Vue Component)│
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Core Components

- **BaseModel**: Reactive data models with validation
- **BaseViewModel**: Command handling and state management
- **MVVMComponent**: Vue component mixin for MVVM binding
- **CommandManager**: Command pattern implementation
- **StateManager**: Centralized state management

## Quick Start

```javascript
import { createMVVMApp } from './core'
import UserViewModel from './viewmodels/UserViewModel'

const app = createMVVMApp({
  viewModel: UserViewModel
})

app.mount('#app')
```