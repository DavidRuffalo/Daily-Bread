import { useState } from 'react'
import Button from '@mui/material/Button'
import Stack from '@mui/material/Stack'
import TextField from '@mui/material/TextField'
import { supabase } from '../lib/supabase'
import { groupInviteUrl, inviteErrorMessage } from '../lib/groupInvite'

type CreatedInvite = { token: string; expires_at: string }

export default function GroupInviteControls({ groupId }: { groupId: string }) {
  const [invite, setInvite] = useState<CreatedInvite | null>(null)
  const [pending, setPending] = useState(false)
  const [error, setError] = useState('')
  const [message, setMessage] = useState('')

  async function createInvite() {
    if (pending) return
    setPending(true)
    setError('')
    setMessage('')
    setInvite(null)
    try {
      const { data, error: requestError } = await supabase
        .rpc('create_group_invite', { target_group_id: groupId })
        .single<CreatedInvite>()
      if (requestError) {
        setError(inviteErrorMessage(requestError, 'Unable to create an invite link. Check your connection and try again.'))
        return
      }
      setInvite(data)
      setMessage('Invite link ready to share.')
    } catch {
      setError('Unable to create an invite link. Check your connection and try again.')
    } finally {
      setPending(false)
    }
  }

  async function revokeInvite() {
    if (pending) return
    setPending(true)
    setError('')
    setMessage('')
    try {
      const { error: requestError } = await supabase.rpc('revoke_group_invite', { target_group_id: groupId })
      if (requestError) {
        setError(inviteErrorMessage(requestError, 'Unable to revoke the invite link. Check your connection and try again.'))
        return
      }
      setInvite(null)
      setMessage('The invite link has been revoked. Existing members keep their access.')
    } catch {
      setError('Unable to revoke the invite link. Check your connection and try again.')
    } finally {
      setPending(false)
    }
  }

  async function copyInvite() {
    if (!invite) return
    setMessage('')
    setError('')
    try {
      await navigator.clipboard.writeText(groupInviteUrl(invite.token))
      setMessage('Invite link copied.')
    } catch {
      setError('Unable to copy automatically. Select and copy the link from the field.')
    }
  }

  return (
    <Stack spacing={2} aria-labelledby="invite-controls-heading" aria-busy={pending}>
      <h3 id="invite-controls-heading">Invite members</h3>
      <p>Anyone with this link can sign in and join as a member. Links last seven days. Creating a new link replaces the previous one.</p>
      <Button variant="contained" onClick={createInvite} disabled={pending}>
        {pending ? 'Updating invite...' : 'Create new invite link'}
      </Button>
      {invite && (
        <>
          <TextField
            label="Invite link"
            value={groupInviteUrl(invite.token)}
            slotProps={{ input: { readOnly: true } }}
            onFocus={(event) => event.target.select()}
            helperText={`Expires ${new Date(invite.expires_at).toLocaleString()}`}
          />
          <Button onClick={copyInvite} disabled={pending}>Copy invite link</Button>
        </>
      )}
      <Button variant="outlined" onClick={revokeInvite} disabled={pending}>Revoke invite link</Button>
      {error && <p role="alert">{error}</p>}
      {message && <p role="status">{message}</p>}
    </Stack>
  )
}
