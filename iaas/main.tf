/* Variables
------------------------------------------------------------------*/
variable devSandbox {}
locals {
  sub = jsondecode(var.devSandbox)
  config = jsondecode(file("../config.json"))
}

/* Provider
------------------------------------------------------------------*/
provider "azurerm" {
  alias = "ScSc-PBMMVDCSandbox"
  features {}
  subscription_id = local.sub.subscription_id
  client_id = local.sub.client_id
  client_secret = local.sub.client_secret
  tenant_id = local.sub.tenant_id
}

/* Data
------------------------------------------------------------------*/
data "azurerm_key_vault" "keyvault" {
  count = local.config.user == "" ? 1 : 0
  name = join("", [local.config.globals.env,"CSV","-",local.config.globals.group,"-",local.config.globals.project,"-","kv"])
  resource_group_name = join("", [local.config.globals.env,"-",local.config.globals.group,"-",local.config.globals.project,"_test","-","rg"])
  provider = azurerm.ScSc-PBMMVDCSandbox
}
data "azurerm_key_vault_secret" "user" {
  count = local.config.user == "" ? 1 : 0
  name = join("", [local.config.globals.env,"-",local.config.globals.project,"-","deploy","-","admin"])
  key_vault_id = data.azurerm_key_vault.keyvault[0].id
  provider = azurerm.ScSc-PBMMVDCSandbox
}
data "azurerm_key_vault_secret" "pwd" {
  count = local.config.pwd == "" ? 1 : 0
  name = join("", [local.config.globals.env,"-",local.config.globals.project,"-","deploy","-","admin","-","pwd"])
  key_vault_id = data.azurerm_key_vault.keyvault[0].id
  provider = azurerm.ScSc-PBMMVDCSandbox
}

/* Iaas
------------------------------------------------------------------*/
module "Iaas" {
  #source = "git::https://github.com/kealeyg/onboarding_Iaas.git"
  source = "../../onboarding_Iaas/"
  globals = local.config.globals
  vnet = local.config.vnet
  snet = cidrsubnets(local.config.vnet,2,2)
  keyvault = {
    user = local.config.user == "" ? data.azurerm_key_vault_secret.user[0].value : local.config.user
    pwd = local.config.pwd == "" ? data.azurerm_key_vault_secret.pwd[0].value : local.config.pwd
  }
  providers = {azurerm.sub  = azurerm.ScSc-PBMMVDCSandbox}
}

/* Output
------------------------------------------------------------------*/
output "Iaas" {value = module.Iaas.moduleOutput}