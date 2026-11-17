import { useEffect, useRef, useState, type FormEvent } from 'react'
import Button from '@mui/material/Button'
import Stack from '@mui/material/Stack'
import TextField from '@mui/material/TextField'
import { supabase } from '../lib/supabase'
import GroupInviteControls from './GroupInviteControls'
import GroupCheckIns from './GroupCheckIns'

type Group = {
  id: string
  name: string
  created_by: string
  created_at: string
}

export default function GroupsDashboard({ userId, initialGroupId = null }: { userId: string; initialGroupId?: string | null }) {
  const [groups, setGroups] = useState<Group[]>([])
  const [loading, setLoading] = useState(true)
  const [loadAttempt, setLoadAttempt] = useState(0)
  const [loadError, setLoadError] = useState('')
  const [name, setName] = useState('')
  const [creating, setCreating] = useState(false)
  const [createError, setCreateError] = useState('')
  const [message, setMessage] = useState('')
  const [selectedId, setSelectedId] = useState<string | null>(initialGroupId)
  const request = useRef<{ id: string; name: string } | null>(null)

  useEffect(() => {
    let ignore = false
    const controller = new AbortController()

    async function loadGroups() {
      try {
        const { data, error } = await supabase
          .from('groups')
          .select('id, name, created_by, created_at')
          .order('created_at', { ascending: false })
          .order('id')
          .abortSignal(controller.signal)
          .returns<Group[]>()

        if (ignore) return
        if (error) throw error
        setGroups(data)
      } catch {
        if (!ignore) setLoadError('Unable to load your groups. Check your connection and try again.')
      } finally {
        if (!ignore) setLoading(false)
      }
    }

    void loadGroups()
    return () => {
      ignore = true
      controller.abort()
    }
  }, [userId, loadAttempt])

  function reloadGroups() {
    setLoading(true)
    setLoadError('')
    setLoadAttempt((attempt) => attempt + 1)
  }

  async function handleCreate(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    if (creating || loading || loadError) return
    setCreateError('')
    setMessage('')
    const trimmedName = name.trim()
    if (Array.from(trimmedName).length < 1 || Array.from(trimmedName).length > 80) {
      setCreateError('Use a group name between 1 and 80 characters.')
      return
    }

    setCreating(true)
    try {
      if (!request.current || request.current.name !== trimmedName) {
        request.current = { id: crypto.randomUUID(), name: trimmedName }
      }
      const { data, error } = await supabase
        .rpc('create_group', { group_name: trimmedName, group_id: request.current.id })
        .single<Group>()
      if (error) throw error

      setGroups((current) => [data, ...current.filter((group) => group.id !== data.id)])
      setName('')
      request.current = null
      setMessage(`Created ${data.name}. You are the owner.`)
    } catch {
      setCreateError('Unable to confirm group creation. Check your connection and try again. Your group name has been kept.')
    } finally {
      setCreating(false)
    }
  }

  const selectedGroup = groups.find((group) => group.id === selectedId)
  if (selectedGroup) {
    return (
      <Stack component="section" spacing={2} aria-labelledby="group-heading">
        <Button onClick={() => setSelectedId(null)}>Back to my groups</Button>
        <h2 id="group-heading" style={{ overflowWrap: 'anywhere' }}>{selectedGroup.name}</h2>
        <p>Your role: {selectedGroup.created_by === userId ? 'Owner' : 'Member'}</p>
        <GroupCheckIns key={`check-ins-${selectedGroup.id}-${userId}`} groupId={selectedGroup.id} userId={userId} />
        {selectedGroup.created_by === userId && <GroupInviteControls key={selectedGroup.id} groupId={selectedGroup.id} />}
      </Stack>
    )
  }

  return (
    <Stack component="section" spacing={2} aria-labelledby="groups-heading">
      <h2 id="groups-heading">My groups</h2>
      {loading ? <p role="status">Loading your groups...</p> : loadError ? (
        <>
          <p role="alert">{loadError}</p>
          <Button onClick={reloadGroups}>Retry loading groups</Button>
        </>
      ) : (
        <>
          {groups.length === 0 ? <p>You have no groups yet. Create your first group below.</p> : (
            <Stack component="ul" spacing={1} sx={{ listStyle: 'none', p: 0 }}>
              {groups.map((group) => (
                <li key={group.id}>
                  <Button
                    variant="outlined"
                    fullWidth
                    onClick={() => setSelectedId(group.id)}
                    sx={{ overflowWrap: 'anywhere', textTransform: 'none' }}
                  >
                    {group.name} — {group.created_by === userId ? 'Owner' : 'Member'}
                  </Button>
                </li>
              ))}
            </Stack>
          )}
          <Button onClick={reloadGroups} disabled={creating}>Refresh groups</Button>
          <Stack component="form" onSubmit={handleCreate} spacing={2} aria-labelledby="create-group-heading" aria-busy={creating}>
            <h3 id="create-group-heading">Create a group</h3>
            <TextField
              label="Group name"
              required
              value={name}
              disabled={creating}
              helperText="Between 1 and 80 characters."
              onChange={(event) => {
                setName(event.target.value)
                setCreateError('')
                setMessage('')
              }}
            />
            <Button type="submit" variant="contained" disabled={creating || !name.trim()}>
              {creating ? 'Creating group...' : 'Create group'}
            </Button>
            {createError && <p role="alert">{createError}</p>}
            {message && <p role="status">{message}</p>}
          </Stack>
        </>
      )}
    </Stack>
  )
}
