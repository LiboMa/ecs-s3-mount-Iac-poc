import { onMounted, onUnmounted, inject, provide } from 'vue'

export const MVVMComponent = {
  props: {
    viewModel: {
      type: Object,
      default: null
    }
  },

  setup(props, { emit }) {
    // Get viewModel from props or injection
    const viewModel = props.viewModel || inject('viewModel', null)
    
    if (!viewModel) {
      throw new Error('ViewModel is required for MVVM component')
    }

    // Provide viewModel to child components
    provide('viewModel', viewModel)

    // Initialize viewModel on mount
    onMounted(async () => {
      if (!viewModel.isInitialized) {
        await viewModel.initialize()
      }
    })

    // Cleanup on unmount
    onUnmounted(() => {
      if (viewModel.dispose) {
        viewModel.dispose()
      }
    })

    // Command execution helper
    const executeCommand = async (commandName, ...args) => {
      try {
        const result = await viewModel.executeCommand(commandName, ...args)
        emit('command-executed', { command: commandName, result })
        return result
      } catch (error) {
        emit('command-error', { command: commandName, error })
        throw error
      }
    }

    // Command can execute helper
    const canExecuteCommand = (commandName) => {
      return viewModel.canExecuteCommand(commandName)
    }

    return {
      viewModel,
      executeCommand,
      canExecuteCommand,
      // Expose common viewModel properties
      isLoading: viewModel.isLoading,
      error: viewModel.error,
      isInitialized: viewModel.isInitialized
    }
  }
}

// Composable for using MVVM in any component
export function useMVVM(viewModel = null) {
  const vm = viewModel || inject('viewModel')
  
  if (!vm) {
    throw new Error('ViewModel not found. Provide it as parameter or inject it.')
  }

  const executeCommand = async (commandName, ...args) => {
    return await vm.executeCommand(commandName, ...args)
  }

  const canExecuteCommand = (commandName) => {
    return vm.canExecuteCommand(commandName)
  }

  return {
    viewModel: vm,
    executeCommand,
    canExecuteCommand,
    isLoading: vm.isLoading,
    error: vm.error,
    isInitialized: vm.isInitialized
  }
}