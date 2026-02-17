-- Create Test User for Login
-- Run this in Supabase SQL Editor: https://supabase.com/dashboard/project/YOUR_PROJECT/sql

-- Test User Credentials:
-- Email: test@translator.com
-- Password: Test123456!
-- Username: testuser

-- Step 1: Create user in Supabase Auth
-- Note: You need to do this via Supabase Dashboard > Authentication > Users > Add User
-- OR use the Supabase API

-- For now, let's create a user that you can manually add via Dashboard
-- Go to: https://supabase.com/dashboard/project/blqqqxsijgvydczjaayy/auth/users
-- Click "Add User" and use these details:
-- Email: test@translator.com
-- Password: Test123456!
-- Auto Confirm User: YES

-- After creating the user in Auth, get the UUID and run this:
-- Replace 'USER_UUID_HERE' with the actual UUID from the auth.users table

-- Step 2: Create user profile (run this AFTER creating auth user)
-- First, get the user ID from auth.users
DO $$
DECLARE
    test_user_id UUID;
BEGIN
    -- Get the user ID from auth.users
    SELECT id INTO test_user_id 
    FROM auth.users 
    WHERE email = 'test@translator.com' 
    LIMIT 1;
    
    -- If user exists in auth, create profile
    IF test_user_id IS NOT NULL THEN
        -- Insert into users table
        INSERT INTO users (id, username, email, preferred_language)
        VALUES (
            test_user_id,
            'testuser',
            'test@translator.com',
            'en'
        )
        ON CONFLICT (id) DO UPDATE 
        SET username = 'testuser',
            email = 'test@translator.com',
            preferred_language = 'en';
        
        -- Create user preferences
        INSERT INTO user_preferences (user_id, auto_play_audio, show_original_text, theme)
        VALUES (
            test_user_id,
            true,
            true,
            'light'
        )
        ON CONFLICT (user_id) DO NOTHING;
        
        RAISE NOTICE 'Test user profile created successfully!';
    ELSE
        RAISE NOTICE 'Please create the auth user first in Supabase Dashboard';
    END IF;
END $$;

-- Verify the user was created
SELECT 
    u.id,
    u.username,
    u.email,
    u.preferred_language,
    u.created_at
FROM users u
WHERE u.email = 'test@translator.com';
