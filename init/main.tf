/* Variables
------------------------------------------------------------------*/
variable devSandbox {}
locals {sub = jsondecode(var.devSandbox)}

/* Config
------------------------------------------------------------------*/
variable "globals" {
  default = {
    tags = {
      env            = "dev"
      classification = "pbmm"
      owner          = "gerald.hill@canada.ca"
      contact        = "gregory.kealey@canada.ca"
      deployment     = "azure-bca-iac-2021-03-27"
    }
    env     = "ScDc"
    group   = "CTO"
    project = "MW"
  }
}
variable "user" {default = ""} # Change to "" after first deployment
variable "pwd" {default = ""} # Change to "" after first depployment

/* Provider
------------------------------------------------------------------*/
provider "azurerm" {
  version  = ">=2.2.0"
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
  count = "${var.user == "" ? 1 : 0}"
  name = join("", [var.globals.env,"CSV","-",var.globals.group,"-",var.globals.project,"-","kv"])
  resource_group_name = join("", [var.globals.env,"-",var.globals.group,"-",var.globals.project,"_test","-","rg"])
  provider = azurerm.ScSc-PBMMVDCSandbox
}
data "azurerm_key_vault_secret" "user" {
  count = "${var.user == "" ? 1 : 0}"
  name = join("", [var.globals.env,"-",var.globals.project,"-","deploy","-","admin"])
  key_vault_id = "${data.azurerm_key_vault.keyvault[0].id}"
  provider = azurerm.ScSc-PBMMVDCSandbox
}
data "azurerm_key_vault_secret" "pwd" {
  count = "${var.pwd == "" ? 1 : 0}"
  name = join("", [var.globals.env,"-",var.globals.project,"-","deploy","-","admin","-","pwd"])
  key_vault_id = "${data.azurerm_key_vault.keyvault[0].id}"
  provider = azurerm.ScSc-PBMMVDCSandbox
}

/* Init
------------------------------------------------------------------*/
module "init" {
  #source = "git::https://github.com/kealeyg/onboarding_Init.git"
  source = "../onboarding_Init/"
  globals = var.globals
  keyvault = {
    user = var.user == "" ? data.azurerm_key_vault_secret.user[0].value : var.user
    pwd = var.pwd == "" ? data.azurerm_key_vault_secret.pwd[0].value : var.pwd
  }
  providers = {azurerm.sub  = azurerm.ScSc-PBMMVDCSandbox}
}

/* Output
------------------------------------------------------------------*/
output "init" {value = module.init.moduleOutput}
