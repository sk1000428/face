# FaceTrack Clerk Authentication Setup Guide

This guide will help you complete the Clerk authentication setup for your FaceTrack application.

## 🔧 **What's Already Configured:**

### ✅ **Clerk Integration Complete:**
- **Clerk Provider**: Added to root layout
- **Authentication Pages**: Login and Signup using Clerk components
- **Protected Routes**: Middleware protecting dashboard and other pages
- **User Context**: AuthContext updated to work with Clerk
- **Navigation**: Updated with Clerk SignOutButton
- **Database Integration**: API functions to sync Clerk users with Supabase

## 🚀 **Next Steps to Complete Setup:**

### **Step 1: Get Your Clerk Secret Key**
1. Go to your Clerk Dashboard: https://dashboard.clerk.com/
2. Select your project: "rational-molly-22"
3. Go to **API Keys** section
4. Copy your **Secret Key**
5. Update your `.env.local` file:

```env
# Replace 'your_clerk_secret_key_here' with your actual secret key
CLERK_SECRET_KEY=sk_test_your_actual_secret_key_here
```

### **Step 2: Configure Clerk Dashboard**
1. **Set Redirect URLs:**
   - Sign-in redirect: `http://localhost:3000/dashboard`
   - Sign-up redirect: `http://localhost:3000/dashboard`
   - Sign-out redirect: `http://localhost:3000/login`

2. **Enable Email/Password Authentication:**
   - Go to **User & Authentication** → **Email, Phone, Username**
   - Enable **Email address** as a required field
   - Enable **Password** authentication

3. **Configure Session Settings:**
   - Go to **Sessions**
   - Set session timeout as needed (default is fine)

### **Step 3: Update Database Schema**
Run the Clerk migration SQL in your Supabase dashboard:

```sql
-- Copy and paste the contents of facetrack-clerk-migration.sql
-- This adds clerk_user_id columns and updates RLS policies
```

### **Step 4: Test the Integration**
1. Start your development server:
   ```bash
   npm run dev
   ```

2. Visit `http://localhost:3000/login`
3. Try creating a new account
4. Check if you're redirected to the dashboard
5. Verify that a student record is created in Supabase

## 📁 **Files Modified for Clerk:**

### **Updated Files:**
- `/src/app/layout.tsx` - Added ClerkProvider
- `/src/contexts/AuthContext.tsx` - Updated to use Clerk hooks
- `/src/app/login/page.tsx` - Now uses Clerk SignIn component
- `/src/app/signup/page.tsx` - Now uses Clerk SignUp component
- `/src/components/Navigation.tsx` - Uses Clerk SignOutButton
- `/src/middleware.ts` - Clerk route protection
- `/src/lib/api.ts` - Added Clerk user ID support
- `/src/lib/supabase.ts` - Updated Student interface

### **New Files:**
- `facetrack-clerk-migration.sql` - Database migration for Clerk
- `CLERK_SETUP_GUIDE.md` - This setup guide

## 🔐 **How Authentication Works:**

### **User Registration Flow:**
1. User signs up via Clerk SignUp component
2. Clerk creates user account and returns user object
3. AuthContext detects new user and calls `fetchStudentData()`
4. If no student record exists, creates one with Clerk user ID
5. User is redirected to dashboard with full access

### **User Login Flow:**
1. User signs in via Clerk SignIn component
2. Clerk authenticates and returns user object
3. AuthContext fetches associated student record from Supabase
4. User gains access to protected routes

### **Route Protection:**
- Middleware checks authentication status for protected routes
- Unauthenticated users are redirected to `/login`
- Authenticated users can access all dashboard features

## 🛠 **Troubleshooting:**

### **Common Issues:**

1. **"Invalid publishable key" error:**
   - Check that your publishable key is correct in `.env.local`
   - Ensure the key starts with `pk_test_`

2. **"Clerk secret key not found" error:**
   - Add your secret key to `.env.local`
   - Restart your development server

3. **User not redirected after login:**
   - Check redirect URLs in Clerk dashboard
   - Verify middleware configuration

4. **Student record not created:**
   - Check Supabase connection
   - Verify the `students` table exists
   - Check browser console for API errors

### **Debug Steps:**
1. Check browser console for errors
2. Verify environment variables are loaded
3. Test Supabase connection at `/test-connection`
4. Check Clerk dashboard for user creation
5. Verify database permissions and RLS policies

## 🔄 **Data Flow:**

```
Clerk User Registration
        ↓
AuthContext detects new user
        ↓
Calls studentAPI.getByClerkId()
        ↓
If not found, calls studentAPI.create()
        ↓
Student record created in Supabase
        ↓
User can access dashboard features
```

## 🎯 **Testing Checklist:**

- [ ] User can sign up with email/password
- [ ] User receives email verification (if enabled)
- [ ] User is redirected to dashboard after signup
- [ ] Student record is created in Supabase
- [ ] User can sign in with existing credentials
- [ ] User can sign out and is redirected to login
- [ ] Protected routes require authentication
- [ ] User data displays correctly in navigation
- [ ] Settings page loads user preferences

## 🚀 **Production Deployment:**

### **Environment Variables for Production:**
```env
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_live_your_production_key
CLERK_SECRET_KEY=sk_live_your_production_secret
NEXT_PUBLIC_SUPABASE_URL=your_production_supabase_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_production_supabase_key
```

### **Clerk Dashboard Configuration:**
1. Update redirect URLs to your production domain
2. Configure production webhook endpoints (if needed)
3. Set up proper CORS settings
4. Enable production mode

## 📞 **Support:**

If you encounter issues:
1. Check the Clerk documentation: https://clerk.com/docs
2. Review Supabase logs for database errors
3. Test individual components in isolation
4. Verify all environment variables are set correctly

---

**Your FaceTrack application is now ready with Clerk authentication! 🎉**

The integration provides secure, scalable authentication with automatic user management and seamless integration with your Supabase database.