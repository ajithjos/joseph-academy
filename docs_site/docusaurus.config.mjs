const siteUrl = process.env.CORNERSTONE_CONTENT_SITE_URL || "http://127.0.0.1:8080";
const baseUrl = process.env.CORNERSTONE_CONTENT_SITE_BASE_URL || "/content/";
const frontendUrl = `${
  process.env.CORNERSTONE_FRONTEND_SITE_URL || siteUrl
}`.replace(/\/?$/, "/");

function withBaseUrl(target) {
  const normalizedBaseUrl = baseUrl.endsWith("/") ? baseUrl : `${baseUrl}/`;
  const normalizedTarget = target.replace(/^\/+/, "");
  if (normalizedBaseUrl === "/") {
    return `/${normalizedTarget}`;
  }
  return `${normalizedBaseUrl}${normalizedTarget}`;
}

const brandLockupHtml = `
  <a class="navbar__brand-lockup" href="${frontendUrl}" aria-label="Back to Cornerstone site">
    <span class="navbar__brand-logo-frame">
      <img class="navbar__brand-logo" src="${withBaseUrl("/img/logo-symbol.png")}" alt="Cornerstone symbol" />
    </span>
    <span class="navbar__brand-wordmark-frame">
      <img class="navbar__brand-wordmark" src="${withBaseUrl("/img/logo-wordmark.png")}" alt="Cornerstone" />
    </span>
  </a>
`;

const config = {
  title: "Cornerstone Content",
  tagline: "Browse repo-owned pathways, playlists, and teaching materials",
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
      items: [
        { type: "html", value: brandLockupHtml, position: "left" },
        { to: "/", label: "Content", position: "left" },
        { to: "/generated/library-overview", label: "Overview", position: "left" },
        {
          to: "/library/maths/arithmetic/household-arithmetic-fact-fluency/pathway",
          label: "Pathways",
          position: "left",
        },
        { href: frontendUrl, label: "Back to Site", position: "right", className: "navbar__back-to-site" }
      ]
    },
    footer: {
      style: "dark",
      links: [
        {
          title: "Sources",
          items: [
            { label: "Library Overview", to: "/generated/library-overview" },
            {
              label: "Household Arithmetic Pathway",
              to: "/library/maths/arithmetic/household-arithmetic-fact-fluency/pathway",
            }
          ]
        }
      ],
      copyright: "Cornerstone MVP"
    }
  }
};

export default config;
