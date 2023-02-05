# Load the System.Windows.Forms assembly
Add-Type -AssemblyName System.Windows.Forms

# Prompt the user for the input directory
$folderBrowserDialog = New-Object System.Windows.Forms.FolderBrowserDialog
$folderBrowserDialog.Description = "Select the input directory"
if ($folderBrowserDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK)
{
  $inputDirectory = $folderBrowserDialog.SelectedPath
}
else
{
  Write-Host "No input directory selected. Exiting."
  return
}

$outputDirectory = "$($inputDirectory)\Translated"
if (Test-Path $outputDirectory)
{
    Remove-Item $outputDirectory -Recurse -Force
}
$outputDirectory = New-Item "$($inputDirectory)\Translated" -ItemType Directory

# Get a list of the image files in the input directory
$imageFiles = Get-ChildItem $inputDirectory | Where-Object { -not $_.PSIsContainer }
Write-Output $imageFiles

# Loop through each image file
foreach ($imageFile in $imageFiles)
{
  # Get the base name of the file
  $baseName = [System.IO.Path]::GetFileNameWithoutExtension($imageFile.FullName)
  # Run Tesseract on the file
  & "C:\Program Files\Tesseract-OCR\tesseract.exe" "$($imageFile.FullName)" "$($outputDirectory)\$($baseName)" -l deu
  # Translate the text from German to English using the Google Translate API
  $text = Get-Content "$($outputDirectory)\$($baseName).txt" -Raw
  $translatedText = Invoke-WebRequest -Uri "https://translation.googleapis.com/language/translate/v2?target=en&key=APi_KEY&format=text&q=$text" | Select-Object -ExpandProperty Content | ConvertFrom-Json | Select-Object -ExpandProperty data | Select-Object -ExpandProperty translations | Select-Object -ExpandProperty translatedText
  # Write the translated text to a file
  $translatedText | Set-Content "$($outputDirectory)\$($baseName)_translated.txt" -Force
}
