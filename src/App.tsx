import { useEffect, useState } from 'react'
import type { Session } from '@supabase/supabase-js'
import Stack from '@mui/material/Stack'
import Button from '@mui/material/Button'
import LoginForm from './components/LoginForm'
import SignupForm from './components/SignupForm'
import ProfileForm from './components/ProfileForm'
import GroupsDashboard from './components/GroupsDashboard'
import JoinGroupInvite from './components/JoinGroupInvite'
import { inviteFromHash, pendingInviteKey, readPendingInvite, withoutInviteHash } from './lib/groupInvite'
import { supabase } from './lib/supabase'


export default function App() {
  const [session, setSession] = useState<Session | null>(null)
  const [loading, setLoading] = useState(true)
  const [signingOut, setSigningOut] = useState(false)
  const [logoutError, setLogoutError] = useState('')
  const [authScreen, setAuthScreen] = useState<'login' | 'signup'>('login')
  const [inviteToken, setInviteToken] = useState(readPendingInvite)
  const [joinedGroup, setJoinedGroup] = useState<{ userId: string; id: string } | null>(null)

  useEffect(() => {
    function receiveInvite() {
      const token = inviteFromHash(window.location.hash)
      if (token !== null) setInviteToken(token)
    }
    window.addEventListener('hashchange', receiveInvite)
    return () => window.removeEventListener('hashchange', receiveInvite)
  }, [])

  useEffect(() => {
    let stored: boolean
    try {
      if (inviteToken === null) window.sessionStorage.removeItem(pendingInviteKey)
      else window.sessionStorage.setItem(pendingInviteKey, inviteToken)
      stored = true
    } catch {
      stored = false
    }
    if ((stored || inviteToken === null) && inviteFromHash(window.location.hash) !== null) {
      window.history.replaceState(
        window.history.state,
        '',
        window.location.pathname + window.location.search + withoutInviteHash(window.location.hash),
      )
    }
  }, [inviteToken])

  function dismissInvite() {
    setInviteToken(null)
    setJoinedGroup(null)
  }

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
    const form = authScreen === 'signup'
      ? <SignupForm onSignIn={() => setAuthScreen('login')} />
      : <LoginForm onSignup={() => setAuthScreen('signup')} />
    return (
      <>
        {inviteToken !== null && (
          <Stack spacing={1} sx={{ maxWidth: 400, mx: 'auto', px: 3 }}>
            <p>Sign in to review your group invitation. If you create an account, confirm your email, then return to this tab or reopen the invitation link.</p>
            <Button onClick={dismissInvite}>Dismiss invitation</Button>
          </Stack>
        )}
        {form}
      </>
    )
  }

  return (
    <Stack spacing={2} sx={{ maxWidth: 400, mx: 'auto', p: 3 }}>
      <h1>Welcome to Daily Bread</h1>
      <p>Signed in as {session.user.email}</p>
      {inviteToken !== null ? (
        <JoinGroupInvite
          key={`${session.user.id}-${inviteToken}`}
          token={inviteToken}
          onDismiss={dismissInvite}
          onJoined={(groupId) => {
            setJoinedGroup({ userId: session.user.id, id: groupId })
            setInviteToken(null)
          }}
        />
      ) : (
        <>
          <ProfileForm key={session.user.id} userId={session.user.id} />
          <GroupsDashboard
            key={`groups-${session.user.id}`}
            userId={session.user.id}
            initialGroupId={joinedGroup?.userId === session.user.id ? joinedGroup.id : null}
          />
        </>
      )}
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
