import { useEffect, useState, type FormEvent } from 'react'
import Button from '@mui/material/Button'
import Stack from '@mui/material/Stack'
import TextField from '@mui/material/TextField'
import { supabase } from '../lib/supabase'

type ProfileFormProps = {
  userId: string
}

type Profile = {
  display_name: string | null
}

export default function ProfileForm({ userId }: ProfileFormProps) {
  const [displayName, setDisplayName] = useState('')
  const [savedName, setSavedName] = useState<string | null>(null)
  const [loading, setLoading] = useState(true)
  const [loadAttempt, setLoadAttempt] = useState(0)
  const [loadError, setLoadError] = useState('')
  const [saving, setSaving] = useState(false)
  const [saveError, setSaveError] = useState('')
  const [message, setMessage] = useState('')

  useEffect(() => {
    let ignore = false
    const controller = new AbortController()

    async function loadProfile() {
      try {
        const { data, error } = await supabase
          .from('profiles')
          .select('display_name')
          .eq('id', userId)
          .abortSignal(controller.signal)
          .single<Profile>()

        if (ignore) return
        if (error) throw error

        setSavedName(data.display_name)
        setDisplayName(data.display_name ?? '')
      } catch {
        if (!ignore) {
          setLoadError('Unable to load your profile. Check your connection and try again.')
        }
      } finally {
        if (!ignore) setLoading(false)
      }
    }

    void loadProfile()

    return () => {
      ignore = true
      controller.abort()
    }
  }, [userId, loadAttempt])

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    if (saving || loading || loadError) return

    setSaveError('')
    setMessage('')
    const name = displayName.trim()

    if (Array.from(name).length > 80) {
      setSaveError('Use a display name of 80 characters or fewer.')
      return
    }

    setSaving(true)

    try {
      const { data, error } = await supabase
        .from('profiles')
        .update({ display_name: name || null })
        .eq('id', userId)
        .select('display_name')
        .single<Profile>()

      if (error) throw error

      setSavedName(data.display_name)
      setDisplayName(data.display_name ?? '')
      setMessage('Profile saved.')
    } catch {
      setSaveError('Unable to save your profile. Check your connection and try again.')
    } finally {
      setSaving(false)
    }
  }

  if (loading) {
    return <p role="status">Loading your profile...</p>
  }

  if (loadError) {
    return (
      <Stack spacing={2}>
        <p role="alert">{loadError}</p>
        <Button
          type="button"
          onClick={() => {
            setLoading(true)
            setLoadError('')
            setLoadAttempt((attempt) => attempt + 1)
          }}
        >
          Retry loading profile
        </Button>
      </Stack>
    )
  }

  return (
    <Stack
      component="form"
      onSubmit={handleSubmit}
      spacing={2}
      aria-labelledby="profile-heading"
      aria-busy={saving}
    >
      <h2 id="profile-heading">{savedName ? `Welcome, ${savedName}` : 'Your profile'}</h2>
      <TextField
        label="Display name"
        autoComplete="nickname"
        helperText="Optional. Up to 80 characters. Leave blank to clear."
        value={displayName}
        onChange={(event) => {
          setDisplayName(event.target.value)
          setSaveError('')
          setMessage('')
        }}
        disabled={saving}
      />
      <Button
        type="submit"
        variant="contained"
        disabled={saving || displayName.trim() === (savedName ?? '')}
      >
        {saving ? 'Saving...' : 'Save profile'}
      </Button>
      {saveError && <p role="alert">{saveError}</p>}
      {message && <p role="status">{message}</p>}
    </Stack>
  )
}
