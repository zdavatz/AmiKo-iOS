# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

AmiKo is a Swiss healthcare medication reference and prescription management app for iPhone/iPad, written entirely in Objective-C. It targets healthcare professionals (doctors, pharmacists) in Switzerland. Licensed under GPLv3.0.

## Build Commands

**Prerequisites:** CocoaPods, wget, and medication databases from pillbox.oddb.org.

```bash
# Install dependencies
pod install

# Download required databases (must be in AmiKoDesitin/ directory)
cd AmiKoDesitin
for LANG in de fr; do
  wget http://pillbox.oddb.org/amiko_report_$LANG.html
  for DB in drug_interactions_csv_$LANG.zip amiko_frequency_$LANG.db.zip amiko_db_full_idx_$LANG.zip; do
    wget http://pillbox.oddb.org/$DB && unzip $DB && rm $DB
  done
done

# Build (from repo root) — must use workspace, not project
xcodebuild clean build -workspace AmikoDesitin.xcworkspace -scheme AmiKoDesitin
xcodebuild clean build -workspace AmikoDesitin.xcworkspace -scheme CoMedDesitin

# Build without code signing (CI)
xcodebuild clean build archive -allowProvisioningUpdates -workspace AmikoDesitin.xcworkspace -scheme AmiKoDesitin CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO

# Full release build
./scripts/build.sh Release
```

There are no automated tests (no XCTest targets).

## Credential Setup

Before building, copy and fill these credential files:
- `AmiKoDesitin/HINClient/MLHINClientCredential.sample.h` → `MLHINClientCredential.h`
- `AmiKoDesitin/EPrescription/ZurRoseCredential.h.sample` → `ZurRoseCredential.h`
- Place ZurRose certificate at `AmiKoDesitin/EPrescription/client.p12`

## Two App Targets (Same Codebase)

The codebase produces two apps differentiated by preprocessor macros:
- **AmiKoDesitin** — German (`de`) medication database, `AMIKO_DESITIN` macro
- **CoMedDesitin** — French (`fr`) medication database, `COMED_DESITIN` macro

Target differentiation is handled in `MLConstants.m` via `#if defined(AMIKO_DESITIN)` / `#elif defined(COMED_DESITIN)`. The `MLConstants` class provides `+databaseLanguage`, `+appOwner`, `+iCloudContainerIdentifier` etc. based on the active target. When modifying target-specific behavior, always handle both variants.

## Architecture

**Pattern:** MVC with a slide-out menu (`SWRevealViewController`).

**Source layout:** All source files are flat in `AmiKoDesitin/` with two subdirectories:
- `HINClient/` — Swiss Health Information Network OAuth integration
- `EPrescription/` — ZurRose pharmacy e-prescription submission
- `Persistence/` — Core Data persistence and iCloud sync

**Key layers:**

| Layer | Key Files | Purpose |
|-------|-----------|---------|
| App Entry | `MLAppDelegate` | App lifecycle, URL scheme handling (`.amk` files) |
| Main UI | `MLViewController` | Central search interface with tabs (AIPS, Favorites, Interactions, Desitin, Prescription) |
| Menu | `MLMenuViewController` via `SWRevealViewController` | Slide-out navigation menu |
| Medication DB | `MLDBAdapter` | SQLite queries against `amiko_db_full_idx_*.db` |
| Full-text Search | `FullTextDBAdapter` + `FullTextViewController` | Full-text medication search via `amiko_frequency_*.db` |
| Patient Mgmt | `PatientViewController`, `PatientDbListViewController` | Patient CRUD with Core Data |
| Prescriptions | `PrescriptionViewController`, `AmkListViewController` | Create/manage/email prescriptions |
| Persistence | `MLPersistenceManager` | Core Data stack with iCloud sync |
| Drug Interactions | `MLInteractionsAdapter` + `JavaScript/interactions.js` | CSV-based interaction data rendered via JavaScript in WebView |
| HIN Auth | `MLHINClient`, `MLHINTokens` | OAuth flow for Swiss health network |
| e-Prescription | `EPrescription`, `ZurRosePrescription` | Submit prescriptions to ZurRose pharmacy |

**Data models:** `MLMedication`, `Patient`, `Prescription`, `Operator` (doctor), `Product`.

**Database files** (downloaded at build time, not in repo):
- `amiko_db_full_idx_de.db` / `amiko_db_full_idx_fr.db` — Main medication SQLite databases
- `amiko_frequency_de.db` / `amiko_frequency_fr.db` — Full-text search databases
- `drug_interactions_csv_de.csv` / `drug_interactions_csv_fr.csv` — Drug interaction data

## Dependencies

Managed via CocoaPods (`Podfile`):
- **GZIP** (~> 1.3.0) — Data compression
- **KissXML** (~> 5.3.1) — XML parsing

Embedded libraries (in source tree):
- **minizip** — ZIP archive handling
- **SWRevealViewController** — Slide-out menu UI
- **LFCGzipUtility** — GZIP utilities

## Localization

Three languages: German (`de.lproj`), French (`fr.lproj`), English (`en.lproj`). Strings are in `Localizable.strings` and storyboard localization files.

## CI/CD

GitHub Actions workflows in `.github/workflows/`:
- `build.yml` — Builds both schemes on every push (no code signing)
- `archive.yaml` — Creates release archives on tagged pushes
- `codeql.yml` — Weekly CodeQL analysis
