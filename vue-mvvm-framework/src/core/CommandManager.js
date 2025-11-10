export class CommandManager {
  constructor() {
    this._commands = new Map()
  }

  // Register a command
  register(name, command) {
    if (!command.execute || typeof command.execute !== 'function') {
      throw new Error(`Command ${name} must have an execute function`)
    }
    
    this._commands.set(name, {
      execute: command.execute,
      canExecute: command.canExecute || (() => true)
    })
  }

  // Execute a command
  async execute(name, ...args) {
    const command = this._commands.get(name)
    if (!command) {
      throw new Error(`Command ${name} not found`)
    }

    if (!command.canExecute(...args)) {
      throw new Error(`Command ${name} cannot be executed`)
    }

    return await command.execute(...args)
  }

  // Check if command can execute
  canExecute(name, ...args) {
    const command = this._commands.get(name)
    if (!command) return false
    
    return command.canExecute(...args)
  }

  // Get all registered commands
  getCommands() {
    return Array.from(this._commands.keys())
  }

  // Clear all commands
  clear() {
    this._commands.clear()
  }

  // Remove specific command
  unregister(name) {
    return this._commands.delete(name)
  }
}