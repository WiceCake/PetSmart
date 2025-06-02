// Supabase Edge Function for Push Notifications
// Simplified version for Flutter local notifications

import { createClient } from 'jsr:@supabase/supabase-js@2'

console.log('Push Notification Function Started')

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface NotificationRequest {
  user_id: string
  title: string
  body: string
  type?: string
  data?: Record<string, any>
}

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
)

Deno.serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { user_id, title, body, type = 'system', data = {} }: NotificationRequest = await req.json()

    if (!user_id || !title || !body) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: user_id, title, body' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Check if push notifications are enabled for this user and type
    const { data: preferences, error: prefError } = await supabase
      .from('notification_preferences')
      .select('push_enabled')
      .eq('user_id', user_id)
      .eq('type', type)
      .single()

    if (prefError && prefError.code !== 'PGRST116') {
      console.error('Error checking preferences:', prefError)
    }

    // If preferences exist and push is disabled, skip sending
    if (preferences && !preferences.push_enabled) {
      return new Response(
        JSON.stringify({ message: 'Push notifications disabled for this user and type' }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Get user's device tokens
    const { data: tokens, error: tokenError } = await supabase
      .from('push_tokens')
      .select('device_token, platform')
      .eq('user_id', user_id)

    if (tokenError) {
      console.error('Error fetching device tokens:', tokenError)
      return new Response(
        JSON.stringify({ error: 'Failed to fetch device tokens' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    if (!tokens || tokens.length === 0) {
      return new Response(
        JSON.stringify({ message: 'No device tokens found for user' }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    console.log(`Found ${tokens.length} device tokens for user ${user_id}`)

    // For Flutter local notifications, we just log the notification
    // In a real implementation, you would use Firebase Cloud Messaging or similar
    console.log('Push notification details:', {
      user_id,
      title,
      body,
      type,
      data,
      device_count: tokens.length
    })

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Push notification processed successfully',
        device_count: tokens.length
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Error in push notification function:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error', details: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
