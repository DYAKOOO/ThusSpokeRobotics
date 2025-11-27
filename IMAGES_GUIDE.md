# How to Add Images to Your Blog

## ⭐ Recommended Structure: Folder Per Article

**This is the BEST way to organize your blog!** Each article gets its own folder:

```
src/content/blog/
├── gs-intro/
│   ├── index.md
│   └── images/
│       └── comprehensiveOverview.png
├── robot-arm-tutorial/
│   ├── index.md
│   └── images/
│       ├── hero.jpg
│       ├── assembly.jpg
│       └── diagram.png
├── _example-article/          # Template for new articles
│   ├── index.md
│   └── images/
└── ...
```

### Benefits:
✅ Each article is self-contained
✅ No image naming conflicts
✅ Easy to move/share entire articles
✅ Clear ownership of images
✅ Professional organization

### Old Structure (Not Recommended):
```
src/content/blog/
├── images/                    # Shared images - harder to manage
├── article1.md
└── article2.md
```

### Option 2: Public Static Images (For Site-Wide Assets)
```
public/
├── images/
│   ├── blog/          # General blog images
│   └── authors/       # Author profile pictures
├── blog-placeholder-*.jpg  # Legacy placeholder images
└── favicon.svg
```

## Adding Images to Blog Posts

### Method 1: Content-Collocated Images (RECOMMENDED)

This is best for images specific to a blog post. Place images in `src/content/blog/images/` and use relative paths:

**Frontmatter (Hero Image):**
```yaml
---
title: "My Awesome Robotics Post"
description: "A description"
pubDate: 2024-11-27
heroImage: "./images/my-post-hero.jpg"  # Note: relative path with ./
---
```

**Inline in Content:**
```markdown
![Robot demonstration](./images/robot-demo.jpg)
```

Place your images at: `src/content/blog/images/my-post-hero.jpg`

### Method 2: Public Folder Images

For site-wide images or if you prefer central organization:

```yaml
---
heroImage: "/images/blog/my-post-hero.jpg"  # Note: starts with /
---
```

Place images at: `public/images/blog/my-post-hero.jpg`

### Method 3: External Image URLs

You can also use external image URLs:

```yaml
heroImage: "https://example.com/image.jpg"
```

Or inline:
```markdown
![Image](https://example.com/image.jpg)
```

## Recommended Image Specifications

- **Hero Images**: 1200x630px (ideal for social media sharing)
- **Inline Images**: Max width 800-1000px
- **Format**: JPG for photos, PNG for graphics with transparency, WebP for best compression
- **File Size**: Keep under 500KB for best performance

## Example Blog Post

```markdown
---
title: "Building an Autonomous Robot"
description: "Learn how to build a self-navigating robot"
pubDate: 2024-11-27
heroImage: "/images/blog/autonomous-robot.jpg"
tags: ["robotics", "computer-vision", "ai"]
---

# Building an Autonomous Robot

In this tutorial, we'll build an autonomous robot.

![The completed robot](/images/blog/robot-complete.jpg)

## Step 1: Hardware Setup

![Hardware components](/images/blog/robot-parts.jpg)

...
```

## Adding Author Profile Images

Update your About page image:
1. Add your photo to `public/images/authors/profile.jpg`
2. Update [src/pages/about.astro](src/pages/about.astro#L8) line 8:
   ```astro
   <img src="/images/authors/profile.jpg" alt="ThusSpokeRobotics" ... />
   ```

## Tips

1. **Always use descriptive filenames**: `robot-arm-demo.jpg` instead of `img001.jpg`
2. **Add alt text** for accessibility
3. **Optimize images** before uploading (use tools like TinyPNG or Squoosh)
4. **Use relative paths** starting with `/` (e.g., `/images/blog/photo.jpg`)
5. The sitemap will be auto-generated when you run `npm run build`
