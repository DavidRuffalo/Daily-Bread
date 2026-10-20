import { useEffect, useState } from 'react'
import type { Session } from '@supabase/supabase-js'
import Stack from '@mui/material/Stack'
import Button from '@mui/material/Button'
import LoginForm from './components/LoginForm'
import { supabase } from './lib/supabase'


export default function App() {
  const [session, setSession] = useState<Session | null>(null)
  const [loading, setLoading] = useState(true)
  const [signingOut, setSigningOut] = useState(false)
  const [logoutError, setLogoutError] = useState('')

  useEffect(() => {
    const { data: { subscription } } =
      supabase.auth.onAuthStateChange((_event, nextSession) => {
        setSession(nextSession)
        setLoading(false)
      })

    return () => subscription.unsubscribe()
  }, [])

  async function handleLogout() {
    if (signingOut) return

    setSigningOut(true)
    setLogoutError('')

    try {
      const { error } = await supabase.auth.signOut({
        scope: 'local',
      })

      if (error) {
        setLogoutError(error.message)
      }
    } catch {
      setLogoutError('Unable to sign out. Please try again.')
    } finally {
      setSigningOut(false)
    }
  }

  if (loading) {
    return <p role="status">Checking your session...</p>
  }

  if (!session) {
    return <LoginForm />
  }

  return (
    <Stack spacing={2} sx={{ maxWidth: 400, mx: 'auto', p: 3 }}>
      <h1>Welcome to Daily Bread</h1>
      <p>Signed in as {session.user.email}</p>
      <Button
        variant="outlined"
        onClick={handleLogout}
        disabled={signingOut}
      >
        {signingOut ? 'Signing out...' : 'Sign out'}
      </Button>

      {logoutError && <p role="alert">{logoutError}</p>}
    </Stack>
  )
}