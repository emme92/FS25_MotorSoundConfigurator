# Converts a PNG into a 512x512 DDS, 1 mip level (same as other FS25 mod icons).
# -Format DXT1 (default): no alpha, like most mod icons.
# -Format DXT5: 8 bit alpha, for an icon on a transparent background (the game shows transparent mod icons,
#   e.g. the base game icons in BC7 / DX10; DXT5 icons load as well, e.g. FS25_RealisticHarvesting).
# -Background: image drawn first (scaled to Size), the source is drawn over it with its alpha. For the ModHub icon:
#   the official template assets/FS25_ModHub_BG512.png (ModHub guidelines: icon_*.dds 512x512 BC1 = DXT1 without
#   mip maps on the template background), e.g.
#   -Source assets\icon_source_transparent.png -Background assets\FS25_ModHub_BG512.png -Target icon_motorSoundConfigurator.dds
param(
    [Parameter(Mandatory = $true)][string]$Source,
    [Parameter(Mandatory = $true)][string]$Target,
    [int]$Size = 512,
    [ValidateSet('DXT1', 'DXT5')][string]$Format = 'DXT1',
    [string]$Background = ''
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.IO;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public static class DxtIcon
{
    static int To565(int r, int g, int b) { return ((r >> 3) << 11) | ((g >> 2) << 5) | (b >> 3); }
    static void From565(int c, out int r, out int g, out int b)
    {
        r = (c >> 11) & 31; g = (c >> 5) & 63; b = c & 31;
        r = (r << 3) | (r >> 2); g = (g << 2) | (g >> 4); b = (b << 3) | (b >> 2);
    }

    // BC3 / DXT5 alpha block: 8 interpolated values between max and min (a0 > a1), 3 bit index per pixel
    static void WriteAlphaBlock(BinaryWriter bw, int[] ba)
    {
        int a0 = 0, a1 = 255;
        for (int i = 0; i < 16; i++) { a0 = Math.Max(a0, ba[i]); a1 = Math.Min(a1, ba[i]); }
        bw.Write((byte)a0); bw.Write((byte)a1);
        int[] pal = new int[8];
        pal[0] = a0; pal[1] = a1;
        for (int k = 2; k < 8; k++) pal[k] = ((8 - k) * a0 + (k - 1) * a1) / 7;
        ulong bits = 0;
        for (int i = 0; i < 16; i++)
        {
            int best = 0, bestD = int.MaxValue;
            for (int k = 0; k < 8; k++) { int d = Math.Abs(ba[i] - pal[k]); if (d < bestD) { bestD = d; best = k; } }
            bits |= (ulong)best << (3 * i);
        }
        for (int k = 0; k < 6; k++) bw.Write((byte)((bits >> (8 * k)) & 0xFF));
    }

    public static void Write(Bitmap bmp, string path, bool withAlpha)
    {
        int w = bmp.Width, h = bmp.Height;
        BitmapData data = bmp.LockBits(new Rectangle(0, 0, w, h), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
        byte[] px = new byte[w * h * 4];
        for (int y = 0; y < h; y++)
            Marshal.Copy(IntPtr.Add(data.Scan0, y * data.Stride), px, y * w * 4, w * 4);
        bmp.UnlockBits(data);

        using (var fs = new FileStream(path, FileMode.Create))
        using (var bw = new BinaryWriter(fs))
        {
            int blocksX = (w + 3) / 4, blocksY = (h + 3) / 4;
            bw.Write(new byte[] { (byte)'D', (byte)'D', (byte)'S', (byte)' ' });
            bw.Write(124);                              // dwSize
            bw.Write(0x1 | 0x2 | 0x4 | 0x1000 | 0x20000 | 0x80000); // CAPS|HEIGHT|WIDTH|PIXELFORMAT|MIPMAPCOUNT|LINEARSIZE
            bw.Write(h); bw.Write(w);
            bw.Write(blocksX * blocksY * (withAlpha ? 16 : 8)); // linear size
            bw.Write(0);                                // depth
            bw.Write(1);                                // mip map count
            for (int i = 0; i < 11; i++) bw.Write(0);   // reserved
            bw.Write(32); bw.Write(0x4);                // pixel format size, DDPF_FOURCC
            bw.Write(new byte[] { (byte)'D', (byte)'X', (byte)'T', (byte)(withAlpha ? '5' : '1') });
            bw.Write(0); bw.Write(0); bw.Write(0); bw.Write(0); bw.Write(0);
            bw.Write(0x1000);                           // DDSCAPS_TEXTURE
            bw.Write(0); bw.Write(0); bw.Write(0); bw.Write(0);

            int[] br = new int[16], bg = new int[16], bb = new int[16], ba = new int[16];
            for (int by = 0; by < blocksY; by++)
            for (int bx = 0; bx < blocksX; bx++)
            {
                for (int i = 0; i < 16; i++)
                {
                    int x = Math.Min(bx * 4 + (i & 3), w - 1), y = Math.Min(by * 4 + (i >> 2), h - 1);
                    int o = (y * w + x) * 4;                // BGRA in memory
                    bb[i] = px[o]; bg[i] = px[o + 1]; br[i] = px[o + 2]; ba[i] = px[o + 3];
                }
                if (withAlpha) WriteAlphaBlock(bw, ba);
                // endpoints: bounding box of the block colors; with alpha only the visible pixels count (the colour
                // of fully transparent pixels is undefined after resizing). BC3 always decodes the colour block in
                // 4 colour mode, so the order of c0 / c1 does not matter there.
                int minR = 255, minG = 255, minB = 255, maxR = 0, maxG = 0, maxB = 0;
                bool any = false;
                for (int i = 0; i < 16; i++)
                {
                    if (withAlpha && ba[i] == 0) continue;
                    any = true;
                    minR = Math.Min(minR, br[i]); minG = Math.Min(minG, bg[i]); minB = Math.Min(minB, bb[i]);
                    maxR = Math.Max(maxR, br[i]); maxG = Math.Max(maxG, bg[i]); maxB = Math.Max(maxB, bb[i]);
                }
                if (!any) { minR = minG = minB = maxR = maxG = maxB = 255; }
                int c0 = To565(maxR, maxG, maxB), c1 = To565(minR, minG, minB);
                if (c0 < c1) { int t = c0; c0 = c1; c1 = t; }
                bw.Write((ushort)c0); bw.Write((ushort)c1);

                int[,] pal = new int[4, 3];
                int r0, g0, b0, r1, g1, b1;
                From565(c0, out r0, out g0, out b0); From565(c1, out r1, out g1, out b1);
                pal[0, 0] = r0; pal[0, 1] = g0; pal[0, 2] = b0;
                pal[1, 0] = r1; pal[1, 1] = g1; pal[1, 2] = b1;
                if (c0 > c1)
                {
                    pal[2, 0] = (2 * r0 + r1) / 3; pal[2, 1] = (2 * g0 + g1) / 3; pal[2, 2] = (2 * b0 + b1) / 3;
                    pal[3, 0] = (r0 + 2 * r1) / 3; pal[3, 1] = (g0 + 2 * g1) / 3; pal[3, 2] = (b0 + 2 * b1) / 3;
                }
                else
                {   // single color block: 3-color mode, index 3 would be transparent black, so never used
                    pal[2, 0] = (r0 + r1) / 2; pal[2, 1] = (g0 + g1) / 2; pal[2, 2] = (b0 + b1) / 2;
                    pal[3, 0] = pal[2, 0]; pal[3, 1] = pal[2, 1]; pal[3, 2] = pal[2, 2];
                }
                uint indices = 0;
                int count = c0 > c1 ? 4 : 3;
                for (int i = 0; i < 16; i++)
                {
                    int best = 0, bestD = int.MaxValue;
                    for (int p = 0; p < count; p++)
                    {
                        int dr = br[i] - pal[p, 0], dg = bg[i] - pal[p, 1], db = bb[i] - pal[p, 2];
                        int d = dr * dr * 3 + dg * dg * 4 + db * db * 2;
                        if (d < bestD) { bestD = d; best = p; }
                    }
                    indices |= (uint)best << (2 * i);
                }
                bw.Write(indices);
            }
        }
    }
}
'@

$src = [System.Drawing.Image]::FromFile($Source)
try {
    # centered square crop, then high quality resize
    $side = [Math]::Min($src.Width, $src.Height)
    $cropX = [int](($src.Width - $side) / 2); $cropY = [int](($src.Height - $side) / 2)
    $dst = New-Object System.Drawing.Bitmap($Size, $Size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($dst)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    if ($Background -ne '') {
        $bg = [System.Drawing.Image]::FromFile((Resolve-Path $Background))
        try { $g.DrawImage($bg, 0, 0, $Size, $Size) } finally { $bg.Dispose() }
    }
    $g.DrawImage($src, (New-Object System.Drawing.Rectangle(0, 0, $Size, $Size)), $cropX, $cropY, $side, $side, [System.Drawing.GraphicsUnit]::Pixel)
    $g.Dispose()
    [DxtIcon]::Write($dst, $Target, $Format -eq 'DXT5')
    $preview = [IO.Path]::ChangeExtension($Target, '.preview.png')
    $dst.Save($preview, [System.Drawing.Imaging.ImageFormat]::Png)
    $dst.Dispose()
    "Written $Target ($Format, $((Get-Item $Target).Length) bytes), preview $preview"
} finally { $src.Dispose() }
