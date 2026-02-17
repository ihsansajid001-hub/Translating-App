-- FIX REGISTRATION ISSUE
-- This will allow the backend (using service_role) to insert user profiles
-- Run this in Supabase SQL Editor

-- Step 1: Check current RLS status
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' AND tablename = 'users';

-- Step 2: Temporarily disable RLS on users table to allow service_role to insert
-- The service_role key should bypass RLS, but let's make sure
ALTER TABLE users DISABLE ROW LEVEL SECURITY;

-- Step 3: Test by creating a profile for the existing auth user
DO $$
DECLARE
    user_uuid UUID;
BEGIN
    -- Get the user ID from auth.users
    SELECT id INTO user_uuid 
    FROM auth.users 
    WHERE email = 'ihsanajid001@gmail.com' 
    LIMIT 1;
    
    IF user_uuid IS NOT NULL THEN
        -- Create user profile
        INSERT INTO users (id, username, email, preferred_language)
        VALUES (
            user_uuid,
            'ihsanajid',
            'ihsanajid001@gmail.com',
            'en'
        )
        ON CONFLICT (id) DO UPDATE 
        SET username = 'ihsanajid',
            email = 'ihsanajid001@gmail.com';
        
        -- Create user preferences
        INSERT INTO user_preferences (user_id, auto_play_audio, show_original_text, theme)
        VALUES (
            user_uuid,
            true,
            true,
            'light'
        )
        ON CONFLICT (user_id) DO NOTHING;
        
        RAISE NOTICE 'User profile created for ihsanajid001@gmail.com';
    END IF;
END $$;

-- Step 4: Re-enable RLS with proper policies
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Step 5: Drop old restrictive policies
DROP POLICY IF EXISTS users_insert_own ON users;
DROP POLICY IF EXISTS users_select_own ON users;
DROP POLICY IF EXISTS users_update_own ON users;

-- Step 6: Create new policies that work correctly
-- Allow service_role to do anything (this is automatic, but let's be explicit)
-- Allow authenticated users to insert their own profile
CREATE POLICY users_insert_own ON users
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = id);

-- Allow users to read their own data
CREATE POLICY users_select_own ON users
    FOR SELECT
    TO authenticated
    USING (auth.uid() = id);

-- Allow users to update their own data
CREATE POLICY users_update_own ON users
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- Allow service_role to bypass all policies (this should be default)
-- No explicit policy needed for service_role as it bypasses RLS

-- Step 7: Verify
SELECT 
    u.id,
    u.username,
    u.email,
    u.preferred_language,
    u.created_at
FROM users u
WHERE u.email = 'ihsanajid001@gmail.com';

-- Step 8: Check all policies
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd
FROM pg_policies
WHERE tablename = 'users';
