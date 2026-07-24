// send-push edge function.
// Invoked by Supabase Database Webhooks on INSERT into messages / calls /
// friendships. Looks up the recipient's FCM tokens and sends via FCM v1.
//
// Deploy with "Verify JWT" OFF — the gate is the x-push-secret header below
// (a valid Supabase JWT alone is NOT enough: the anon key is public, so
// verify_jwt would let anyone spam pushes). The webhook must send this header.
//
// Required function secrets:
//   FIREBASE_SERVICE_ACCOUNT  full service-account JSON (one line)
//   PUSH_SECRET               shared secret, also set on the webhook header
//   SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY are auto-injected.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { SignJWT, importPKCS8 } from 'https://esm.sh/jose@5'

const sa = JSON.parse(Deno.env.get('FIREBASE_SERVICE_ACCOUNT')!)
const PROJECT_ID = sa.project_id

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
)

// Cache the OAuth access token in memory (~1h) to avoid re-minting per call.
let cached: { token: string; exp: number } | null = null

async function getAccessToken(): Promise<string> {
  const now = Math.floor(Date.now() / 1000)
  if (cached && cached.exp > now + 60) return cached.token

  const key = await importPKCS8(sa.private_key, 'RS256')
  const jwt = await new SignJWT({
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
  })
    .setProtectedHeader({ alg: 'RS256' })
    .setIssuer(sa.client_email)
    .setSubject(sa.client_email)
    .setAudience('https://oauth2.googleapis.com/token')
    .setIssuedAt(now)
    .setExpirationTime(now + 3600)
    .sign(key)

  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body:
      `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  })
  const data = await res.json()
  cached = { token: data.access_token, exp: now + 3600 }
  return data.access_token
}

async function nameOf(userId: string): Promise<string> {
  const { data } = await supabase
    .from('users').select('username').eq('id', userId).maybeSingle()
  return data?.username ?? 'Someone'
}

// Map an inserted row -> push, or null if this event shouldn't notify.
async function build(payload: any) {
  const r = payload.record
  switch (payload.table) {
    case 'messages':
      return {
        recipient: r.receiver_id,
        title: await nameOf(r.sender_id),
        body: r.content && r.content.length ? r.content : 'Sent you a message',
        data: { type: 'message', sender_id: r.sender_id },
      }
    case 'calls':
      if (r.status !== 'ringing') return null
      return {
        recipient: r.receiver_id,
        title: await nameOf(r.caller_id),
        body: `Incoming ${r.call_type} call`,
        data: { type: 'call', call_id: r.id },
      }
    case 'friendships':
      if (r.status !== 'pending') return null
      return {
        recipient: r.addressee_id,
        title: 'New friend request',
        body: `${await nameOf(r.requester_id)} wants to be friends`,
        data: { type: 'friend_request' },
      }
    default:
      return null
  }
}

Deno.serve(async (req) => {
  if (req.headers.get('x-push-secret') !== Deno.env.get('PUSH_SECRET')) {
    return new Response('Unauthorized', { status: 401 })
  }
  try {
    const msg = await build(await req.json())
    if (!msg) return new Response('skip', { status: 200 })

    const { data: tokens } = await supabase
      .from('device_tokens').select('token').eq('user_id', msg.recipient)
    if (!tokens?.length) return new Response('no tokens', { status: 200 })

    const access = await getAccessToken()
    const url =
      `https://fcm.googleapis.com/v1/projects/${PROJECT_ID}/messages:send`

    // ponytail: fire-and-forget per token; dead-token pruning (FCM 404/UNREGISTERED)
    // skipped — add a delete on those responses if stale tokens pile up.
    await Promise.all(tokens.map(({ token }) =>
      fetch(url, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${access}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          message: {
            token,
            notification: { title: msg.title, body: msg.body },
            data: Object.fromEntries(
              Object.entries(msg.data).map(([k, v]) => [k, String(v)]),
            ),
            android: { priority: 'high' },
          },
        }),
      })
    ))
    return new Response('sent', { status: 200 })
  } catch (e) {
    return new Response(JSON.stringify({ error: e.message }), { status: 500 })
  }
})
