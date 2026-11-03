import { useState, type FormEvent } from 'react'
import Button from '@mui/material/Button'
import { supabase } from '../lib/supabase'
import Stack from '@mui/material/Stack'
import TextField from '@mui/material/TextField'

export default function LoginForm() {
    const [email, setEmail] = useState('')
    const [password, setPassword] = useState('')
    const [pending, setPending] = useState(false)
    const [message, setMessage] = useState('')

    async function handleSubmit(event: FormEvent<HTMLFormElement>) {
        event.preventDefault()
        if (pending) return

        setPending(true)
        setMessage('')

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
        </Stack>
    )
}