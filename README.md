# OneDriveSync PowerShell Module

## Overview
This repository provides a PowerShell module for synchronizing and comparing files between two directories, typically representing **external storage (e.g., OneDrive)** and **internal/local storage**.  
It includes functions to:
- **Synchronize paths** in one or both directions.
- **Compare paths** to identify differences, unique files, or storage usage.

The module is designed to simplify file management and ensure consistency between cloud and local directories.

---

## Repository Structure
- **onedrivesync.psm1**  
  PowerShell module file that imports all functions from the `Functions` folder and exports:
  - `Compare-Paths`
  - `Sync-Paths`

- **Sync-Paths.ps1**  
  Defines the `Sync-Paths` function, which synchronizes files between two directories.  
  Features:
  - Supports three directions: `Both`, `ExternalToInternal`, `InternalToExternal`.
  - Optional **SafeMode** to prevent overwriting or conflicting changes.
  - Detects and sets files as *online-only* using OneDrive attributes.
  - Displays progress during synchronization.

- **Compare-Paths.ps1**  
  Defines the `Compare-Paths` function, which compares two directories and reports differences.  
  Display modes:
  - `ExternalOnly` – files only in external path.
  - `InternalOnly` – files only in internal path.
  - `Full` – full listing of both paths.
  - `DifferencesOnly` – only mismatched files.
  - `Space` – summary of storage usage (total, external-only, internal-only).

---

## Installation
1. Clone or download this repository.
2. Import the module in PowerShell:
```powershell 
Import-Module .\onedrivesync.psm1

## Usage
Synchronize Paths
```
Sync-Paths -ExternalPath "C:\Users\Example\OneDrive" `
           -InternalPath "D:\LocalBackup" `
           -Direction Both `
           -SafeMode

