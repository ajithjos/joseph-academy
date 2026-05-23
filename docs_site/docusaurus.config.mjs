const config = {
  title: "Cornerstone Catalog",
  tagline: "Browse file-owned capabilities, plans, and learning content",
  url: "http://localhost",
  baseUrl: "/",
  organizationName: "cornerstone",
  projectName: "cornerstone-docs",
  onBrokenLinks: "throw",
  markdown: {
    hooks: {
      onBrokenMarkdownLinks: "warn"
    }
  },
  i18n: {
    defaultLocale: "en",
    locales: ["en"]
  },
  presets: [
    [
      "classic",
      {
        docs: {
          routeBasePath: "/",
          sidebarPath: "./sidebars.js"
        },
        blog: false,
        theme: {
          customCss: "./src/css/custom.css"
        }
      }
    ]
  ],
  themeConfig: {
    navbar: {
      title: "Cornerstone",
      items: [
        { to: "/", label: "Catalog", position: "left" },
        { to: "/generated/catalog-overview", label: "Generated", position: "left" }
      ]
    },
    footer: {
      style: "dark",
      links: [
        {
          title: "Sources",
          items: [
            { label: "Catalog Overview", to: "/generated/catalog-overview" }
          ]
        }
      ],
      copyright: "Cornerstone MVP"
    }
  }
};

export default config;
