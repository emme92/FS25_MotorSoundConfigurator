# Renders an SVG into a 512x512 PNG with transparency (no SVG converter on this machine, the browser does it).
# Serves a page on http://localhost:<Port>/ that draws the SVG into a canvas and posts the PNG back; open that URL
# in any browser, the script writes -Out and exits. Used for the icon:
#   tools\render_svg.ps1 -Svg assets\icon_source.svg -Out assets\icon_source_transparent.png
# then tools\make_icon.ps1 (see there) for the DDS.
param(
    [Parameter(Mandatory = $true)][string]$Svg,
    [Parameter(Mandatory = $true)][string]$Out,
    [int]$Port = 8766
)
$ErrorActionPreference = 'Stop'
$svgText = [IO.File]::ReadAllText((Resolve-Path $Svg))
$Out = [IO.Path]::GetFullPath($Out)
$html = @"
<!doctype html><html><body style="background:#444"><div id="s">$svgText</div><p id="st">rendering</p><script>
(async () => {
  const svgText = new XMLSerializer().serializeToString(document.querySelector('#s svg'));
  const img = new Image();
  img.src = 'data:image/svg+xml;base64,' + btoa(unescape(encodeURIComponent(svgText)));
  await img.decode();
  const c = document.createElement('canvas'); c.width = 512; c.height = 512;
  c.getContext('2d').drawImage(img, 0, 0, 512, 512);
  const r = await fetch('/upload', {method: 'POST', body: c.toDataURL('image/png').split(',')[1]});
  document.getElementById('st').textContent = 'done ' + r.status;
})();
</script></body></html>
"@
$l = New-Object System.Net.HttpListener; $l.Prefixes.Add("http://localhost:$Port/"); $l.Start()
"Open http://localhost:$Port/ in a browser"
try {
    while ($true) {
        $ctx = $l.GetContext()
        if ($ctx.Request.HttpMethod -eq 'POST') {
            $b64 = (New-Object IO.StreamReader($ctx.Request.InputStream)).ReadToEnd()
            [IO.File]::WriteAllBytes($Out, [Convert]::FromBase64String($b64))
            $ctx.Response.StatusCode = 200; $ctx.Response.Close()
            "Written $Out ($((Get-Item $Out).Length) bytes)"
            break
        }
        $bytes = [Text.Encoding]::UTF8.GetBytes($html)
        $ctx.Response.ContentType = 'text/html; charset=utf-8'
        $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length); $ctx.Response.Close()
    }
} finally { $l.Stop() }
