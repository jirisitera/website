import { readFile } from "node:fs/promises";
export const prerender = true;
export async function GET() {
  const filePath = new URL("../../../public/install.ps1", import.meta.url);
  const body = await readFile(filePath);
  return new Response(body, {
    headers: {
      "content-type": "text/plain; charset=utf-8",
      "content-disposition": 'attachment; filename="install.ps1"',
      "cache-control": "public, max-age=3600",
    },
  });
}
