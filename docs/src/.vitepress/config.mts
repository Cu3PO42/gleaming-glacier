import { defineConfig } from 'vitepress'

// https://vitepress.dev/reference/site-config
export default defineConfig({
  title: "Gleaming Glacier",
  description: "The documentation for Copper's dotfiles.",
  themeConfig: {
    // https://vitepress.dev/reference/default-theme-config
    nav: [
      { text: 'Home', link: '/' },
      { text: 'Highlights', link: '/highlights' }
    ],

    sidebar: [
      {
        items: [
          { text: 'Introduction', link: '/introduction' },
          { text: 'Usage', link: '/usage' },
          { text: 'Highlights', link: '/highlights' },
        ],
      },
      {
        text: 'Features',
        items: [
          { text: 'Chroma', link: '/features/chroma' },
          { text: 'Mage', link: '/features/mage' },
          { text: 'Plate', link: '/features/plate' },
          { text: 'Swim', link: '/features/swim' },
          { text: 'Autoload', link: '/features/gleaming-autoload' },
        ],
      },
      {
        text: 'Reference',
        items: [
          { text: 'Flake Outputs', link: '/reference/flake' },
          { text: 'Packages', link: '/reference/packages' },
          { text: 'Library', link: '/reference/lib' },
          { text: 'Limitations on macOS', link: '/darwin' },
        ],
      },
      {
        text: 'Closing',
        items: [
          { text: 'FAQ', link: '/faq' },
          { text: 'Common Issues', link: '/pitfalls' },
          { text: 'Licensing', link: 'https://github.com/Cu3PO42/gleaming-glacier/blob/LICENSE.md' },
          { text: 'Credits and Resources', link: '/credits' },
          { text: 'Nix Documentation', link: '/nix-documentation' },
        ]
      }
    ],

    socialLinks: [
      { icon: 'github', link: 'https://github.com/Cu3PO42/gleaming-glacier' }
    ],

    search: {
      provider: 'local',
    }
  }
})
