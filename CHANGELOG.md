# Changelog

## 0.0.1 (2025-09-15) - Initial Release

### Features
- Initial commit of Azure Virtual WAN vSocket HA module
- Multi-regional deployment support for Cato vSockets across Azure regions
- Support for three deployment scenarios:
  - New vWAN, New vHubs, New vSockets
  - Existing vWAN, New vHubs, New vSockets  
  - Existing vWAN, Existing vHubs, New vSockets
- High Availability configuration with primary and secondary vSocket instances
- BGP peering integration between Cato and Azure Virtual Hub
- Dynamic site location resolution from Azure region
- Support for routed networks and static range translation
- Comprehensive resource management with proper tagging
- Automated vSocket provisioning and configuration
- Support for both new and existing Azure infrastructure integration (Greenfield / Brownfield)