variable "aws_access_key" {}
variable "aws_secret_key" {}

locals {
  // replace with your cluster name
  cluster_name = "<replace with cluster name>"
  provider_name = "aws"
}

module "compute" {
  source = "upmaru/instellar/aws"
  version = "~> 0.4"

  access_key   = var.aws_access_key
  secret_key   = var.aws_secret_key
  cluster_name = local.cluster_name
  node_size    = "t3a.medium"
  cluster_topology = [
    // replace name of node with anything you like
    // you can use 01, 02 also to keep it simple.
    { id = 1, name = "01", size = "t3a.medium" },
    { id = 2, name = "02", size = "t3a.medium" },
  ]
  volume_type  = "gp3"
  storage_size = 40
  ssh_keys = [
    "<add your ssh key name>"
  ]
}

variable "instellar_auth_token" {}
module "instellar" {
  source  = "upmaru/bootstrap/instellar"
  version = "~> 0.3"

  auth_token      = var.instellar_auth_token
  cluster_name    = local.cluster_name
  region          = module.compute.region
  provider_name   = local.provider_name
  cluster_address = module.compute.cluster_address
  password_token  = module.compute.trust_token

  bootstrap_node = module.compute.bootstrap_node
  nodes          = module.compute.nodes
}