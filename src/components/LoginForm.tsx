import { useEffect, useState, type FormEvent } from 'react'
import Button from '@mui/material/Button'
import { supabase } from '../lib/supabase'
import Stack from '@mui/material/Stack'
import TextField from '@mui/material/TextField'

type LoginFormProps = {
    onSignup: () => void
}

function getConfirmationError(hash: string) {
    const params = new URLSearchParams(hash.slice(1))
    if (!params.has('error') && !params.has('error_code') && !params.has('error_description')) {
        return ''
    }

    if (params.get('error_code') === 'otp_expired') {
        return 'This email link is invalid, expired, or has already been used. If you already confirmed your email, sign in below. Otherwise, use the latest confirmation email.'
    }

    return 'We could not confirm your email with this link. Please use the latest confirmation email, or sign in if your email is already confirmed.'
}

export default function LoginForm({ onSignup }: LoginFormProps) {
    const [email, setEmail] = useState('')
    const [password, setPassword] = useState('')
    const [pending, setPending] = useState(false)
    const [message, setMessage] = useState('')
    const [confirmationError, setConfirmationError] = useState(
        () => getConfirmationError(window.location.hash),
    )

    useEffect(() => {
        if (!getConfirmationError(window.location.hash)) return

        const params = new URLSearchParams(window.location.hash.slice(1))
        params.delete('error')
        params.delete('error_code')
        params.delete('error_description')
        const remainingHash = params.toString()
        window.history.replaceState(
            window.history.state,
            '',
            window.location.pathname + window.location.search
                + (remainingHash ? `#${remainingHash}` : ''),
        )
    }, [])

    async function handleSubmit(event: FormEvent<HTMLFormElement>) {
        event.preventDefault()
        if (pending) return

        setPending(true)
        setMessage('')
        setConfirmationError('')

        try {
            const { error } = await supabase.auth.signInWithPassword({
                email: email.trim(),
                password,
            })

            if (error) {
                setMessage(error.message)
                return
            }

            setMessage('Signed in successfully!')
            setPassword('')
        } catch {
            setMessage('Unable to sign in. Please try again.')
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
            <h1>Sign in to Daily Bread</h1>
            {confirmationError && <p role="alert">{confirmationError}</p>}
            <TextField
                label="Email"
                type="email"
                autoComplete="email"
                value={email}
                onChange={(event) => setEmail(event.target.value)}
                required
            />
            <TextField
                label="Password"
                type="password"
                autoComplete="current-password"
                value={password}
                onChange={(event) => setPassword(event.target.value)}
                required
            />
            <Button type="submit" variant="contained" disabled={pending}>
                {pending ? 'Signing in…' : 'Sign in'}
            </Button>

            {message && <p role="status">{message}</p>}
            <Button type="button" onClick={onSignup} disabled={pending}>
                Create an account
            </Button>
        </Stack>
    )
}
