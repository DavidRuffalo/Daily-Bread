const recoveryKey = 'daily-bread.password-recovery-user'

// This marker restores the screen after refresh. Supabase still authorizes every update.
export function readRecoveryUser() {
  try {
    return window.sessionStorage.getItem(recoveryKey)
  } catch {
    return null
  }
}

export function storeRecoveryUser(userId: string | null) {
  try {
    if (userId) window.sessionStorage.setItem(recoveryKey, userId)
    else window.sessionStorage.removeItem(recoveryKey)
  } catch {
    // Recovery still works in this page when browser storage is unavailable.
  }
}
