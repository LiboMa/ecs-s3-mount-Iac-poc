import { reactive, computed } from 'vue'

export class BaseModel {
  constructor(data = {}) {
    this._data = reactive({ ...data })
    this._validators = new Map()
    this._errors = reactive({})
  }

  // Reactive data getter
  get data() {
    return this._data
  }

  // Set data with validation
  setData(key, value) {
    if (this.validate(key, value)) {
      this._data[key] = value
      delete this._errors[key]
    }
  }

  // Add validator for a field
  addValidator(field, validator) {
    this._validators.set(field, validator)
  }

  // Validate field
  validate(field, value) {
    const validator = this._validators.get(field)
    if (validator) {
      const result = validator(value)
      if (result !== true) {
        this._errors[field] = result
        return false
      }
    }
    return true
  }

  // Get validation errors
  get errors() {
    return this._errors
  }

  // Check if model is valid
  get isValid() {
    return Object.keys(this._errors).length === 0
  }

  // Serialize to plain object
  toJSON() {
    return { ...this._data }
  }
}