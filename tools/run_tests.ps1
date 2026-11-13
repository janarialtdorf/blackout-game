# Runs every tests/test_*.gd headless inside the game (tools/run.tscn) and prints a summary. A test that hangs is killed after 90 s.
# Run from the project folder:  .\tools\run_tests.ps1
param([string]$Godot = "C:\Program Files\Godot\Godot.exe.exe")

$log = Join-Path ([IO.Path]::GetTempPath()) "godot_test"
# Re-scan first so new/renamed class_name scripts are known.
Start-Process -FilePath $Godot -ArgumentList "--headless", "--path", ".", "--import" -RedirectStandardOutput "$log.out" -RedirectStandardError "$log.err" -Wait -NoNewWindow
$failed = 0
foreach ($test in Get-ChildItem tests -Filter "test_*.gd") {
    $p = Start-Process -FilePath $Godot -ArgumentList "--headless", "--path", ".", "res://tools/run.tscn", "--", "res://tests/$($test.Name)" `
        -RedirectStandardOutput "$log.out" -RedirectStandardError "$log.err" -PassThru -NoNewWindow
    if (-not $p.WaitForExit(90000)) { $p.Kill(); "HUNG: $($test.Name)"; $failed++; continue }
    $lines = @(Get-Content "$log.out" | Select-String "PASS|FAIL") + @(Get-Content "$log.err" | Select-String "ERROR")
    $bad = @($lines | Where-Object { "$_" -notmatch "^PASS" })
    $failed += $bad.Count
    "{0,-22} {1} passed" -f $test.BaseName, ($lines.Count - $bad.Count)
    $bad | ForEach-Object { "    $_" }
}
if ($failed) { "FAILED: $failed problem(s)"; exit 1 } else { "ALL PASSED" }
