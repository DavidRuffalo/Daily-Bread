import { useEffect, useRef, useState, type FormEvent } from 'react'
import Button from '@mui/material/Button'
import MenuItem from '@mui/material/MenuItem'
import Stack from '@mui/material/Stack'
import TextField from '@mui/material/TextField'
import { supabase } from '../lib/supabase'

const statusLabels = { on_track: 'On track', needs_support: 'Need support' }
type CheckInStatus = keyof typeof statusLabels
type CheckIn = {
  id: string
  group_id: string
  user_id: string
  author_name: string
  status: CheckInStatus
  note: string
  created_at: string
}

export default function GroupCheckIns({ groupId, userId }: { groupId: string; userId: string }) {
  const [checkIns, setCheckIns] = useState<CheckIn[]>([])
  const [loading, setLoading] = useState(true)
  const [loadAttempt, setLoadAttempt] = useState(0)
  const [loadError, setLoadError] = useState('')
  const [status, setStatus] = useState<CheckInStatus | ''>('')
  const [note, setNote] = useState('')
  const [submitting, setSubmitting] = useState(false)
  const [submitError, setSubmitError] = useState('')
  const [message, setMessage] = useState('')
  const request = useRef<{ id: string; status: CheckInStatus; note: string } | null>(null)

  useEffect(() => {
    let ignore = false
    const controller = new AbortController()

    async function loadCheckIns() {
      try {
        const { data, error } = await supabase
          .from('check_ins')
          .select('id, group_id, user_id, author_name, status, note, created_at')
          .eq('group_id', groupId)
          .order('created_at', { ascending: false })
          .order('id', { ascending: false })
          .limit(20)
          .abortSignal(controller.signal)
          .returns<CheckIn[]>()

        if (ignore) return
        if (error) throw error
        setCheckIns(data)
      } catch {
        if (!ignore) setLoadError('Unable to load check-ins. Check your connection and try again.')
      } finally {
        if (!ignore) setLoading(false)
      }
    }

    void loadCheckIns()
    return () => {
      ignore = true
      controller.abort()
    }
  }, [groupId, userId, loadAttempt])

  function reloadCheckIns() {
    setLoading(true)
    setLoadError('')
    setLoadAttempt((attempt) => attempt + 1)
  }

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    if (submitting || loading || loadError) return
    setSubmitError('')
    setMessage('')
    const trimmedNote = note.trim()
    if (!status || Array.from(trimmedNote).length < 1 || Array.from(trimmedNote).length > 1000) {
      setSubmitError('Choose a status and write an update between 1 and 1,000 characters.')
      return
    }

    setSubmitting(true)
    try {
      if (!request.current || request.current.status !== status || request.current.note !== trimmedNote) {
        request.current = { id: crypto.randomUUID(), status, note: trimmedNote }
      }
      const { data, error } = await supabase
        .rpc('submit_check_in', {
          target_group_id: groupId,
          check_in_id: request.current.id,
          check_in_status: status,
          check_in_note: trimmedNote,
        })
        .single<CheckIn>()
      if (error) {
        if (error.code === '42501') setSubmitError('You must be signed in and belong to this group to post a check-in.')
        else if (error.code === '22023') setSubmitError('Choose a status and write an update between 1 and 1,000 characters.')
        else setSubmitError('Unable to confirm your check-in. Check your connection and try again. Your draft has been kept.')
        return
      }

      setCheckIns((current) => [data, ...current.filter((checkIn) => checkIn.id !== data.id)]
        .sort((first, second) => second.created_at.localeCompare(first.created_at) || second.id.localeCompare(first.id))
        .slice(0, 20))
      setStatus('')
      setNote('')
      request.current = null
      setMessage('Check-in posted.')
    } catch {
      setSubmitError('Unable to confirm your check-in. Check your connection and try again. Your draft has been kept.')
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <Stack component="section" spacing={2} aria-labelledby="check-ins-heading">
      <h3 id="check-ins-heading">Check-ins</h3>
      <Stack component="form" spacing={2} onSubmit={handleSubmit} aria-label="Post a check-in" aria-busy={submitting}>
        <p>Share how you are doing with your goals. Your update and display name are visible to members of this group.</p>
        <TextField
          select
          label="How are you doing?"
          required
          value={status}
          disabled={submitting}
          onChange={(event) => {
            setStatus(event.target.value as CheckInStatus)
            setSubmitError('')
            setMessage('')
          }}
        >
          {Object.entries(statusLabels).map(([value, label]) => <MenuItem key={value} value={value}>{label}</MenuItem>)}
        </TextField>
        <TextField
          label="Your update"
          required
          multiline
          minRows={3}
          helperText="Between 1 and 1,000 characters."
          value={note}
          disabled={submitting}
          onChange={(event) => {
            setNote(event.target.value)
            setSubmitError('')
            setMessage('')
          }}
        />
        <Button type="submit" variant="contained" disabled={submitting || loading || !!loadError || !status || !note.trim()}>
          {submitting ? 'Posting...' : 'Post check-in'}
        </Button>
        {submitError && <p role="alert">{submitError}</p>}
        {message && <p role="status">{message}</p>}
      </Stack>
      <h4>Recent check-ins</h4>
      {loading ? <p role="status">Loading check-ins...</p> : loadError ? (
        <>
          <p role="alert">{loadError}</p>
          <Button onClick={reloadCheckIns}>Retry loading check-ins</Button>
        </>
      ) : (
        <>
          <p>Latest 20 check-ins, newest first.</p>
          <Button onClick={reloadCheckIns} disabled={submitting}>Refresh check-ins</Button>
          {checkIns.length === 0 ? <p>No check-ins yet. Be the first to share an update.</p> : (
            <Stack component="ul" spacing={2} sx={{ listStyle: 'none', p: 0 }}>
              {checkIns.map((checkIn) => (
                <Stack component="li" key={checkIn.id} spacing={1} sx={{ border: 1, borderColor: 'divider', borderRadius: 1, p: 2, overflowWrap: 'anywhere' }}>
                  <strong>{checkIn.author_name}{checkIn.user_id === userId ? ' (you)' : ''} — {statusLabels[checkIn.status]}</strong>
                  <time dateTime={checkIn.created_at}>{new Date(checkIn.created_at).toLocaleString()}</time>
                  <p style={{ whiteSpace: 'pre-wrap' }}>{checkIn.note}</p>
                </Stack>
              ))}
            </Stack>
          )}
        </>
      )}
    </Stack>
  )
}
