export const pendingInviteKey = 'daily-bread.pending-group-invite'

export function inviteFromHash(hash: string): string | null {
  const params = new URLSearchParams(hash.replace(/^#/, ''))
  if (!params.has('invite')) return null
  const token = params.get('invite') ?? ''
  return /^[0-9a-f]{64}$/.test(token) ? token : 'invalid'
}

export function withoutInviteHash(hash: string): string {
  const params = new URLSearchParams(hash.replace(/^#/, ''))
  params.delete('invite')
  const remaining = params.toString()
  return remaining ? `#${remaining}` : ''
}

export function readPendingInvite(): string | null {
  const token = inviteFromHash(window.location.hash)
  if (token !== null) return token
  try {
    return window.sessionStorage.getItem(pendingInviteKey)
  } catch {
    return null
  }
}

export function groupInviteUrl(token: string): string {
  const url = new URL(import.meta.env.BASE_URL, window.location.origin)
  url.hash = new URLSearchParams({ invite: token }).toString()
  return url.href
}

export function inviteErrorMessage(error: { code?: string }, fallback: string): string {
  if (error.code === '22023') return 'This invite link is invalid, expired, or revoked. Ask the group owner for a new link.'
  if (error.code === '42501') return 'Your account cannot perform this action. Check that you are signed in with the correct account.'
  return fallback
}
