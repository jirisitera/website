# My Personal Website (JapiWeb)

![github](https://cdn.jsdelivr.net/npm/@intergrav/devins-badges@3/assets/cozy/available/github_vector.svg)
![website](https://cdn.jsdelivr.net/npm/@intergrav/devins-badges@3/assets/cozy/documentation/website_vector.svg)

[![.github/workflows/pack.yml](https://img.shields.io/github/actions/workflow/status/jirisitera/website/deploy.yml?style=for-the-badge&logo=github)](https://github.com/jirisitera/website/actions/workflows/deploy.yml)

A modern website for my personal projects and interests. Made with Astro, Tailwind, and love sprinkled on top.

> [!NOTE]
> This is a purely static website. Everything is compiled into static files for easy hosting and portability.

## License & Usage

I'm not one for gatekeeping code, so feel free to use any part of this project for your own website or project.

All of the code is open source under the [MIT License](LICENSE.txt).

## Getting Started

To preview this website locally, make sure you have [Node.js](https://nodejs.org/) and [pnpm](https://pnpm.io/) installed, then run:

```bash
pnpm install
pnpm dev
```

This will start a local development server on `http://localhost:4321` (unless the port is already occupied). You can then check it out in your web browser. You can stop the server at any time by pressing `Ctrl + C` in the terminal.

## Hosting & Deployment

This project uses GitHub Actions for continuous deployment to GitHub Pages.

The used workflow is defined in the [deploy.yml](.github/workflows/deploy.yml) workflow file.

> [!NOTE]
> The deployment workflow runs on the 'push' and 'pull_request' events, and uses the newest experimental versions of all actions and dependencies. This may not be desirable for everyone, as it could become unstable over time without maintenance.
