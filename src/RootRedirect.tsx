import { useEffect, useState } from 'react'
import { Navigate } from 'react-router-dom'
import type { Session } from '@supabase/supabase-js'
import { SessionLoadingFallback } from './SessionLoadingFallback.tsx'
import { supabase } from './supabaseClient'

/**
 * / — send signed-in users to the app, guests to login.
 */
export function RootRedirect() {
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

  if (session) {
    return <Navigate to="/app" replace />
  }

  return <Navigate to="/login" replace />
}
