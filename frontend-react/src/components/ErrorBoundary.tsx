import { Component } from 'react'
import type { ErrorInfo, ReactNode } from 'react'
import { sendErrorReport } from './ErrorReporter'
import i18n from '../i18n'

interface Props {
  children: ReactNode
  fallback?: ReactNode
}

interface State {
  hasError: boolean
  error: Error | null
}

export default class ErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props)
    this.state = { hasError: false, error: null }
  }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error }
  }

  componentDidCatch(error: Error, info: ErrorInfo): void {
    void sendErrorReport({
      errorType: 'react_error_boundary',
      message: error.message,
      stack: [error.stack, info.componentStack].filter(Boolean).join('\n---\n'),
      severity: 'CRITICAL',
    })
  }

  private handleReset = (): void => {
    this.setState({ hasError: false, error: null })
  }

  render(): ReactNode {
    if (this.state.hasError) {
      if (this.props.fallback) {
        return this.props.fallback
      }

      return (
        <div className="flex min-h-screen items-center justify-center bg-gray-50 dark:bg-gray-900 p-6">
          <div className="max-w-md w-full bg-white dark:bg-gray-800 rounded-xl shadow-lg p-8 text-center">
            <div className="mx-auto mb-4 flex h-12 w-12 items-center justify-center rounded-full bg-red-100 dark:bg-red-900/30">
              <svg
                className="h-6 w-6 text-red-600 dark:text-red-400"
                fill="none"
                viewBox="0 0 24 24"
                strokeWidth="1.5"
                stroke="currentColor"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126ZM12 15.75h.007v.008H12v-.008Z"
                />
              </svg>
            </div>
            <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-2">
              {i18n.t('literals.varatlan-hiba-tortent')}
            </h2>
            <p className="text-sm text-gray-500 dark:text-gray-400 mb-6">
              {i18n.t('literals.az-alkalmazas-egy-nem-vart-hibaba-utkozo')}
            </p>
            {this.state.error && (
              <pre className="mb-4 max-h-32 overflow-auto rounded bg-gray-100 dark:bg-gray-700 p-3 text-left text-xs text-gray-600 dark:text-gray-300">
                {this.state.error.message}
              </pre>
            )}
            <div className="flex gap-3 justify-center">
              <button
                onClick={this.handleReset}
                className="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 transition-colors"
              >
                {i18n.t('literals.ujraprobalas')}
              </button>
              <button
                onClick={() => {
                  window.location.href = '/'
                }}
                className="rounded-lg border border-gray-300 dark:border-gray-600 px-4 py-2 text-sm font-medium text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors"
              >
                {i18n.t('literals.fooldal')}
              </button>
            </div>
          </div>
        </div>
      )
    }

    return this.props.children
  }
}
