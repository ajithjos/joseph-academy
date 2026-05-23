const config = {
  title: "Joseph Academy Catalog",
  tagline: "Browse file-owned capabilities, plans, and learning content",
  url: "http://localhost",
  baseUrl: "/",
  organizationName: "joseph-academy",
  projectName: "joseph-academy-docs",
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
      title: "Joseph Academy",
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
      copyright: "Joseph Academy MVP"
    }
  }
};

export default config;
