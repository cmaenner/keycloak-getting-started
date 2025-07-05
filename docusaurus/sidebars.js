/** @type {import('@docusaurus/plugin-content-docs').SidebarsConfig} */
const sidebars = {
  // By default, Docusaurus generates a sidebar from the docs folder structure
  tutorialSidebar: [
    {
      type: 'category',
      label: 'Getting Started',
      items: [
        'intro',
        'keycloak-setup',
        'crossplane-config',
        'troubleshooting',
      ],
    },
  ],
};

module.exports = sidebars; 