# AWS Catalog

This is a catalog of all the supported `blocks` for insterra. The format for these catalogs should be `tf.json` so they can be easily parsed by `insterra`.

![AWS logo](logo.svg)

## AWS Resources

- [x] Storage
  - [x] S3 Bucket
- [x] Networking
  - [x] VPC
- [x] Compute
  - [x] Cluster
    - [x] Bastion Node
    - [x] Bootstrap Node
    - [x] Expandable Compute Topology
  - [x] Reference network from `Foundation`
- [x] Database
  - [x] Reference network from `Foundation`

## Instellar Resources

- [x] Storage
- [x] Cluster
  - [x] Foundation Cluster
  - [x] Compute Cluster
- [x] Component
  - [x] Postgresql Service

### Running Terraform

Once you've configured your cluster simply run

```shell
terraform init
terraform plan
terraform apply
```

That's it! Everything should be automatically setup and ready to go!
