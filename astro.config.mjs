import { defineConfig } from "astro/config";
import tailwindcss from "@tailwindcss/vite";
import sitemap from "@astrojs/sitemap";
export default defineConfig({
  output: "static",
  site: "https://japicraft.com",
  vite: { plugins: [tailwindcss()] },
  integrations: [sitemap()],
});
