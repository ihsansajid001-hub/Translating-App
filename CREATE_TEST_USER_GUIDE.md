# 🔐 Create Test User - Step by Step Guide

## Test User Credentials
```
Email: test@translator.com
Password: Test123456!
Username: testuser
```

---

## Method 1: Via Supabase Dashboard (EASIEST) ✅

### Step 1: Go to Supabase Dashboard
1. Open: https://supabase.com/dashboard/project/blqqqxsijgvydczjaayy/auth/users
2. Login to your Supabase account

### Step 2: Add User
1. Click the **"Add User"** button (top right)
2. Fill in:
   - **Email**: `test@translator.com`
   - **Password**: `Test123456!`
   - **Auto Confirm User**: ✅ YES (check this box!)
3. Click **"Create User"**

### Step 3: Create User Profile
1. Go to SQL Editor: https://supabase.com/dashboard/project/blqqqxsijgvydczjaayy/sql
2. Click **"New Query"**
3. Copy and paste this SQL:

```sql
-- Get the user ID and create profile
DO $$
DECLARE
    test_user_id UUID;
BEGIN
    -- Get the user ID from auth.users
    SELECT id INTO test_user_id 
    FROM auth.users 
    WHERE email = 'test@translator.com' 
    LIMIT 1;
    
    -- Create user profile
    INSERT INTO users (id, username, email, preferred_language)
    VALUES (
        test_user_id,
        'testuser',
        'test@translator.com',
        'en'
    )
    ON CONFLICT (id) DO UPDATE 
    SET username = 'testuser';
    
    -- Create user preferences
    INSERT INTO user_preferences (user_id, auto_play_audio, show_original_text, theme)
    VALUES (
        test_user_id,
        true,
        true,
        'light'
    )
    ON CONFLICT (user_id) DO NOTHING;
    
    RAISE NOTICE 'Test user created successfully!';
END $$;
```

4. Click **"Run"** (or press F5)

### Step 4: Verify User
Run this query to verify:
```sql
SELECT 
    u.id,
    u.username,
    u.email,
    u.preferred_language,
    u.created_at
FROM users u
WHERE u.email = 'test@translator.com';
```

You should see the test user!

---

## Method 2: Via API (Alternative)

If you want to create the user programmatically, run this from your terminal:

```bash
curl -X POST 'https://blqqqxsijgvydczjaayy.supabase.co/auth/v1/signup' \
  -H "apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJscXFneHNpamd2eWRjemphYXl5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzExNjc0MDcsImV4cCI6MjA4Njc0MzQwN30.QWeFsEP5eIMQiRPWLzdOswN6JlzGl5jbIu1jTLTOOpg" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@translator.com",
    "password": "Test123456!",
    "data": {
      "username": "testuser",
      "preferred_language": "en"
    }
  }'
```

Then run the SQL from Step 3 above to create the profile.

---

## 🎯 Now You Can Login!

### In Flutter App:
1. Open the app
2. Go to Login screen
3. Enter:
   - **Email**: `test@translator.com`
   - **Password**: `Test123456!`
4. Click **Login**

### Test the API:
```bash
curl -X POST 'http://localhost:3000/api/auth/login' \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@translator.com",
    "password": "Test123456!"
  }'
```

You should get back a JWT token!

---

## 🔧 Create More Test Users

Want to create more users? Just repeat the process with different emails:

```
User 2:
Email: user2@translator.com
Password: Test123456!
Username: user2

User 3:
Email: user3@translator.com
Password: Test123456!
Username: user3
```

---

## ⚠️ Troubleshooting

### "Email not confirmed"
- Make sure you checked **"Auto Confirm User"** when creating the user
- OR go to the user in Dashboard and click "Confirm Email"

### "User not found in database"
- Run the SQL query from Step 3 to create the user profile

### "Invalid credentials"
- Double-check the email and password
- Make sure the user exists in Supabase Auth

---

## 🎉 Done!

You now have a test user to login and explore the app!
