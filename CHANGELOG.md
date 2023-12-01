# PSRelativityConfig Changelog

All notable changes to this project will be documented in this file.

## [0.1.4] - 2023-12-01

### Added
- Invoke-PSSessionConfigurationUnregistrationJob
- Invoke-StartRemoteServiceJob
- Invoke-StopRemoteServiceJob

### Changed
- Refactored EnsureServiceRunning method of RelativityServer class

## [0.1.3] - 2023-11-30

### Added
- Invoke-PSSessionConfigurationRegistrationJob

## [0.1.2] - 2023-11-29

### Added
- Get-DefaultThrottleLimit
- Invoke-RelativityInstall
- New-RelativityInstallerBundle

### Changed
- Added credential requirements to New-RelativityInstance and Get-RelativityInstance
- Refactored RelativityInstance and RelativityServer classes so default properties are set during validation if they're null

## [0.1.1] - 2023-11-26

### Added
- Get-RegistryKeyValue
- Get-RelativityInstanceSetting

### Changed
- Added method to RelativityServer to ensure important services were running
- Refactored Get-RelativityAgentServer for readability
- Refactored Get-RelativityPrimarySqlServer for readability
- Refactored Get-RelativitySecretStoreServer for readability
- Refactored Get-RelativityServiceBusServer for readability
- Refactored Get-RelativityWebServer for readability
- Refactored Get-RelativityWorkerManagerServer for readability
- Refactored Get-RelativityWorkerServer for readability
- Added progress reporting to Get-RelativityInstance

## [0.1.0] - 2023-11-25

### Added
- Changelog

### Changed
- Refactored Get-RelativityInstance