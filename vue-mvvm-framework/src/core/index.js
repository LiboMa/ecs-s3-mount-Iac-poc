import { createApp } from 'vue'
import { BaseModel } from './BaseModel.js'
import { BaseViewModel } from './BaseViewModel.js'
import { CommandManager } from './CommandManager.js'
import { MVVMComponent, useMVVM } from './MVVMComponent.js'

// Create MVVM-enabled Vue app
export function createMVVMApp(options = {}) {
  const { viewModel, ...vueOptions } = options
  
  const app = createApp(vueOptions)
  
  // Global MVVM mixin
  app.mixin(MVVMComponent)
  
  // Provide global viewModel if specified
  if (viewModel) {
    app.provide('viewModel', viewModel)
  }
  
  return app
}

// Export core classes and utilities
export {
  BaseModel,
  BaseViewModel,
  CommandManager,
  MVVMComponent,
  useMVVM
}

// Plugin for Vue
export default {
  install(app, options = {}) {
    // Register global components
    app.component('MVVMComponent', MVVMComponent)
    
    // Global properties
    app.config.globalProperties.$mvvm = {
      createModel: (data) => new BaseModel(data),
      createViewModel: (model) => new BaseViewModel(model)
    }
    
    // Provide global viewModel if specified
    if (options.viewModel) {
      app.provide('viewModel', options.viewModel)
    }
  }
}