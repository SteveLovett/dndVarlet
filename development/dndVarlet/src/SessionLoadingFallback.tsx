import './session-loading.css'

type Props = {
  /** Shown next to the spinner; announced by screen readers via role="status". */
  message?: string
}

/**
 * Full-viewport placeholder while Supabase session is unknown (getSession in flight).
 */
export function SessionLoadingFallback({ message = 'Checking session…' }: Props) {
  return (
    <div
      className="session-loading-screen"
      role="status"
      aria-live="polite"
      aria-busy="true"
    >
      <div className="session-loading-card">
        <div className="session-loading-spinner" aria-hidden />
        <p className="session-loading-text">{message}</p>
      </div>
    </div>
  )
}
