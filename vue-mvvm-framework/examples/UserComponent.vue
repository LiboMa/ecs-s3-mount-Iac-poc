<template>
  <div class="user-form">
    <h2>User Management</h2>
    
    <!-- Loading indicator -->
    <div v-if="isLoading" class="loading">
      Loading...
    </div>

    <!-- Error display -->
    <div v-if="error" class="error">
      {{ error }}
    </div>

    <!-- User form -->
    <form @submit.prevent="handleSave" v-if="isInitialized">
      <div class="form-group">
        <label for="name">Name:</label>
        <input
          id="name"
          v-model="viewModel.user.name"
          @input="updateName"
          type="text"
          :class="{ error: viewModel.userErrors.name }"
        />
        <span v-if="viewModel.userErrors.name" class="error-text">
          {{ viewModel.userErrors.name }}
        </span>
      </div>

      <div class="form-group">
        <label for="email">Email:</label>
        <input
          id="email"
          v-model="viewModel.user.email"
          @input="updateEmail"
          type="email"
          :class="{ error: viewModel.userErrors.email }"
        />
        <span v-if="viewModel.userErrors.email" class="error-text">
          {{ viewModel.userErrors.email }}
        </span>
      </div>

      <div class="form-group">
        <label for="age">Age:</label>
        <input
          id="age"
          v-model.number="viewModel.user.age"
          @input="updateAge"
          type="number"
          :class="{ error: viewModel.userErrors.age }"
        />
        <span v-if="viewModel.userErrors.age" class="error-text">
          {{ viewModel.userErrors.age }}
        </span>
      </div>

      <div class="form-actions">
        <button
          type="submit"
          :disabled="!canExecuteCommand('saveUser')"
          class="btn-primary"
        >
          Save User
        </button>
        
        <button
          type="button"
          @click="handleLoad"
          :disabled="isLoading"
          class="btn-secondary"
        >
          Load Sample User
        </button>
        
        <button
          type="button"
          @click="handleReset"
          :disabled="isLoading"
          class="btn-secondary"
        >
          Reset
        </button>
      </div>
    </form>
  </div>
</template>

<script>
import { useMVVM } from '../src/core/MVVMComponent.js'
import { UserViewModel } from './UserExample.js'

export default {
  name: 'UserComponent',
  
  setup() {
    const userViewModel = new UserViewModel()
    const { executeCommand, canExecuteCommand, isLoading, error, isInitialized } = useMVVM(userViewModel)

    // Form handlers
    const updateName = (event) => {
      userViewModel.model.setData('name', event.target.value)
    }

    const updateEmail = (event) => {
      userViewModel.model.setData('email', event.target.value)
    }

    const updateAge = (event) => {
      userViewModel.model.setData('age', parseInt(event.target.value) || 0)
    }

    const handleSave = async () => {
      try {
        const result = await executeCommand('saveUser')
        alert(result.message)
      } catch (error) {
        console.error('Save failed:', error)
      }
    }

    const handleLoad = async () => {
      try {
        await executeCommand('loadUser', 123)
      } catch (error) {
        console.error('Load failed:', error)
      }
    }

    const handleReset = () => {
      executeCommand('resetUser')
    }

    return {
      viewModel: userViewModel,
      executeCommand,
      canExecuteCommand,
      isLoading,
      error,
      isInitialized,
      updateName,
      updateEmail,
      updateAge,
      handleSave,
      handleLoad,
      handleReset
    }
  }
}
</script>

<style scoped>
.user-form {
  max-width: 400px;
  margin: 0 auto;
  padding: 20px;
}

.form-group {
  margin-bottom: 15px;
}

label {
  display: block;
  margin-bottom: 5px;
  font-weight: bold;
}

input {
  width: 100%;
  padding: 8px;
  border: 1px solid #ddd;
  border-radius: 4px;
}

input.error {
  border-color: #e74c3c;
}

.error-text {
  color: #e74c3c;
  font-size: 12px;
  margin-top: 5px;
  display: block;
}

.form-actions {
  display: flex;
  gap: 10px;
  margin-top: 20px;
}

.btn-primary, .btn-secondary {
  padding: 10px 15px;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}

.btn-primary {
  background-color: #3498db;
  color: white;
}

.btn-secondary {
  background-color: #95a5a6;
  color: white;
}

button:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.loading {
  text-align: center;
  padding: 20px;
  color: #3498db;
}

.error {
  background-color: #f8d7da;
  color: #721c24;
  padding: 10px;
  border-radius: 4px;
  margin-bottom: 15px;
}
</style>