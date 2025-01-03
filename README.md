# PowerShell Trello Backup Script

A robust PowerShell script to back up Trello boards, separating active and closed boards, excluding specified boards, and archiving backups into a single ZIP file.

## Features

- **Active and Closed Board Separation**: Backups are stored in separate folders for better organization.
- **Exclusion List**: Specify board IDs to exclude from backups.
- **Progress Tracking**: Displays the current board name and ID during the backup process.
- **Detailed Logging**: Logs all actions, errors, and skipped boards. Cleans the log file before each run.
- **Unified Archive**: Combines all backups into a single ZIP file for easy storage.
- **Retention Policy**: Automatically removes backups older than a specified number of days.

## Prerequisites

- **PowerShell**: Ensure you have PowerShell installed on your system.
- **Trello API Key and Token**:
  - Obtain your API key and token from [Trello Developer Portal](https://developer.atlassian.com/cloud/trello/guides/rest-api/api-introduction/).

## Setup

1. Clone the repository or copy the script file.
2. Update the following variables in the script:
   - `$apiKey`: Your Trello API key.
   - `$token`: Your Trello token.
   - `$excludedBoards`: Add board IDs to exclude from backups.
3. (Optional) Adjust settings like `$retentionDays` and `$compressionEnabled` as needed.

## Usage

1. Open PowerShell.
2. Navigate to the directory containing the script.
3. Run the script:
   ```powershell
   .\trello-backup.ps1
   ```

## Output

- Backups are saved in `C:\TrelloBackup`.
  - `ActiveBoards`: Contains JSON files of active boards.
  - `ClosedBoards`: Contains JSON files of closed boards.
- A unified ZIP archive of all backups is created in the root backup folder.

## Contributing

Feel free to submit issues or contribute enhancements to the project.

## Show your support

If you like this, please consider making a donation! 

[!["Buy Me A Coffee"](https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png)](https://buymeacoffee.com/ggiovine)

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.

