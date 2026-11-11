import { useEffect, useRef, useState } from 'react'
import Button from '@mui/material/Button'
import Stack from '@mui/material/Stack'
import { supabase } from '../lib/supabase'
import { inviteErrorMessage } from '../lib/groupInvite'

type InvitePreview = {
  group_id: string
  group_name: string
  expires_at: string
  already_member: boolean
}

type JoinGroupInviteProps = {
  token: string
  onJoined: (groupId: string) => void
  onDismiss: () => void
}

export default function JoinGroupInvite({ token, onJoined, onDismiss }: JoinGroupInviteProps) {
  const [preview, setPreview] = useState<InvitePreview | null>(null)
  const [loading, setLoading] = useState(true)
  const [attempt, setAttempt] = useState(0)
  const [error, setError] = useState('')
  const [joining, setJoining] = useState(false)
  const mounted = useRef(false)

  useEffect(() => {
    mounted.current = true
    return () => { mounted.current = false }
  }, [])

  useEffect(() => {
    let ignore = false
    const controller = new AbortController()

    async function loadInvite() {
      try {
        const { data, error: requestError } = await supabase
          .rpc('preview_group_invite', { invite_token: token })
          .abortSignal(controller.signal)
          .single<InvitePreview>()
        if (ignore) return
        if (requestError) {
          setError(inviteErrorMessage(requestError, 'Unable to load the invitation. Check your connection and try again.'))
          return
        }
        setPreview(data)
      } catch {
        if (!ignore) setError('Unable to load the invitation. Check your connection and try again.')
      } finally {
        if (!ignore) setLoading(false)
      }
    }

    void loadInvite()
    return () => {
      ignore = true
      controller.abort()
    }
  }, [token, attempt])

  async function joinGroup() {
    if (joining || !preview) return
    setJoining(true)
    setError('')
    try {
      const { data, error: requestError } = await supabase
        .rpc('join_group_by_invite', { invite_token: token })
        .single<{ id: string }>()
      if (!mounted.current) return
      if (requestError) {
        setError(inviteErrorMessage(requestError, 'Unable to confirm joining. Check your connection and try again.'))
        return
      }
      onJoined(data.id)
    } catch {
      if (mounted.current) setError('Unable to confirm joining. Check your connection and try again.')
    } finally {
      if (mounted.current) setJoining(false)
    }
  }

  return (
    <Stack component="section" spacing={2} aria-labelledby="join-group-heading" aria-busy={loading || joining}>
      <h2 id="join-group-heading">Group invitation</h2>
      {loading ? <p role="status">Loading invitation...</p> : preview ? (
        <>
          <h3 style={{ overflowWrap: 'anywhere' }}>{preview.group_name}</h3>
          <p>{preview.already_member ? 'You already belong to this group.' : 'Join this group as a member.'}</p>
          <Button variant="contained" onClick={joinGroup} disabled={joining}>
            {joining ? 'Opening group...' : preview.already_member ? 'Open group' : 'Join group'}
          </Button>
        </>
      ) : (
        <Button onClick={() => {
          setError('')
          setLoading(true)
          setAttempt((current) => current + 1)
        }}>Retry loading invitation</Button>
      )}
      {error && <p role="alert">{error}</p>}
      <Button onClick={onDismiss} disabled={joining}>Back to my groups</Button>
    </Stack>
  )
}
