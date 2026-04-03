import { useEffect, useState } from 'react'
import type { ReactNode } from 'react'
import { Navigate, useLocation } from 'react-router-dom'
import type { Session } from '@supabase/supabase-js'
import { SessionLoadingFallback } from './SessionLoadingFallback.tsx'
import { supabase } from './supabaseClient'

type Props = {
  children: ReactNode
}

/**
 * Renders children only when a Supabase session exists; otherwise redirects to /login.
 */
export function ProtectedRoute({ children }: Props) {
  const location = useLocation()
  const [session, setSession] = useState<Session | null | undefined>(undefined)

  useEffect(() => {
    void supabase.auth.getSession().then(({ data: { session: s } }) => {
      setSession(s)
    })

    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((_event, s) => {
      setSession(s)
    })

    return () => subscription.unsubscribe()
  }, [])

  if (session === undefined) {
    return <SessionLoadingFallback />
  }

  if (!session) {
    return <Navigate to="/login" state={{ from: location }} replace />
  }

  return <>{children}</>
}
