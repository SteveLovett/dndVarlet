import { useEffect, useState } from 'react'
import { supabase } from '../supabaseClient'

/**
 * /app — main authenticated home (rendered inside AppShellLayout).
 * Loads `profiles.display_name` when the Phase 0 migration is applied; backfills a row if missing.
 */
export function HomePage() {
  const [email, setEmail] = useState<string | null>(null)
  const [displayName, setDisplayName] = useState<string | null>(null)

  useEffect(() => {
    void (async () => {
      const {
        data: { session },
      } = await supabase.auth.getSession()
      if (!session?.user) return

      const user = session.user
      setEmail(user.email ?? null)

      const { data: row, error: selectError } = await supabase
        .from('profiles')
        .select('display_name')
        .eq('id', user.id)
        .maybeSingle()

      if (selectError) {
        console.warn('profiles select:', selectError.message)
        return
      }

      const fallback = user.email?.split('@')[0]?.trim() || 'Player'

      if (row?.display_name) {
        setDisplayName(row.display_name)
        return
      }

      if (row && row.display_name == null) {
        const { data: updated, error: updateError } = await supabase
          .from('profiles')
          .update({ display_name: fallback })
          .eq('id', user.id)
          .select('display_name')
          .maybeSingle()

        if (updateError) {
          console.warn('profiles update:', updateError.message)
          return
        }
        if (updated?.display_name) setDisplayName(updated.display_name)
        return
      }

      const { data: inserted, error: insertError } = await supabase
        .from('profiles')
        .insert({ id: user.id, display_name: fallback })
        .select('display_name')
        .maybeSingle()

      if (insertError) {
        console.warn('profiles insert:', insertError.message)
        return
      }

      if (inserted?.display_name) {
        setDisplayName(inserted.display_name)
      }
    })()
  }, [])

  const label = displayName ?? email

  return (
    <div className="app-panel">
      <h2>Home</h2>
      <p>
        {"You're signed in"}
        {label ? (
          <>
            {' '}
            as <strong>{label}</strong>
            {displayName && email && displayName !== email ? (
              <span style={{ color: 'var(--text)' }}> ({email})</span>
            ) : null}
          </>
        ) : null}
        . Your games and tools will show here in Phase 1.
      </p>
    </div>
  )
}
