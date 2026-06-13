import { readFile } from "node:fs/promises";
import { resolve } from "node:path";
export async function GET() {
  const scriptPath = resolve(process.cwd(), "src", "scripts", "mc", "run.ps1");
  const script = await readFile(scriptPath, "utf8");
  return new Response(script, {
    headers: {
      "Content-Type": "text/plain; charset=utf-8",
      "Cache-Control": "no-cache",
    },
  });
}
