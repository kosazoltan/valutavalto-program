# Word dokumentumok szövegének kinyerése
$extractedPath = "c:\Users\Kósa Zoltán\OneDrive\Dokumentumok\GIThub munkamappa\valutavalto-program\extracted"
$outputPath = "$extractedPath\text_extracted"

# Kimeneti mappa létrehozása
if (-not (Test-Path $outputPath)) {
    New-Item -ItemType Directory -Path $outputPath | Out-Null
}

Write-Host "Word dokumentumok keresése..."

# Word COM objektum létrehozása
$word = New-Object -ComObject Word.Application
$word.Visible = $false

# Minden .docx fájl megkeresése
$docxFiles = Get-ChildItem -Path $extractedPath -Filter "*.docx" -Recurse -File

Write-Host "Talált fájlok: $($docxFiles.Count)"

$counter = 0
foreach ($file in $docxFiles) {
    $counter++
    Write-Host "[$counter/$($docxFiles.Count)] Feldolgozás: $($file.Name)"
    
    try {
        # Dokumentum megnyitása
        $doc = $word.Documents.Open($file.FullName, $false, $true) # ReadOnly = true
        
        # Szöveg kinyerése
        $text = $doc.Content.Text
        
        # Kimeneti fájl neve
        $outputFileName = $file.BaseName + ".txt"
        $outputFilePath = Join-Path $outputPath $outputFileName
        
        # Mentés UTF-8 encoding-gal
        $text | Out-File -FilePath $outputFilePath -Encoding UTF8
        
        Write-Host "  ✓ Mentve: $outputFileName"
        
        # Dokumentum bezárása
        $doc.Close($false)
    }
    catch {
        Write-Host "  ✗ HIBA: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Word bezárása
$word.Quit()
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($word) | Out-Null

Write-Host "`nKész! Kinyert fájlok: $outputPath"
