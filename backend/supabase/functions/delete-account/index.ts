// Supabase Edge Function to delete user account
// This runs with service role permissions, allowing deletion from auth.users
// Deploy with: supabase functions deploy delete-account

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  if (req.method !== 'POST') {
    return new Response(
      JSON.stringify({ error: 'Method not allowed' }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 405,
      }
    )
  }

  try {
    // Create a Supabase client with the service role key
    // This gives us admin permissions to delete from auth.users
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false
        }
      }
    )

    // Get the user from the request JWT
    const authHeader = req.headers.get('Authorization')
    if (!authHeader?.startsWith('Bearer ')) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 401,
        }
      )
    }

    const token = authHeader.replace('Bearer ', '')
    
    // Verify the JWT token and get user
    const { data: { user }, error: userError } = await supabaseAdmin.auth.getUser(token)
    
    if (userError || !user) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        { 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 401 
        }
      )
    }

    const userId = user.id

    // Safety check: if the user owns shops, do not delete the account here.
    // This prevents cascading deletion of unrelated customers' orders.
    const { count: ownedShopCount, error: ownedShopCheckError } = await supabaseAdmin
      .from('shops')
      .select('id', { count: 'exact', head: true })
      .eq('owner_id', userId)

    if (ownedShopCheckError) {
      console.error('Error checking owned shops before account deletion:', ownedShopCheckError)
      return new Response(
        JSON.stringify({
          error: 'Failed to verify owned shops before deletion',
          detail: ownedShopCheckError.message ?? null,
          hint: (ownedShopCheckError as any).hint ?? null,
          code: (ownedShopCheckError as any).code ?? null,
        }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 500,
        }
      )
    }

    if ((ownedShopCount ?? 0) > 0) {
      return new Response(
        JSON.stringify({
          error: 'Cannot delete account while you own shop(s). Please transfer or remove your shop first.',
          code: 'SHOP_OWNER_ACCOUNT_DELETE_BLOCKED',
          ownedShops: ownedShopCount,
        }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 409,
        }
      )
    }

    // Delete from public.users first (triggers CASCADE deletions).
    // If this fails, do NOT delete auth.users to avoid partial deletion.
    const { data: profileRow, error: profileReadError } = await supabaseAdmin
      .from('users')
      .select('id')
      .eq('id', userId)
      .maybeSingle()

    if (profileReadError) {
      console.error('Error checking public.users before deletion:', profileReadError)
      return new Response(
        JSON.stringify({
          error: 'Failed to verify user profile before deletion',
          detail: profileReadError.message ?? null,
          hint: (profileReadError as any).hint ?? null,
        }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 500,
        }
      )
    }

    if (profileRow != null) {
      const { error: publicDeleteError } = await supabaseAdmin
        .from('users')
        .delete()
        .eq('id', userId)

      if (publicDeleteError) {
        console.error('Error deleting from public.users:', publicDeleteError)
        // Include detail/hint so the client log shows which FK constraint fired.
        return new Response(
          JSON.stringify({
            error: 'Failed to delete user data',
            detail: publicDeleteError.message ?? null,
            hint: (publicDeleteError as any).hint ?? null,
            code: (publicDeleteError as any).code ?? null,
          }),
          {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 500,
          }
        )
      }
    }

    // Delete from auth.users (requires service role)
    const { error: authDeleteError } = await supabaseAdmin.auth.admin.deleteUser(userId)

    if (authDeleteError) {
      console.error('Error deleting from auth.users:', authDeleteError)
      return new Response(
        JSON.stringify({ error: 'Failed to delete auth user' }),
        { 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 500 
        }
      )
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Account deleted successfully',
        publicUserExisted: profileRow != null,
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200 
      }
    )
  } catch (error) {
    console.error('Unexpected error:', error)
    const message = error instanceof Error ? error.message : 'Unknown error occurred'
    return new Response(
      JSON.stringify({ error: message }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500 
      }
    )
  }
})
