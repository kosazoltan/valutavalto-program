import { Component, type ErrorInfo, type ReactNode } from 'react';
import { sendErrorReport } from '@/lib/ErrorReporter';

interface Props {
  children: ReactNode;
  fallback?: ReactNode;
}

interface State {
  hasError: boolean;
  error: Error | null;
}

/**
 * React Error Boundary — elkapja a renderelési hibákat.
 * Fallback UI-t mutat, és opcionálisan továbbítja a hibát logolásra.
 */
export default class ErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = { hasError: false, error: null };
  }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: ErrorInfo): void {
    console.error('[ErrorBoundary] Caught error:', error, errorInfo);
    void sendErrorReport(error, 'ErrorBoundary componentDidCatch');
  }

  private handleReset = (): void => {
    this.setState({ hasError: false, error: null });
  };

  render(): ReactNode {
    if (this.state.hasError) {
      if (this.props.fallback) {
        return this.props.fallback;
      }

      return (
        <div className="flex flex-col items-center justify-center min-h-screen bg-gray-50 p-8">
          <div className="bg-white rounded-lg shadow-lg p-8 max-w-md text-center">
            <div className="text-5xl mb-4">⚠️</div>
            <h1 className="text-xl font-bold text-gray-800 mb-2">Váratlan hiba történt</h1>
            <p className="text-gray-500 mb-4 text-sm">
              {this.state.error?.message ?? 'Ismeretlen hiba'}
            </p>
            <button
              onClick={this.handleReset}
              className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 transition-colors text-sm"
            >
              Újrapróbálás
            </button>
          </div>
        </div>
      );
    }

    return this.props.children;
  }
}
