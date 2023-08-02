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
  version = "~> 0.4"

  bucket_name = var.identifier
}

module "foundation_basic" {
  source  = "upmaru/instellar/aws"
  version = "~> 0.4"

  cluster_name = var.identifier
  node_size    = "t3a.medium"
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
  version = "~> 0.4"

  identifier = var.identifier

  db_size        = "db.t3.small"
  db_name        = "instellardb"
  engine         = "postgres"
  engine_version = "15"
  port           = 5432

  db_username = "instellar"

  subnet_ids          = module.foundation_basic.public_subnet_ids
  security_group_ids  = [module.foundation_basic.nodes_security_group_id]
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

module "cluster_basic" {
  source  = "upmaru/bootstrap/instellar"
  version = "~> 0.3"

  cluster_name    = var.identifier
  region          = var.aws_region
  provider_name   = var.provider_name
  cluster_address = module.foundation_basic.cluster_address
  password_token  = module.foundation_basic.trust_token

  bootstrap_node = module.foundation_basic.bootstrap_node
  nodes          = module.foundation_basic.nodes
}

module "service_postgresql" {
  source  = "upmaru/bootstrap/instellar//modules/service"
  version = "~> 0.4"

  slug           = module.database_postgresql.identifier
  provider_name  = var.provider_name
  driver         = "database/postgresql"
  driver_version = "15"
  cluster_ids    = [module.cluster_basic.cluster_id]
  channels       = ["develop", "master"]
  credential = {
    username = module.database_postgresql.username
    password = module.database_postgresql.password
    database = module.database_postgresql.db_name
    host     = module.database_postgresql.address
    port     = module.database_postgresql.port
  }
}