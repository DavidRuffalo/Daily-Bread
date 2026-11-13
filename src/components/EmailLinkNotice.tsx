import { useEffect, useState } from 'react'
import Stack from '@mui/material/Stack'

function readError() {
  const params = new URLSearchParams(window.location.hash.slice(1))
  if (!params.has('error') && !params.has('error_code') && !params.has('error_description')) return ''
  return params.get('error_code') === 'otp_expired'
    ? 'This email link is invalid, expired, or has already been used. Sign in if your email is confirmed, or use the latest confirmation email. To reset your password, sign out if needed and select Forgot password to request a new link.'
    : 'We could not use this email link. Use the latest confirmation email, or sign in. To reset your password, sign out if needed and select Forgot password to request a new link.'
}

export default function EmailLinkNotice() {
  const [message] = useState(readError)
  useEffect(() => {
    if (!message) return
    const params = new URLSearchParams(window.location.hash.slice(1))
    params.delete('error')
    params.delete('error_code')
    params.delete('error_description')
    const hash = params.toString()
    window.history.replaceState(window.history.state, '',
      window.location.pathname + window.location.search + (hash ? `#${hash}` : ''))
  }, [message])

  return message ? <Stack sx={{ maxWidth: 400, mx: 'auto', px: 3 }}><p role="alert">{message}</p></Stack> : null
}
