import { useState, type FormEvent } from 'react'
import { isAuthRetryableFetchError } from '@supabase/supabase-js'
import Button from '@mui/material/Button'
import Stack from '@mui/material/Stack'
import TextField from '@mui/material/TextField'
import { supabase } from '../lib/supabase'

export default function ForgotPasswordForm({ onSignIn }: { onSignIn: () => void }) {
  const [email, setEmail] = useState('')
  const [pending, setPending] = useState(false)
  const [sent, setSent] = useState(false)
  const [errorMessage, setErrorMessage] = useState('')

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    if (pending || sent) return
    setPending(true)
    setErrorMessage('')
    try {
      const { error } = await supabase.auth.resetPasswordForEmail(email.trim(), {
        redirectTo: new URL(import.meta.env.BASE_URL, window.location.origin).href,
      })
      if (error) {
        setErrorMessage(isAuthRetryableFetchError(error)
          ? 'Unable to connect. Please check your internet connection and try again.'
          : error.message)
      } else {
        setSent(true)
      }
    } catch {
      setErrorMessage('Unable to request a reset email. Check your connection and try again.')
    } finally {
      setPending(false)
    }
  }

  return (
    <Stack component="form" onSubmit={handleSubmit} spacing={2} sx={{ maxWidth: 400, mx: 'auto', p: 3 }}>
      <h1>Reset your password</h1>
      <p>Enter your account email to request a password reset link.</p>
      <TextField label="Email" type="email" autoComplete="email" required
        value={email} onChange={(event) => setEmail(event.target.value)} disabled={pending || sent} />
      <Button type="submit" variant="contained" disabled={pending || sent}>
        {pending ? 'Requesting reset email...' : 'Send reset email'}
      </Button>
      {errorMessage && <p role="alert">{errorMessage}</p>}
      {sent && <p role="status">If an account exists for that email, you will receive a password reset link. Check your inbox and spam folder, and use the latest email.</p>}
      {sent && <Button onClick={() => setSent(false)}>Request another email</Button>}
      <Button onClick={onSignIn} disabled={pending}>Back to sign in</Button>
    </Stack>
  )
}
