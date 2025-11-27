---
title: 'Example Article: Building a Robot Arm'
description: 'Learn how to build and program a robotic arm from scratch'
pubDate: 2024-11-27
heroImage: './images/hero.jpg'
category: 'Robotics'
tags: ['robotics', 'arduino', 'servo motors', 'kinematics']
---

# Building a Robot Arm

This is an example article showing the folder-per-article structure.

## Why This Structure?

Each article has its own folder with:
- `index.md` - The article content
- `images/` - All images for this article

## Adding Images

### Hero Image (Featured)
Already set in frontmatter above:
```yaml
heroImage: './images/hero.jpg'
```

### Inline Images
Add images in your content like this:

![Robot arm assembly](./images/assembly.jpg)

The image path is relative to this article's folder!

## Benefits

✅ Self-contained articles
✅ No naming conflicts
✅ Easy to move/share articles
✅ Clear image ownership

## Adding Your Images

1. Create your article folder: `src/content/blog/my-article/`
2. Add your markdown: `src/content/blog/my-article/index.md`
3. Add your images: `src/content/blog/my-article/images/hero.jpg`
4. Reference with relative path: `./images/hero.jpg`

That's it!
