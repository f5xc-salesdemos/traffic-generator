locals {
  component = "traffic-generator"

  # --- Deployer resolution (4-tier fallback) ---
  # 1. Explicit override via var.deployer
  # 2a. Azure AD: given_name initial + surname
  # 2b. Azure AD: mail prefix (guest/external accounts)
  # 3. Object ID hash (service principals, managed identities)
  deployer_from_name = (
    var.deployer == "" && length(data.azuread_user.current) > 0
    ? try(
      lower("${substr(data.azuread_user.current[0].given_name, 0, 1)}${data.azuread_user.current[0].surname}"),
      ""
    )
    : ""
  )

  deployer_from_mail = (
    var.deployer == "" && length(data.azuread_user.current) > 0 && local.deployer_from_name == ""
    ? try(
      lower(split("@", data.azuread_user.current[0].mail)[0]),
      ""
    )
    : ""
  )

  deployer_from_oid = substr(sha1(data.azuread_client_config.current.object_id), 0, 8)

  deployer_resolved = coalesce(
    var.deployer,
    local.deployer_from_name,
    local.deployer_from_mail,
    local.deployer_from_oid
  )

  deployer = replace(lower(local.deployer_resolved), "/[^a-z0-9]/", "")

  # --- Resource naming (Cloud Adoption Framework) ---
  name = {
    resource_group    = "rg-${local.component}-${var.environment}-${local.deployer}"
    virtual_network   = "vnet-${local.component}-${local.deployer}"
    subnet            = "snet-${local.component}-${local.deployer}"
    public_ip         = "pip-${local.component}-${local.deployer}"
    nsg               = "nsg-${local.component}-${local.deployer}"
    network_interface = "nic-${local.component}-${local.deployer}"
    virtual_machine   = "vm-${local.component}-${local.deployer}"
  }

  # --- Standard tags ---
  standard_tags = {
    component   = local.component
    environment = var.environment
    deployer    = local.deployer
    managed_by  = "terraform"
  }

  tags = merge(local.standard_tags, var.tags)
}
