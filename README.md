# Neural Diwan

This project is a sophisticated blog built with Astro, featuring a custom design and several advanced functionalities focused on Machine Learning, Gaussian Splatting, and related topics.

## Disclaimer

This project is provided as-is, without ny warranty or guarantee of its functionality or suitability for any purpose. The author is not responsible for any damages or liabilities arising from the use of this code. Users are advised to review and test the code thoroughly before implementing it in their own projects.

## Implemented Features

- ✅ Responsive design with mobile-friendly navigation
- ✅ Blog post categorization (Machine Learning, Gaussian Splatting) and tagging system
- ✅ Advanced search functionality for blog posts
- ✅ Category and tag filtering on the blog page
- ✅ Recent posts sidebar on the homepage
- ✅ Custom 404 and 500 error pages
- ✅ SEO optimizations including meta tags, structured data, and sitemap
- ✅ Commenting system (simulated, ready for backend integration)
- ✅ Neural network-inspired logo
- ✅ Dedicated category pages for Machine Learning and Gaussian Splatting

## TODO Features

- [ ] Dark mode toggle
- [ ] Pagination for blog posts
- [ ] Author profiles
- [ ] Related posts suggestions
- [ ] Newsletter subscription
- [ ] Social media sharing buttons
- [ ] Reading time estimation for posts
- [ ] Interactive demos for ML and Gaussian Splatting concepts

## Getting Started

To get this project up and running on your local machine, follow these steps:

1. Clone the repository:
   ```
   git clone https://github.com/yourusername/neural-diwan.git
   ```
2. Navigate to the project directory:
   ```
   cd neural-diwan
   ```
3. Install the dependencies:
   ```
   npm install
   ```
4. Start the development server:
   ```
   npm run dev
   ```
5. Open your browser and visit `http://localhost:4321` to see the blog.

## Project Structure

```
neural-diwan/
│
├── public/
│   └── (static assets like images and sitemap.xml)
│
├── src/
│   ├── components/
│   │   └── (Astro components including Logo.astro)
│   │
│   ├── content/
│   │   └── blog/
│   │       └── (Markdown files for blog posts)
│   │
│   ├── layouts/
│   │   └── (Layout components)
│   │
│   ├── pages/
│   │   ├── blog/
│   │   │   └── category/
│   │   │       ├── gaussian-splatting.astro
│   │   │       └── machine-learning.astro
│   │   └── (Other Astro pages)
│   │
│   └── styles/
│       └── global.css
│
├── astro.config.mjs
├── package.json
└── tsconfig.json
```

## Customization

1. Update site metadata in `src/consts.ts`
2. Modify the global styles in `src/styles/global.css`
3. Add or edit blog posts in `src/content/blog/`
4. Customize components in `src/components/`
5. Adjust the neural network-inspired logo in `src/components/Logo.astro`

## Deployment

To build the site for production:

```
npm run build
```

The built files will be in the `dist/` directory, ready for deployment to your preferred hosting service.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is open source and available under the MIT License. However, please note that the author is not responsible for any consequences resulting from the use of this code.