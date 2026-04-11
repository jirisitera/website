import { readFile } from "node:fs/promises";
export const prerender = true;
export async function GET() {
  const filePath = new URL("../../../public/rp/install.sh", import.meta.url);
  const body = await readFile(filePath);
  return new Response(body, {
    headers: {
      "content-type": "text/x-shellscript; charset=utf-8",
      "content-disposition": 'attachment; filename="install.sh"',
      "cache-control": "public, max-age=3600",
    },
  });
}
