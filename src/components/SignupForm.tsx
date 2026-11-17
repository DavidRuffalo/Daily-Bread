import { useState, type FormEvent } from 'react'
import { isAuthRetryableFetchError } from '@supabase/supabase-js'
import Button from '@mui/material/Button'
import Stack from '@mui/material/Stack'
import TextField from '@mui/material/TextField'
import { supabase } from '../lib/supabase'

type SignupFormProps = {
  onSignIn: () => void
}

export default function SignupForm({ onSignIn }: SignupFormProps) {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [pending, setPending] = useState(false)
  const [errorMessage, setErrorMessage] = useState('')
  const [confirmationSent, setConfirmationSent] = useState(false)

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    if (pending || confirmationSent) return

    setPending(true)
    setErrorMessage('')

    try {
      const { data, error } = await supabase.auth.signUp({
        email: email.trim(),
        password,
        options: {
          emailRedirectTo: new URL(
            import.meta.env.BASE_URL,
            window.location.origin,
          ).href,
        },
      })

      if (error) {
        setErrorMessage(
          isAuthRetryableFetchError(error)
            ? 'Unable to connect. Please check your internet connection and try again.'
            : error.message,
        )
        return
      }

      setPassword('')
      // App's auth subscription handles an immediately signed-in session.
      // Otherwise, wait for email confirmation before signing in.
      if (!data.session) {
        setConfirmationSent(true)
      }
    } catch {
      setErrorMessage('Unable to create an account. Please try again.')
    } finally {
      setPending(false)
    }
  }

  return (
    <Stack
      component="form"
      onSubmit={handleSubmit}
      spacing={2}
      sx={{ maxWidth: 400, mx: 'auto', p: 3 }}
    >
      <h1>Create your Daily Bread account</h1>
      <TextField
        label="Email"
        type="email"
        autoComplete="email"
        value={email}
        onChange={(event) => setEmail(event.target.value)}
        disabled={pending || confirmationSent}
        required
      />
      <TextField
        label="Password"
        type="password"
        autoComplete="new-password"
        value={password}
        onChange={(event) => setPassword(event.target.value)}
        disabled={pending || confirmationSent}
        required
      />
      <Button
        type="submit"
        variant="contained"
        disabled={pending || confirmationSent}
      >
        {pending ? 'Creating account...' : 'Create account'}
      </Button>
      {errorMessage && <p role="alert">{errorMessage}</p>}
      {confirmationSent && (
        <p role="status">
          Check your email for a confirmation link before signing in.
          If you already have an account, return to sign in.
        </p>
      )}
      <Button type="button" onClick={onSignIn} disabled={pending}>
        Back to sign in
      </Button>
    </Stack>
  )
}
