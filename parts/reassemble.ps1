# reassemble.ps1 — 把 costrict-router.pkg-000 ~ pkg-010 合并成 zip 并解压
# 在 Windows PowerShell 里直接执行：双击 或 powershell -ExecutionPolicy Bypass -File reassemble.ps1
$ErrorActionPreference = "Stop"
$dir = Split-Path -Parent $MyInvocation.MyCommand.Path

$zip = Join-Path $dir "costrict-router.zip"
$exe = Join-Path $dir "costrict-router.exe"

Write-Host "==> 组装 zip ..." -ForegroundColor Cyan
$parts = Get-ChildItem -Path $dir -Filter "costrict-router.pkg-*" | Sort-Object Name
if ($parts.Count -eq 0) {
    Write-Host "❌ 当前目录没找到 costrict-router.pkg-* 分块，请确认 11 个 part 文件都已下载到位" -ForegroundColor Red
    exit 1
}
Write-Host "    找到 $($parts.Count) 个 part，准备合并"
$ms = New-Object System.IO.MemoryStream
foreach ($p in $parts) {
    $ms.Write([IO.File]::ReadAllBytes($p.FullName), 0, (int)$p.Length)
}
[IO.File]::WriteAllBytes($zip, $ms.ToArray())
$ms.Dispose()

# 校验 SHA256
$hash = (Get-FileHash $zip -Algorithm SHA256).Hash.ToLower()
$expected = "8f8399e44c0a9a231c13643821b65b0940c5266b44ef03c2476cd7c389d8646f"
if ($hash -ne $expected) {
    Write-Host "❌ SHA256 不匹配！期望 $expected 实际 $hash" -ForegroundColor Red
    Write-Host "    可能是分块没下完整，建议把所有 part 都删了重新下载" -ForegroundColor Yellow
    exit 1
}
Write-Host "✅ SHA256 校验通过" -ForegroundColor Green

Write-Host "==> 解压 zip ..." -ForegroundColor Cyan
if (Test-Path $exe) { Remove-Item $exe -Force }
Expand-Archive -Path $zip -DestinationPath $dir -Force

$exeInfo = Get-Item $exe -ErrorAction SilentlyContinue
if ($exeInfo) {
    Write-Host "✅ 完成！" -ForegroundColor Green
    Write-Host ""
    Write-Host "    产物: $($exeInfo.FullName)"
    Write-Host "    大小: $([math]::Round($exeInfo.Length/1MB, 1)) MB"
    Write-Host ""
    Write-Host "下一步:"
    Write-Host "  1. 把 costrict-router.exe 和 model_extra.json 拷到 D:\software\"
    Write-Host "  2. 先执行 costrict-router.exe stop（如果之前有旧实例在跑）"
    Write-Host "  3. 再执行 costrict-router.exe start"
} else {
    Write-Host "❌ 解压后没找到 costrict-router.exe，请手动打开 zip 看看内容" -ForegroundColor Red
}

# 清理 part 和 zip（可选，留着也行）
Write-Host ""
Write-Host "==> 清理临时文件 ..." -ForegroundColor Gray
Remove-Item $parts.FullName -Force -ErrorAction SilentlyContinue
Remove-Item $zip -Force -ErrorAction SilentlyContinue
Write-Host "    已清理 part 分块和 zip" -ForegroundColor Gray
