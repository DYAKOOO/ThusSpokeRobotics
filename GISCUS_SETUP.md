# Giscus Comment System Setup Guide

## What is Giscus?

Giscus is a comment system powered by GitHub Discussions. It's:
- ✅ **FREE** forever
- ✅ **No backend needed** - uses GitHub Discussions
- ✅ **Works perfectly with Cloud Run** (no state to store)
- ✅ **Privacy-focused** - no tracking
- ✅ **Markdown support** - code blocks, images, etc.
- ✅ **Great for tech blogs** - your audience likely has GitHub accounts

## Step-by-Step Setup

### 1. Enable GitHub Discussions

1. **Go to your repository settings**:
   - Navigate to: `https://github.com/[your-username]/ThusSpokeRobotics/settings`

2. **Scroll down to "Features" section**

3. **Check the box** next to "Discussions"

4. **Click "Set up discussions"** (if prompted)
   - GitHub will create a welcome discussion
   - You can customize it or leave the default

### 2. Install Giscus App

1. **Go to**: https://github.com/apps/giscus

2. **Click "Install"**

3. **Select your repository**: `ThusSpokeRobotics`

4. **Authorize** the app

### 3. Configure Giscus

1. **Go to**: https://giscus.app

2. **Enter your repository** in the format: `username/ThusSpokeRobotics`
   - Example: `johndoe/ThusSpokeRobotics`

3. **Wait for validation** ✅
   - Giscus will check if your repo meets requirements:
     - Public repository
     - Discussions enabled
     - Giscus app installed

4. **Configure Discussion Settings**:

   **Page ↔️ Discussions Mapping**:
   - Choose: `pathname` ✅ (recommended)
   - This maps each blog post URL to a unique discussion

   **Discussion Category**:
   - Choose: `Announcements` ✅ (recommended)
   - Or create a custom "Blog Comments" category

   **Features**:
   - ✅ Enable reactions for main post
   - ✅ Emit discussion metadata (optional)
   - Choose: Place comment box above/below comments

   **Theme**:
   - Choose: `preferred_color_scheme` ✅
   - This auto-switches between light/dark mode

5. **Copy the generated script**:
   ```html
   <script src="https://giscus.app/client.js"
           data-repo="YOUR_USERNAME/ThusSpokeRobotics"
           data-repo-id="YOUR_REPO_ID_HERE"
           data-category="Announcements"
           data-category-id="YOUR_CATEGORY_ID_HERE"
           ...>
   </script>
   ```

### 4. Update Your Blog Component

I've already created `src/components/GiscusComments.astro`, but you need to update it with your configuration:

**Replace these values** in `src/components/GiscusComments.astro`:

```astro
data-repo="YOUR_USERNAME/ThusSpokeRobotics"  → data-repo="your-actual-username/ThusSpokeRobotics"
data-repo-id="YOUR_REPO_ID"                  → data-repo-id="R_..." (from giscus.app)
data-category-id="YOUR_CATEGORY_ID"          → data-category-id="DIC_..." (from giscus.app)
```

**Example** (with real values):
```astro
data-repo="diako/ThusSpokeRobotics"
data-repo-id="R_kgDOKH1234"
data-category-id="DIC_kwDOKH1234HgBg"
```

### 5. Update Blog Post Template

I'll update `src/pages/blog/[...slug].astro` to use the new component.

---

## How It Works

1. **User visits blog post**: `https://thusspokerobotics.xyz/blog/my-post`

2. **Giscus loads**: Fetches or creates a GitHub Discussion for this URL

3. **User comments**:
   - Clicks "Sign in with GitHub"
   - Writes comment in familiar GitHub interface
   - Comment is stored as GitHub Discussion comment

4. **Comments appear**: On your blog AND in GitHub Discussions tab

5. **You can moderate**: Via GitHub (delete spam, etc.)

---

## Benefits

### For Your Blog
- ✅ **Zero cost**: No payment, no server, no database
- ✅ **Zero maintenance**: GitHub handles everything
- ✅ **Scales infinitely**: GitHub's infrastructure
- ✅ **Works on Cloud Run**: No state to persist

### For Your Readers
- ✅ **No new account**: Use GitHub account they already have
- ✅ **Markdown support**: Code blocks, images, GIFs
- ✅ **Notifications**: Get email when someone replies
- ✅ **Privacy**: No tracking, no ads

### For You (as moderator)
- ✅ **Easy moderation**: Delete/edit via GitHub
- ✅ **Email notifications**: New comments notify you
- ✅ **Backup**: All comments in GitHub (version controlled!)

---

## Alternatives Considered

| Solution | Cost | Backend Needed | Accounts Required | Ads |
|----------|------|----------------|-------------------|-----|
| **Giscus** ✅ | Free | No | GitHub | No |
| Utterances | Free | No | GitHub | No |
| Disqus | Free* | No | Email/Social | Yes* |
| Custom (Firestore) | Free* | Yes | Custom | No |

*Free tier with limitations

**Why Giscus over Utterances?**
- Giscus uses **Discussions** (designed for conversations)
- Utterances uses **Issues** (designed for bug tracking)
- Discussions have better UX for comments

---

## Next Steps

After you complete the configuration:

1. Give me your Giscus script values:
   - `data-repo-id`
   - `data-category-id`

2. I'll update the component

3. We'll test locally

4. Deploy to Cloud Run!

---

## Testing Locally

After setup, test with:

```bash
npm run dev
```

Then visit: `http://localhost:4321/blog/[any-post]`

You should see the Giscus comment widget at the bottom!

---

## Troubleshooting

### "Discussion not found"
- Make sure Discussions are enabled
- Make sure Giscus app is installed
- Check data-repo format: `username/repo` (no spaces)

### Comments not loading
- Check browser console for errors
- Verify repo is **public** (Giscus needs public repos)
- Check data-repo-id and data-category-id are correct

### Can't sign in
- Make sure you're logged into GitHub
- Check if popup blockers are enabled
- Try incognito mode

---

## Cost Analysis

**Giscus**: $0/month ✅
- Uses GitHub's free Discussions feature
- No server, no database, no API calls
- Unlimited comments, unlimited users

**Alternatives**:
- Disqus: Free with ads, $9-$89/month ad-free
- Custom backend: $5-20/month (database + hosting)
- Utterances: $0/month (but uses Issues, not ideal)

**Winner**: Giscus! 🎉

---

Let me know when you've completed steps 1-3, and I'll finalize the implementation!
