import { useEffect, useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { supabase } from '../supabaseClient'

type MembershipRow = {
  game_role: 'Game Master' | 'Player' | null
  games:
    | {
        id: string
        name: string
        description: string | null
      }
    | Array<{
        id: string
        name: string
        description: string | null
      }>
    | null
}

export function GameDetailPage() {
  const { gameId } = useParams<{ gameId: string }>()
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [name, setName] = useState<string | null>(null)
  const [description, setDescription] = useState<string | null>(null)
  const [role, setRole] = useState<'Game Master' | 'Player' | null>(null)

  useEffect(() => {
    let cancelled = false

    void (async () => {
      if (!gameId) {
        setError('Missing game id.')
        setLoading(false)
        return
      }

      const {
        data: { user },
        error: userError,
      } = await supabase.auth.getUser()
      if (cancelled) return

      if (userError) {
        setError(userError.message)
        setLoading(false)
        return
      }
      if (!user) {
        setError('You must be signed in.')
        setLoading(false)
        return
      }

      const { data, error: membershipError } = await supabase
        .from('game_members')
        .select('game_role, games ( id, name, description )')
        .eq('user_id', user.id)
        .eq('game_id', gameId)
        .maybeSingle()

      if (cancelled) return

      if (membershipError) {
        setError(membershipError.message)
        setLoading(false)
        return
      }

      if (!data) {
        setError('Game not found or you are not a member.')
        setLoading(false)
        return
      }

      const row = data as MembershipRow
      const game = Array.isArray(row.games) ? row.games[0] : row.games
      if (!game) {
        setError('Game details unavailable.')
        setLoading(false)
        return
      }

      setName(game.name)
      setDescription(game.description)
      setRole(row.game_role === 'Game Master' ? 'Game Master' : 'Player')
      setLoading(false)
    })()

    return () => {
      cancelled = true
    }
  }, [gameId])

  return (
    <div className="app-panel">
      <h2>Game detail</h2>
      {loading ? <p>Loading game...</p> : null}
      {!loading && error ? <p>{error}</p> : null}
      {!loading && !error ? (
        <>
          <p>
            <strong>{name}</strong>
          </p>
          <p>{description && description.length > 0 ? description : 'No description yet.'}</p>
          <p>Role: {role}</p>
        </>
      ) : null}
      <p>
        <Link to="/app">Back to My games</Link>
      </p>
    </div>
  )
}
