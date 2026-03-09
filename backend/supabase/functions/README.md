# Supabase Edge Functions

## Setup

1. Install Supabase CLI:
   ```bash
   brew install supabase/tap/supabase
   ```

2. Login to Supabase:
   ```bash
   supabase login
   ```

3. Link your project:
   ```bash
   cd backend/supabase
   supabase link --project-ref your-project-ref
   ```

## Deploy Functions

### Delete Account Function

This function properly deletes users from both `auth.users` and `public.users`.

Deploy:
```bash
supabase functions deploy delete-account
```

Test locally:
```bash
supabase functions serve delete-account
```

## Environment Variables

Functions automatically have access to:
- `SUPABASE_URL` - Your project URL
- `SUPABASE_SERVICE_ROLE_KEY` - Admin access key (set in dashboard)

## Usage from Flutter

```dart
final response = await supabase.functions.invoke('delete-account');
```
