import { defineConfig } from "astro/config";
import tailwindcss from "@tailwindcss/vite";

export default defineConfig({
  output: "static",
  site: 'https://jirisitera.github.io',
  base: '/website',
  vite: {plugins: [tailwindcss()]},
});
