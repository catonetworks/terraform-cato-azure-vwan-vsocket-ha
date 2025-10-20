# Changelog

## 0.1.0 (2025-01-20) - Multi-Resource Group Support

### 🚀 Major Features
- **Multi-Resource Group Architecture**: Complete refactoring to support flexible resource group organization with three distinct resource group types:
  - **vWAN Resource Group**: Contains Azure Virtual WAN infrastructure
  - **vHub Resource Groups**: Contains Virtual Hub resources (per region)
  - **Cato Resource Groups**: Contains vSocket VMs and related networking resources (per region or shared)
- **Advanced Resource Group Strategies**: Multiple configuration patterns supported:
  - `create_new`: Creates dedicated resource groups
  - `use_existing`: Uses existing resource groups
  - `use_vwan_rg`: Consolidates vHub resources with vWAN
  - `use_shared`: Shared Cato resource group across regions
- **Comprehensive Configuration Examples**: Four detailed scenarios covering all resource group patterns:
  - Scenario 1: Full separation with dedicated RGs per component and region
  - Scenario 2: Mixed strategy with existing vWAN, consolidated vHubs, shared Cato RGs
  - Scenario 3: Complete brownfield with all existing resource groups
  - Scenario 4: Legacy backward-compatible single resource group

### ✨ Enhancements
- **Backward Compatibility**: Full compatibility with existing single resource group configurations
- **Flexible Organization**: Support for enterprise resource organization patterns
- **Cost Management**: Separate billing and cost tracking via resource group separation
- **Access Control**: RBAC implementation at resource group level for different teams
- **Regional Compliance**: Resource group strategies for data residency requirements
- **Migration Support**: Seamless migration path from legacy to new resource group configurations

### 🔧 Technical Improvements
- **Enhanced Locals Logic**: Refactored `locals.tf` with intelligent resource group name resolution:
  - `local.vwan_rg_name` for vWAN resource group determination
  - `local.vhub_rg_names` map for per-region vHub resource groups
  - `local.cato_rg_names` map for per-region or shared Cato resource groups
- **Conditional Resource Creation**: Smart resource group provisioning based on configuration strategy
- **Data Source Integration**: Automatic lookup of existing resource groups when using `use_existing` strategy
- **Resource Reference Updates**: All resources now reference appropriate resource group via locals
- **Variable Validation**: Comprehensive validation rules for resource group configuration consistency

### 📚 Documentation
- **Comprehensive Resource Group Guide**: Detailed documentation covering all configuration patterns
- **Best Practices**: Guidelines for cost management, access control, and organizational patterns
- **Troubleshooting Guide**: Common issues and solutions for resource group configurations
- **Migration Examples**: Step-by-step migration from legacy to new configuration
- **Updated Testing Scenarios**: All test scenarios updated to demonstrate resource group capabilities

### 🔄 Deprecated (Still Supported)
- `create_resource_group` variable: Use `vwan_resource_group.create_new` instead
- `resource_group_name` variable: Use `vwan_resource_group.name` instead
- `existing_resource_group_name` variable: Use `vwan_resource_group.name` with `create_new = false`

### 🧪 Testing
- **Multi-Resource Group Test Scenarios**: All test scenarios updated and validated:
  - `scenario1`: New deployment with separate resource groups
  - `scenario2`: Mixed strategy with existing vWAN and shared Cato RG
  - `scenario3`: All existing infrastructure with per-region resource groups
  - `scenario4`: Backward compatibility with legacy single resource group
- **Cross-Scenario Validation**: Verified proper resource placement and reference resolution
- **Destruction Testing**: Validated clean resource cleanup across all resource group strategies

### ⚠️ Breaking Changes
- None - Full backward compatibility maintained

### 📋 Requirements
- Terraform >= 1.5.0
- Azure Provider >= 4.36.0
- Cato Provider >= 0.0.42

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