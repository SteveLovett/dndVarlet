import { Navigate, Route, Routes } from 'react-router-dom'
import { AppShellLayout } from './AppShellLayout.tsx'
import { GuestRoute } from './GuestRoute.tsx'
import { HomePage } from './pages/HomePage.tsx'
import { LandingPage } from './pages/LandingPage.tsx'
import { LoginPage } from './pages/LoginPage.tsx'
import { RegisterPage } from './pages/RegisterPage.tsx'
import { ProtectedRoute } from './ProtectedRoute.tsx'
import { RootRedirect } from './RootRedirect.tsx'

/**
 * Public: /, /login, /register
 * Authenticated app: /app/* (shared layout + Outlet)
 */
function App() {
  return (
    <Routes>
      <Route path="/" element={<RootRedirect />} />
      <Route
        path="/register"
        element={
          <GuestRoute>
            <RegisterPage />
          </GuestRoute>
        }
      />
      <Route
        path="/login"
        element={
          <GuestRoute>
            <LoginPage />
          </GuestRoute>
        }
      />
      <Route
        path="/app"
        element={
          <ProtectedRoute>
            <AppShellLayout />
          </ProtectedRoute>
        }
      >
        <Route index element={<HomePage />} />
        <Route path="landing" element={<LandingPage />} />
      </Route>
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  )
}

export default App
