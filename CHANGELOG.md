# Changelog
All notable changes to this project will be documented in this file.

## v0.5.0
### Added
- Added `banzaicloud/vault-env`

### Changed
- Removed unwanted `echo` of args in `Dockerfile`

## v0.4.0
### Added
- Added `GOOGLE_PROJECT_ID` (required)

### Changed
- `GOOGLE_APPLICATION_CREDENTIALS` is now optional (to support workload-identity)

## v0.3.0
### Changed
- Changed the way timeouts and retries work.
    - It will now time out after the specified timeout without retries.
    - If it does time out it will check to see if it succeeded before reporting failure.

## v0.2.0 (2020-04-28)
### Added
- Added `GCLOUD_VERBOSITY` environment option
- Added `GCLOUD_WAIT_TIMEOUT` environment option

### Changed
- Added `gcloud sql operations wait` command to catch timeouts

## v0.1.0 (2020-03-18)
- Initial release

