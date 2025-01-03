# Configuration
$apiKey = ""
$token = ""
$outputDirectory = "C:\TrelloBackup"
$activeDirectory = Join-Path $outputDirectory "ActiveBoards"
$closedDirectory = Join-Path $outputDirectory "ClosedBoards"
$finalZipFile = Join-Path $outputDirectory "TrelloBackup_$(Get-Date -Format 'yyyyMMdd_HHmmss').zip"
$logFile = "C:\TrelloBackup\TrelloBackup.log"
$retentionDays = 30  # Number of days to keep backups
$compressionEnabled = $true  # Enable or disable compression

# List of boards to exclude from the backup
$excludedBoards = @(
    "BOARD_ID_1",  # Replace with actual board IDs
    "BOARD_ID_2"   # Replace with additional IDs as needed
)

# Create the output directories if they don't exist
foreach ($dir in @($outputDirectory, $activeDirectory, $closedDirectory)) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir
    }
}

# Function to log messages with levels
function Log-Message {
    param (
        [string]$level,  # Log level: INFO, WARNING, ERROR
        [string]$message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp [$level] - $message" | Out-File -Append -FilePath $logFile
}

# Function to call Trello API
function Invoke-TrelloAPI {
    param (
        [string]$url
    )
    $maxRetries = 3
    $retryCount = 0
    while ($retryCount -lt $maxRetries) {
    try {
        return Invoke-RestMethod -Uri $url -Method Get
    } catch {
            $retryCount++
            Start-Sleep -Seconds 2
            if ($retryCount -ge $maxRetries) {
        $errorDetails = @{
            URL        = $url
            Error      = $_.Exception.Message
            StackTrace = $_.Exception.StackTrace
        } | ConvertTo-Json -Depth 10 -Compress
                Log-Message -level "ERROR" -message "Max retries reached for URL: $url. Error: $errorDetails"
        throw
    }
}
    }
}

# Function to compress all directories into a single ZIP
function Compress-All {
    param (
        [string]$sourceDirectory,
        [string]$outputZip
    )
    Compress-Archive -Path "$sourceDirectory\*" -DestinationPath $outputZip -Force
    Log-Message -level "INFO" -message "Compressed all backups into $outputZip"
}

# Function to clean up old backups
function Cleanup-OldBackups {
    param (
        [string]$directory,
        [int]$retentionDays
    )
    $cutoffDate = (Get-Date).AddDays(-$retentionDays)
    Get-ChildItem -Path $directory -File | Where-Object { $_.LastWriteTime -lt $cutoffDate } | ForEach-Object {
        Remove-Item $_.FullName -Force
        Log-Message -level "INFO" -message "Deleted old backup file: $($_.FullName)"
    }
}

# Function to display progress
function Show-Progress {
    param (
        [int]$current,
        [int]$total,
        [string]$boardName,
        [string]$boardId
    )
    $percentComplete = [math]::Round(($current / $total) * 100, 2)
    Write-Progress -Activity "Backing up Trello boards" -Status "$percentComplete% Complete - Processing board: $boardName (ID: $boardId)" -PercentComplete $percentComplete
}

# Clean the log before starting a new backup
if (Test-Path $logFile) {
    Clear-Content -Path $logFile
}

# Log the start of the backup
Log-Message -level "INFO" -message "Backup process started."

try {
    # Get all boards
    $boardsUrl = "https://api.trello.com/1/members/me/boards?key=$apiKey&token=$token"
    $boards = Invoke-TrelloAPI -url $boardsUrl

    if (-not $boards -or $boards.Count -eq 0) {
        Log-Message -level "WARNING" -message "No boards found for backup."
        exit
    }

    $totalBoards = $boards.Count
    $currentBoard = 0
    $errorCount = 0

    # Backup each board
    foreach ($board in $boards) {
        $boardId = $board.id

        # Skip excluded boards
        if ($excludedBoards -contains $boardId) {
            Log-Message -level "INFO" -message "Skipping excluded board with ID: $boardId"
            continue
        }

        $currentBoard++
        $boardName = $board.name -replace '[^\w]', '_'
        Show-Progress -current $currentBoard -total $totalBoards -boardName $boardName -boardId $boardId
        try {
            Log-Message -level "INFO" -message "Processing board with ID: $boardId"

            # Determine the output directory based on board status
            $destinationDirectory = if ($board.closed -eq $true) { $closedDirectory } else { $activeDirectory }
            $backupFile = Join-Path $destinationDirectory "$boardName.json"

            $boardDataUrl = "https://api.trello.com/1/boards/$($boardId)?key=$($apiKey)&token=$($token)&cards=all&lists=all"
            Log-Message -level "INFO" -message "Board data URL: $boardDataUrl"

            $boardData = Invoke-TrelloAPI -url $boardDataUrl

            # Save the board data as JSON
            $boardData | ConvertTo-Json -Depth 10 | Set-Content -Path $backupFile

            Log-Message -level "INFO" -message "Backed up board '$boardName' to $backupFile"
        } catch {
            $errorCount++
            Log-Message -level "WARNING" -message "Error backing up board '$boardName' (ID: $boardId): $_"
        }
    }

    # Compress all backups into a single ZIP if enabled
    if ($compressionEnabled) {
        Compress-All -sourceDirectory $outputDirectory -outputZip $finalZipFile
    }

    # Clean up old backups
    Cleanup-OldBackups -directory $outputDirectory -retentionDays $retentionDays

    # Summary Report
    $summary = @{
        TotalBoards       = $totalBoards
        SkippedBoards     = $excludedBoards.Count
        BackedUpBoards    = $totalBoards - $excludedBoards.Count - $errorCount
        ErrorsEncountered = $errorCount
    } | ConvertTo-Json -Depth 10
    Log-Message -level "INFO" -message "Backup Summary: $summary"

    Log-Message -level "INFO" -message "Backup process completed successfully."
} catch {
    Log-Message -level "ERROR" -message "Backup process failed: $_"
}
