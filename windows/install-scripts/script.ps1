# Define the directory path
$DirPath = ".\"

# Define the newline character for the current operating system
$NewLine = [Environment]::NewLine

# Get all files recursively in the specified directory
Get-ChildItem -Path $DirPath -File -Recurse | ForEach-Object {
    $file = $_
    # Read the file content as raw string to preserve existing newlines and read the last character
    $content = Get-Content -Path $file.FullName -Raw

    # Check if the file is empty
    if ($content.Length -eq 0) {
        Write-Host "File $($file.Name) is empty, skipping check."
        return
    }

    # Get the last character (which could be the start of a newline sequence)
    $lastChar = $content[-1]

    # Check if the last character is a Line Feed (`n) or Carriage Return (`r)
    # This covers Windows style (CRLF) and Unix style (LF) newlines
    if ($lastChar -eq "`n" -or $lastChar -eq "`r") {
        Write-Host "File $($file.Name) already ends with a newline, skipping."
    }
    else {
        # If no newline exists, append the system-appropriate newline sequence
        Write-Host "File $($file.Name) does not end with a newline. Adding one."
        Add-Content -Path $file.FullName -Value $NewLine
    }
}

