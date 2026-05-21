# terraform-google-cloudrun-lb

A Terraform module for provisioning a dual-layer load balancer for Cloud Run services on GCP — an IAP-protected external HTTPS load balancer and an internal HTTP load balancer — with private DNS zones for VPC-internal routing.

## Features

- Serverless Network Endpoint Groups (NEGs) per Cloud Run service
- External Application Load Balancer with managed SSL certificate and path-based routing
- Identity-Aware Proxy (IAP) on all external backend services
- IAP access granted to a designated API Gateway service account
- Internal Application Load Balancer with per-service host-based routing
- Proxy-only subnet provisioned for the Internal LB
- Private DNS zone for `run.app` (routes Cloud Run traffic internally via restricted VIPs)
- Private DNS zone for `{env}.internal` (wildcard A record pointing to Internal LB IP)
- Domain convention: `api.{root_domain}` in prod, `api.{env}.{root_domain}` in non-prod environments

---

## Assumptions

- A basic understanding of [Git](https://git-scm.com/).
- Git version `>= 2.33.0`.
- An existing GCP IAM user or service account with permissions to create/update/delete the resources defined in [main.tf](https://github.com/nurdsoft/terraform-google-cloudrun-lb/blob/main/main.tf).
- [GCloud CLI](https://cloud.google.com/sdk/docs/install) `>= 465.0.0`.
- A basic understanding of [Terraform](https://www.terraform.io/).
- Terraform version `>= 1.3.0`.
- An existing VPC network with a subnet named `{environment}-default-subnet` in the target region.
- The IAP brand (`projects/{number}/brands/{number}`) already exists in the GCP project. IAP brands can only be created once per project.
- The Cloud Run services referenced in `path_routing_rules` are already deployed.
- The API Gateway service account referenced by `api_gateway_service_account_name` already exists.
- (Optional - for local testing) A basic understanding of [Make](https://www.gnu.org/software/make/manual/make.html#Introduction).
  - Make version `>= GNU Make 3.81`.
  - **Important Note**: This project includes a [Makefile](https://github.com/nurdsoft/terraform-google-cloudrun-lb/blob/main/Makefile) to speed up local development in Terraform. The `make` targets act as a wrapper around Terraform commands. As such, `make` has only been tested/verified on **Linux/Mac OS**. Though, it is possible to [install make using Chocolatey](https://community.chocolatey.org/packages/make), we **do not** guarantee this approach as it has not been tested/verified. You may use the commands in the [Makefile](https://github.com/nurdsoft/terraform-google-cloudrun-lb/blob/main/Makefile) as a guide to run each Terraform command locally on Windows.

---

## Test

**Important Note**: This project includes a [Makefile](https://github.com/nurdsoft/terraform-google-cloudrun-lb/blob/main/Makefile) to speed up local development in Terraform. The `make` targets act as a wrapper around Terraform commands. As such, `make` has only been tested/verified on **Linux/Mac OS**. Though, it is possible to [install make using Chocolatey](https://community.chocolatey.org/packages/make), we **do not** guarantee this approach as it has not been tested/verified. You may use the commands in the [Makefile](https://github.com/nurdsoft/terraform-google-cloudrun-lb/blob/main/Makefile) as a guide to run each Terraform command locally on Windows.

```sh
gcloud init # https://cloud.google.com/docs/authentication/gcloud
gcloud auth application-default login

# Copy the example tfvars and customize it
cp examples/complete/examples.tfvars examples/complete/terraform.tfvars
# Edit terraform.tfvars with your values

# Run terraform commands
make plan
make apply
make destroy
```

---

## Contributions

Contributions are always welcome. As such, this project uses the `main` branch as the source of truth to track changes.

**Step 1**. Clone this project.

```sh
# Using SSH
$ git clone git@github.com:nurdsoft/terraform-google-cloudrun-lb.git

# Using HTTPS
$ git clone https://github.com/nurdsoft/terraform-google-cloudrun-lb.git
```

**Step 2**. Checkout a feature branch: `git checkout -b feature/abc`.

**Step 3**. Validate the change/s locally by executing the steps defined under [Test](#test).

**Step 4**. If testing is successful, commit and push the new change/s to the remote.

```sh
$ git add file1 file2 ...

$ git commit -m "Adding some change"

$ git push --set-upstream origin feature/abc
```

**Step 5**. Once pushed, create a [PR](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request) and assign it to a member for review.

- **Important Note**: It can be helpful to attach the `terraform plan` output in the PR.

**Step 6**. A team member reviews/approves/merges the change/s.

**Step 7**. Once merged, deploy the required changes as needed.

**Step 8**. Once deployed, verify that the changes have been deployed.

- If possible, please add a `plan` output using the feature branch so the member reviewing the PR has better visibility into the changes.

---

## Usage

```hcl
module "cloudrun_lb" {
  source = "git::https://github.com/nurdsoft/terraform-google-cloudrun-lb.git?ref=main"

  project_id                       = "my-gcp-project"
  environment                      = "prod"
  region                           = "us-central1"
  vpc_network                      = "my-vpc"
  root_domain                      = "example.com"
  proxy_subnet_ip_cidr_range       = "10.120.0.0/24"
  google_restricted_vip_ips        = ["199.36.153.4", "199.36.153.5", "199.36.153.6", "199.36.153.7"]
  lb_ip_name                       = "lb-static-ip"
  api_gateway_service_account_name = "api-gateway-invoker-sa"

  path_routing_rules = {
    "/api"    = "my-api-service"
    "/health" = "my-api-service"
  }
}
```

## Examples

| Example | Description |
|---|---|
| [complete](./examples/complete) | Full setup with all inputs configured |

## Requirements

| Name | Version |
|---|---|
| terraform | >= 1.3 |
| google | ~> 5.0 |
| google-beta | ~> 5.0 |

## Providers

| Name | Version |
|---|---|
| [google](https://registry.terraform.io/providers/hashicorp/google/latest) | ~> 5.0 |
| [google-beta](https://registry.terraform.io/providers/hashicorp/google-beta/latest) | ~> 5.0 |

## Inputs

### Required

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| `project_id` | The GCP project ID. | `string` | n/a | yes |
| `environment` | The deployment environment (e.g., dev, prod). | `string` | n/a | yes |
| `vpc_network` | The name of the VPC network. | `string` | n/a | yes |
| `root_domain` | Base domain for the load balancer (e.g., example.com). | `string` | n/a | yes |
| `proxy_subnet_ip_cidr_range` | A unique, non-overlapping CIDR range for the proxy-only subnet used by the Internal LB's managed Envoy proxies. | `string` | n/a | yes |
| `google_restricted_vip_ips` | Restricted Google VIPs for Private Google Access to serverless. | `list(string)` | n/a | yes |
| `path_routing_rules` | Map of URL paths to Cloud Run service names (e.g., `{ "/api" = "my-service" }`). | `map(string)` | n/a | yes |

### Optional

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| `region` | The GCP region for resources. | `string` | `"us-central1"` | no |
| `lb_ip_name` | The name for the reserved global static IP. | `string` | `"lb-static-ip"` | no |
| `api_gateway_service_account_name` | Name of the API Gateway service account (without the `@project.iam.gserviceaccount.com` suffix) granted IAP access. | `string` | `"api-gateway-invoker-sa"` | no |

## Outputs

| Name | Description |
|---|---|
| `load_balancer_ip` | The static IP address of the external global load balancer. |
| `load_balancer_domain` | The custom domain configured for the external load balancer. |
| `internal_lb_ip` | The automatically assigned Internal LB IP. Update Tailscale DNS with this value. |

## Authors

Module is maintained by [Nurdsoft](https://github.com/nurdsoft).

## License

Apache 2 Licensed. See [LICENSE](https://github.com/nurdsoft/terraform-google-cloudrun-lb/blob/main/LICENSE) for full details.
