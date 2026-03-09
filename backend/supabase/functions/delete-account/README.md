# Supabase Edge Functions

This directory contains serverless functions deployed to Supabase Edge Runtime (Deno).

## Available Functions

### delete-account
Properly deletes user accounts from both `auth.users` and `public.users` tables.
Requires service role permissions.

## Deployment

Before deploying, make sure you have:
1. Supabase CLI installed
2. Logged in to Supabase
3. Linked your project

```bash
# Deploy a function
cd /Users/nikunjwadhwa/code/nearmart/backend/supabase
supabase functions deploy delete-account

# Deploy all functions
supabase functions deploy
```

## Local Development

```bash
# Serve function locally
supabase functions serve delete-account

# Test locally
curl -i --location --request POST 'http://localhost:54321/functions/v1/delete-account' \
  --header 'Authorization: Bearer YOUR_USER_JWT' \
  --header 'Content-Type: application/json'
```

## TypeScript Errors in VSCode

If you see TypeScript errors about Deno modules, they can be safely ignored. These functions use Deno runtime, not Node.js, and will work correctly when deployed to Supabase.
