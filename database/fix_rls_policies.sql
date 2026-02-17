-- Fix Row Level Security Policies for Registration
-- Run this in Supabase SQL Editor

-- The issue: Users can't insert their own profile during registration
-- Solution: Allow authenticated users to insert their own user record

-- Drop existing policies that might be blocking
DROP POLICY IF EXISTS users_insert_own ON users;

-- Create a new policy that allows users to insert their own profile
CREATE POLICY users_insert_own ON users
    FOR INSERT
    WITH CHECK (auth.uid() = id);

-- Also, we need to allow the service role to bypass RLS for registration
-- This is already handled by using SUPABASE_SERVICE_KEY in the backend

-- Verify the policies
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE tablename = 'users';

-- Test: Try to insert a user (this should work now)
-- Note: Replace 'YOUR_USER_ID' with an actual UUID from auth.users
/*
INSERT INTO users (id, username, email, preferred_language)
VALUES (
    'YOUR_USER_ID',
    'testuser',
    'test@example.com',
    'en'
);
*/
