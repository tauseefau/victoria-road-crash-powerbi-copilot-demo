# Points every PBIP model at the CSVs in this folder. Run once after cloning.
Set-Location $PSScriptRoot
$old = 'C:\Users\tause\OneDrive\Documents\FIre Data\'
Get-ChildItem -Recurse -Filter *.tmdl | Where-Object { (Get-Content -LiteralPath $_.FullName -Raw).Contains($old) } | ForEach-Object {
  $text = (Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8).Replace($old, "$PWD\")
  [IO.File]::WriteAllText($_.FullName, $text)
}
