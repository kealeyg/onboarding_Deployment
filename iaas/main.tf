/* Variables
------------------------------------------------------------------*/
variable devSandbox {}
locals {
  sub = jsondecode(var.devSandbox)
  config = jsondecode(file("../config.json"))
}

/* Provider
------------------------------------------------------------------*/
/*terraform {
  backend "azurerm" {
    container_name = "tfstate"
    storage_account_name = "scdcmw857stg"
    key                  = "m0/ZpNE7crLPTY5ArpulfaDHJYkXGr6f3VIWIYRjFkujyRskzpkNf5RST9pkVthOPAmRxENVvGmL4SyKdFj2iw=="
    #snapshot = "true"
  } 
}  
*/
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
  name = join("", [local.config.globals.env,"CSV","-",local.config.globals.group,"-",local.config.globals.project,"-","kv"])
  resource_group_name = join("", [local.config.globals.env,"-",local.config.globals.group,"-",local.config.globals.project,"_test","-","rg"])
  provider = azurerm.ScSc-PBMMVDCSandbox
}
data "azurerm_key_vault_secret" "user" {
  name = join("", [local.config.globals.env,"-",local.config.globals.project,"-","deploy","-","admin"])
  key_vault_id = data.azurerm_key_vault.keyvault.id
  provider = azurerm.ScSc-PBMMVDCSandbox
}
data "azurerm_key_vault_secret" "pwd" {
  name = join("", [local.config.globals.env,"-",local.config.globals.project,"-","deploy","-","admin","-","pwd"])
  key_vault_id = data.azurerm_key_vault.keyvault.id
  provider = azurerm.ScSc-PBMMVDCSandbox
}

/* Iaas
------------------------------------------------------------------*/
module "Iaas" {
  #source = "git::https://github.com/kealeyg/onboarding_Iaas.git"
  source = "../../onboarding_Iaas/"
  globals = local.config.globals
  vnet = local.config.vnet
  core = local.config.core
  snet = cidrsubnets(local.config.vnet,2,2)
  keyvault = {
    user = data.azurerm_key_vault_secret.user.value
    pwd = data.azurerm_key_vault_secret.pwd.value
  }
  providers = {azurerm.sub  = azurerm.ScSc-PBMMVDCSandbox}
}

/* Output
------------------------------------------------------------------*/
output "Iaas" {value = module.Iaas.moduleOutput}
