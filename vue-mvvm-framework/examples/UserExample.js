import { BaseModel } from '../src/core/BaseModel.js'
import { BaseViewModel } from '../src/core/BaseViewModel.js'

// User Model
class UserModel extends BaseModel {
  constructor(userData = {}) {
    super({
      id: null,
      name: '',
      email: '',
      age: 0,
      ...userData
    })

    // Add validators
    this.addValidator('name', (value) => {
      if (!value || value.length < 2) {
        return 'Name must be at least 2 characters'
      }
      return true
    })

    this.addValidator('email', (value) => {
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
      if (!emailRegex.test(value)) {
        return 'Invalid email format'
      }
      return true
    })

    this.addValidator('age', (value) => {
      if (value < 0 || value > 120) {
        return 'Age must be between 0 and 120'
      }
      return true
    })
  }
}

// User ViewModel
class UserViewModel extends BaseViewModel {
  constructor() {
    const userModel = new UserModel()
    super(userModel)

    // Register commands
    this.registerCommand('saveUser', this.saveUser, this.canSaveUser)
    this.registerCommand('loadUser', this.loadUser)
    this.registerCommand('resetUser', this.resetUser)
  }

  // Command implementations
  async saveUser() {
    if (!this.model.isValid) {
      throw new Error('Cannot save invalid user data')
    }

    // Simulate API call
    await new Promise(resolve => setTimeout(resolve, 1000))
    
    console.log('User saved:', this.model.toJSON())
    return { success: true, message: 'User saved successfully' }
  }

  canSaveUser() {
    return this.model.isValid && !this.isLoading
  }

  async loadUser(userId) {
    // Simulate API call
    await new Promise(resolve => setTimeout(resolve, 500))
    
    const userData = {
      id: userId,
      name: 'John Doe',
      email: 'john@example.com',
      age: 30
    }

    Object.keys(userData).forEach(key => {
      this.model.setData(key, userData[key])
    })

    return userData
  }

  resetUser() {
    this.model.setData('name', '')
    this.model.setData('email', '')
    this.model.setData('age', 0)
  }

  // Getters for easy access
  get user() {
    return this.model.data
  }

  get userErrors() {
    return this.model.errors
  }
}

export { UserModel, UserViewModel }