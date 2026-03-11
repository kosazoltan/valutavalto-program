import { Component, ErrorInfo, ReactNode } from 'react';
import { sendErrorReport } from './ErrorReporter';

interface Props {
  children: ReactNode;
  fallback?: ReactNode;
}

interface State {
  hasError: boolean;
  error: Error | null;
}

export class ErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = { hasError: false, error: null };
  }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, info: ErrorInfo) {
    sendErrorReport({
      errorType: 'react_error_boundary',
      message: error.message,
      stack: error.stack + '\n\nComponent Stack:\n' + info.componentStack,
      severity: 'FATAL',
    });
  }

  render() {
    if (this.state.hasError) {
      return this.props.fallback ?? (
        <div style={{
          padding: '2rem',
          textAlign: 'center',
          fontFamily: 'sans-serif',
          color: '#c00',
        }}>
          <h2>Hiba történt az alkalmazásban</h2>
          <p>{this.state.error?.message}</p>
          <button onClick={() => window.location.reload()}>Újratöltés</button>
        </div>
      );
    }
    return this.props.children;
  }
}

export default ErrorBoundary;
