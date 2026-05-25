const siteUrl = process.env.CORNERSTONE_CONTENT_SITE_URL || "http://127.0.0.1:8080";
const baseUrl = process.env.CORNERSTONE_CONTENT_SITE_BASE_URL || "/content/";

const config = {
  title: "Cornerstone Content",
  tagline: "Browse file-owned capabilities, plans, and learning content",
  url: siteUrl,
  baseUrl,
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
    colorMode: {
      defaultMode: 'light',
      disableSwitch: false,
      respectPrefersColorScheme: true,
    },
    navbar: {
      title: "Cornerstone",
      items: [
        { to: "/", label: "Content", position: "left" },
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
