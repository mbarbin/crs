import type { SidebarsConfig } from '@docusaurus/plugin-content-docs';

/**
 * Creating a sidebar enables you to:
 - create an ordered group of docs
 - render a sidebar for each doc of that group
 - provide next/previous navigation

 The sidebars can be generated from the filesystem, or explicitly defined here.

 Create as many sidebars as you want.
 */
const sidebars: SidebarsConfig = {

  tutorialsSidebar: [
    {
      type: 'category',
      label: 'Tutorials',
      items: [
        { type: 'doc', id: 'tutorials/README', label: 'Introduction' },
      ],
    },
  ],

  guidesSidebar: [
    {
      type: 'category',
      label: 'Guides',
      items: [
        {
          type: 'category',
          label: 'Installation',
          link: {
            type: 'doc',
            id: 'guides/installation/README',
          },
          items: [
            { type: 'doc', id: 'guides/installation/pre-compiled-binaries', label: 'Pre-compiled Binaries' },
            { type: 'doc', id: 'guides/installation/setup-crs-for-github-actions', label: 'Setup crs for GitHub Actions' },
          ],
        },
      ],
    },
  ],

  referenceSidebar: [
    {
      type: 'category',
      label: 'Reference',
      items: [
        { type: 'doc', id: 'reference/glossary', label: 'Glossary' },
        { type: 'doc', id: 'reference/crs-actions-config/README', label: 'CRs Actions Config' },
        { type: 'doc', id: 'reference/odoc', label: 'OCaml Packages' },
      ],
    },
  ],

  explanationSidebar: [
    {
      type: 'category',
      label: 'Explanation',
      items: [
        { type: 'doc', id: 'explanation/README', label: 'Introduction' },
        { type: 'doc', id: 'explanation/binary-distribution', label: 'Binary Distribution' },
      ],
    },
  ],
};

export default sidebars;
