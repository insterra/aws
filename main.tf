variable "identifier" {}
variable "provider_name" {
  default = "aws"
}

variable "aws_region" {}
variable "aws_access_key" {}
variable "aws_secret_key" {}

provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

module "storage_s3" {
  source  = "upmaru/instellar/aws//modules/storage"
  version = "~> 0.5"

  bucket_name = var.identifier
}

module "foundation_basic" {
  source  = "upmaru/instellar/aws"
  version = "~> 0.5"

  identifier = "orion"
  node_size  = "t3a.medium"

  cluster_topology = [
    // replace name of node with anything you like
    // you can use 01, 02 also to keep it simple.
    { id = 1, name = "01", size = "t3a.medium" },
    { id = 2, name = "02", size = "t3a.medium" },
  ]

  volume_type  = "gp3"
  storage_size = 40
  ssh_keys     = []
}

module "compute_basic" {
  source  = "upmaru/instellar/aws"
  version = "~> 0.5"

  block_type        = "compute"
  vpc_id            = module.foundation_basic.vpc_id
  public_subnet_ids = module.foundation_basic.public_subnet_ids

  identifier = "milkyway"
  node_size  = "t3a.medium"

  cluster_topology = [
    // replace name of node with anything you like
    // you can use 01, 02 also to keep it simple.
    { id = 1, name = "01", size = "t3a.medium" },
    { id = 2, name = "02", size = "t3a.medium" },
  ]

  volume_type  = "gp3"
  storage_size = 40
  ssh_keys     = []
}

module "database_postgresql" {
  source  = "upmaru/instellar/aws//modules/database"
  version = "~> 0.5"

  identifier = "perceptual"

  db_size        = "db.t3.small"
  db_name        = "instellardb"
  engine         = "postgres"
  engine_version = "15"
  port           = 5432

  db_username = "instellar"

  subnet_ids = module.foundation_basic.public_subnet_ids

  security_group_ids = [
    module.foundation_basic.nodes_security_group_id,
    module.compute_basic.nodes_security_group_id,
  ]

  vpc_id              = module.foundation_basic.vpc_id
  deletion_protection = false
  skip_final_snapshot = true
}

variable "instellar_host" {}
variable "instellar_auth_token" {}

provider "instellar" {
  host       = var.instellar_host
  auth_token = var.instellar_auth_token
}

module "cluster_foundation_basic" {
  source  = "upmaru/bootstrap/instellar"
  version = "~> 0.5"

  cluster_name    = module.foundation_basic.identifier
  region          = var.aws_region
  provider_name   = var.provider_name
  cluster_address = module.foundation_basic.cluster_address
  password_token  = module.foundation_basic.trust_token

  bootstrap_node = module.foundation_basic.bootstrap_node
  nodes          = module.foundation_basic.nodes
}

module "cluster_compute_basic" {
  source  = "upmaru/bootstrap/instellar"
  version = "~> 0.5"

  cluster_name    = module.compute_basic.identifier
  region          = var.aws_region
  provider_name   = var.provider_name
  cluster_address = module.compute_basic.cluster_address
  password_token  = module.compute_basic.trust_token

  bootstrap_node = module.compute_basic.bootstrap_node
  nodes          = module.compute_basic.nodes
}

module "service_postgresql" {
  source  = "upmaru/bootstrap/instellar//modules/service"
  version = "~> 0.5"

  slug           = module.database_postgresql.identifier
  provider_name  = var.provider_name
  driver         = "database/postgresql"
  driver_version = "15"

  cluster_ids = [
    module.cluster_foundation_basic.cluster_id,
    module.cluster_compute_basic.cluster_id
  ]

  channels = ["develop", "master"]
  credential = {
    username = module.database_postgresql.username
    password = module.database_postgresql.password
    resource = module.database_postgresql.db_name
    host     = module.database_postgresql.address
    port     = module.database_postgresql.port
    secure   = true
  }
}