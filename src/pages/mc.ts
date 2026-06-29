export async function GET() {
  const url = "https://raw.githubusercontent.com/jirisitera/devcraft/main/scripts/install.ps1";
  try {
    const response = await fetch(url);
    if (!response.ok) return new Response("Error fetching script: " + response.statusText, { status: response.status });
    return new Response(await response.text(), {
      headers: { "Content-Type": "text/plain; charset=utf-8", "Cache-Control": "no-cache" },
    });
  } catch (e) {
    return new Response("Internal Server Error", { status: 500 });
  }
}
