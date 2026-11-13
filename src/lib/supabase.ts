import { createClient } from '@supabase/supabase-js'
import { storeRecoveryUser } from './passwordRecovery'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseKey = import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY

if (!supabaseUrl || !supabaseKey) {
    throw new Error('Missing Supabase URL or publishable key')
}

export const supabase = createClient(supabaseUrl, supabaseKey)

// Capture a fast recovery callback even before React mounts its auth listener.
supabase.auth.onAuthStateChange((event, session) => {
    if (event === 'PASSWORD_RECOVERY' && session) storeRecoveryUser(session.user.id)
})
