import { reactive, computed, ref } from 'vue'
import { CommandManager } from './CommandManager.js'

export class BaseViewModel {
  constructor(model = null) {
    this.model = model
    this.commands = new CommandManager()
    this._state = reactive({
      loading: false,
      error: null,
      initialized: false
    })
  }

  // State getters
  get isLoading() {
    return this._state.loading
  }

  get error() {
    return this._state.error
  }

  get isInitialized() {
    return this._state.initialized
  }

  // State setters
  setLoading(loading) {
    this._state.loading = loading
  }

  setError(error) {
    this._state.error = error
  }

  setInitialized(initialized) {
    this._state.initialized = initialized
  }

  // Command registration
  registerCommand(name, execute, canExecute = () => true) {
    this.commands.register(name, {
      execute: execute.bind(this),
      canExecute: canExecute.bind(this)
    })
  }

  // Execute command
  async executeCommand(name, ...args) {
    try {
      this.setLoading(true)
      this.setError(null)
      const result = await this.commands.execute(name, ...args)
      return result
    } catch (error) {
      this.setError(error.message)
      throw error
    } finally {
      this.setLoading(false)
    }
  }

  // Check if command can execute
  canExecuteCommand(name) {
    return this.commands.canExecute(name)
  }

  // Initialize viewmodel
  async initialize() {
    if (this._state.initialized) return
    
    try {
      this.setLoading(true)
      await this.onInitialize()
      this.setInitialized(true)
    } catch (error) {
      this.setError(error.message)
    } finally {
      this.setLoading(false)
    }
  }

  // Override in derived classes
  async onInitialize() {
    // Implementation specific initialization
  }

  // Cleanup
  dispose() {
    this.commands.clear()
    this._state.loading = false
    this._state.error = null
    this._state.initialized = false
  }
}