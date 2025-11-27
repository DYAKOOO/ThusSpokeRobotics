// @ts-check

import { defineConfig } from 'astro/config';
import mdx from '@astrojs/mdx';
import sitemap from '@astrojs/sitemap';
import tailwind from '@astrojs/tailwind';
import rehypePrism from 'rehype-prism-plus';
import remarkMath from 'remark-math';
import rehypeKatex from 'rehype-katex';
import { EventEmitter } from 'events';
//EventEmitter.defaultMaxListeners = 15;  // or any number higher than 10

export default defineConfig({
  site: 'https://thusspokerobotics.xyz',
  integrations: [mdx(), sitemap(), tailwind()],
  output: 'static',
  build: {
    format: 'file',
  },
  markdown: {
    syntaxHighlight: 'prism',
    rehypePlugins: [rehypePrism, rehypeKatex],
    remarkPlugins: [remarkMath],
  },
  server: {
    port: 3000,
  },
});