# How to Get Your Clerk Secret Key

## 🔑 **Step-by-Step Instructions:**

### **Step 1: Access Clerk Dashboard**
1. Go to https://dashboard.clerk.com/
2. Sign in to your Clerk account

### **Step 2: Select Your Project**
1. Look for your project: **"rational-molly-22"**
2. Click on it to enter the project dashboard

### **Step 3: Navigate to API Keys**
1. In the left sidebar, click on **"API Keys"**
2. You'll see two types of keys:
   - **Publishable Key** (already configured): `pk_test_cmF0aW9uYWwtbW9sbHktMjIuY2xlcmsuYWNjb3VudHMuZGV2JA`
   - **Secret Key** (what you need): `sk_test_...`

### **Step 4: Copy the Secret Key**
1. Find the **Secret Key** (starts with `sk_test_`)
2. Click the **"Copy"** button next to it
3. It should look something like: `sk_test_abcd1234efgh5678ijkl9012mnop3456`

### **Step 5: Update Environment Variables**
1. Open your `.env.local` file
2. Find this line:
   ```
   # CLERK_SECRET_KEY=your_clerk_secret_key_here
   ```
3. Replace it with:
   ```
   CLERK_SECRET_KEY=sk_test_your_actual_secret_key_here
   ```
   (Replace `sk_test_your_actual_secret_key_here` with the key you copied)

### **Step 6: Restart Your Development Server**
1. Stop your current dev server (Ctrl+C)
2. Start it again:
   ```bash
   npm run dev
   ```

## 🧪 **Test Your Setup:**

### **Option 1: Test Page**
Visit: `http://localhost:3000/clerk-test`
- This page will show you if Clerk is working correctly
- You can test sign in/sign up without the secret key

### **Option 2: Login Page**
Visit: `http://localhost:3000/login`
- Try the full authentication flow
- Should redirect to dashboard after successful login

## ⚠️ **Important Notes:**

### **Security:**
- **Never commit your secret key to version control**
- The `.env.local` file is already in `.gitignore`
- Keep your secret key private and secure

### **Key Types:**
- **Test Keys** (start with `pk_test_` and `sk_test_`): For development
- **Live Keys** (start with `pk_live_` and `sk_live_`): For production

### **If You Can't Find Your Secret Key:**
1. Make sure you're logged into the correct Clerk account
2. Verify you're in the right project ("rational-molly-22")
3. Check if you have the necessary permissions
4. Contact Clerk support if needed: support@clerk.com

## 🔧 **Troubleshooting:**

### **"Invalid publishable key" error:**
- Double-check the publishable key is correct
- Make sure there are no extra spaces or characters

### **"Secret key invalid" error:**
- This is the current issue - you need the real secret key
- The placeholder value won't work

### **"Project not found" error:**
- Verify the project name in Clerk dashboard
- Check if the publishable key matches your project

## 🎯 **Once You Have the Secret Key:**

1. **Update `.env.local`** with the real secret key
2. **Restart your dev server**
3. **Test authentication** at `/clerk-test`
4. **Try the full app** starting from `/login`
5. **Verify user creation** in both Clerk and Supabase

## 📞 **Need Help?**

If you're still having issues:
1. Check the Clerk documentation: https://clerk.com/docs
2. Verify your project settings in Clerk dashboard
3. Test with the `/clerk-test` page first
4. Check browser console for detailed error messages

---

**Once you add the correct secret key, your FaceTrack authentication will be fully functional! 🚀**