# 🚩 Flagsmith Setup Guide

## Step 1: Create a Flagsmith Account
1. Go to [flagsmith.com](https://flagsmith.com)
2. Sign up for a free account
3. Create a new project

## Step 2: Create the Feature Flag
1. In your Flagsmith dashboard, go to **Features**
2. Click **Create Feature**
3. Set the following:
   - **Name**: `copy_function`
   - **Type**: Boolean
   - **Default Value**: `true` (enabled by default)
4. Click **Create**

## Step 3: Get Your Environment ID
1. Go to **Settings** → **Environments**
2. Copy your **Environment ID** (looks like: `env-abc123def456`)

## Step 4: Update the Code
1. Open `password-generator.html`
2. Find this line:
   ```javascript
   environmentID: 'YOUR_ENVIRONMENT_ID', // Replace with your Flagsmith environment ID
   ```
3. Replace `'YOUR_ENVIRONMENT_ID'` with your actual Environment ID

## Step 5: Test the Feature Flag
1. Deploy your website: `./deploy.sh`
2. Open the website in your browser
3. Go to your Flagsmith dashboard
4. Toggle the `copy_function` flag on/off
5. Refresh the website to see the copy button appear/disappear

## 🎯 Interview Demo Script

1. **Start**: "This password generator uses real Flagsmith feature flags"
2. **Show the flag**: Point to the status indicator showing "Enabled"
3. **Toggle in dashboard**: Go to Flagsmith dashboard and disable the flag
4. **Refresh page**: Show the copy button disappears and status changes to "Disabled"
5. **Explain benefits**: No code deployment, instant control, real-time updates

## 🔧 Troubleshooting

### Flag not working?
- Check the Environment ID is correct
- Ensure the feature flag name is exactly `copy_function`
- Check browser console for any errors
- Make sure you're using the correct environment (Development/Production)

### Copy button not hiding?
- Verify the flag is set to `false` in Flagsmith
- Check that the JavaScript is loading properly
- Refresh the page after toggling the flag

## 📝 Notes

- The feature flag controls the copy button visibility
- When disabled, users can still generate passwords but cannot copy them
- The status indicator shows the current flag state
- Changes in Flagsmith take effect immediately (just refresh the page)

---

**Ready for your interview!** 🚀 