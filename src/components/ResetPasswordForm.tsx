import { useEffect, useRef, useState, type FormEvent } from 'react'
import { isAuthRetryableFetchError } from '@supabase/supabase-js'
import Button from '@mui/material/Button'
import Stack from '@mui/material/Stack'
import TextField from '@mui/material/TextField'
import { supabase } from '../lib/supabase'
import { storeRecoveryUser } from '../lib/passwordRecovery'

type Props = {
  email?: string
  onContinue: () => void
  onSignOut: () => Promise<void>
  signingOut: boolean
  logoutError: string
}

export default function ResetPasswordForm({ email, onContinue, onSignOut, signingOut, logoutError }: Props) {
  const [password, setPassword] = useState('')
  const [confirmation, setConfirmation] = useState('')
  const [pending, setPending] = useState(false)
  const [saved, setSaved] = useState(false)
  const [errorMessage, setErrorMessage] = useState('')
  const mounted = useRef(false)

  useEffect(() => {
    mounted.current = true
    return () => { mounted.current = false }
  }, [])

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    if (pending || signingOut || saved) return
    setErrorMessage('')
    if (password.length < 6) {
      setErrorMessage('Use a password with at least 6 characters.')
      return
    }
    if (password !== confirmation) {
      setErrorMessage('Your passwords do not match. Please try again.')
      return
    }
    setPending(true)
    try {
      const { error } = await supabase.auth.updateUser({ password })
      if (!mounted.current) return
      if (error) {
        setErrorMessage(isAuthRetryableFetchError(error)
          ? 'Unable to confirm your password change. Check your connection and try again. If the new password was already saved, use it to sign in.'
          : error.message)
      } else {
        storeRecoveryUser(null)
        setPassword('')
        setConfirmation('')
        setSaved(true)
      }
    } catch {
      if (mounted.current) setErrorMessage('Unable to confirm your password change. Check your connection and try again. If the new password was already saved, use it to sign in.')
    } finally {
      if (mounted.current) setPending(false)
    }
  }

  return (
    <Stack component="form" onSubmit={handleSubmit} spacing={2} sx={{ maxWidth: 400, mx: 'auto', p: 3 }}>
      <h1>Choose a new password</h1>
      <p>Resetting the password for {email || 'your account'}.</p>
      {saved ? (
        <>
          <p role="status">Password updated. Use your new password the next time you sign in.</p>
          <Button variant="contained" onClick={onContinue} disabled={signingOut}>Continue to Daily Bread</Button>
        </>
      ) : (
        <>
          <TextField label="New password" type="password" autoComplete="new-password" required
            helperText="At least 6 characters." value={password}
            onChange={(event) => setPassword(event.target.value)} disabled={pending || signingOut} />
          <TextField label="Confirm new password" type="password" autoComplete="new-password" required
            value={confirmation} onChange={(event) => setConfirmation(event.target.value)} disabled={pending || signingOut} />
          <Button type="submit" variant="contained" disabled={pending || signingOut}>
            {pending ? 'Updating password...' : 'Update password'}
          </Button>
          {errorMessage && <p role="alert">{errorMessage}</p>}
        </>
      )}
      <Button onClick={onSignOut} disabled={pending || signingOut}>
        {signingOut ? 'Signing out...' : 'Sign out'}
      </Button>
      {logoutError && <p role="alert">{logoutError}</p>}
    </Stack>
  )
}
