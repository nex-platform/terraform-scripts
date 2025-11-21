# Terraform Scripts

This repository contains reusable Terraform modules for application infrastructure setup on AWS.

## 📦 Available Modules

| Module | Description | Version |
|--------|-------------|---------|
| [EKS](./modules/eks/) | Amazon EKS cluster with node groups | v1.33 compatible |
| [ECR](./modules/ecr/) | Elastic Container Registry repositories | Latest |
| [CodePipeline](./modules/codepipeline/) | CI/CD pipeline with GitHub App integration | Latest |
| [IAM](./modules/iam/) | IAM roles and policies for application infrastructure | Latest |

## 🚀 Quick Start

### Using Modules

Each module can be consumed via Git source references:

```hcl
module "eks" {
  source = "git::https://github.com/nex-platform/terraform-scripts.git//modules/eks?ref=v1.0.0"
  
  cluster_name = "my-cluster"
  vpc_id       = "vpc-12345"
  subnet_ids   = ["subnet-12345", "subnet-67890"]
}
```

### Module Structure

Each module follows the standard Terraform module structure:

```
modules/
├── module-name/
│   ├── main.tf           # Main resources
│   ├── variables.tf      # Input variables
│   ├── outputs.tf        # Output values
│   ├── README.md         # Module documentation
│   └── examples/
│       └── basic/
│           └── main.tf   # Basic usage example
```

## 📋 Requirements

- Terraform >= 1.12.1
- AWS Provider >= 5.0
- Configured AWS credentials

## 🤝 Contributing

1. Create a feature branch from `main`
2. Make your changes following AWS and Terraform best practices
3. Ensure all modules pass validation via GitHub Actions
4. Submit a pull request

## 📖 Documentation

Detailed documentation for each module is available in their respective README files:

- [EKS Module Documentation](./modules/eks/README.md)
- [ECR Module Documentation](./modules/ecr/README.md)
- [CodePipeline Module Documentation](./modules/codepipeline/README.md)
- [IAM Module Documentation](./modules/iam/README.md)

## 🔒 Security

All modules follow AWS security best practices:

- Encryption at rest and in transit
- Least privilege IAM policies
- Secure defaults
- No hardcoded credentials

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🏷️ Versioning

We use [Semantic Versioning](http://semver.org/) for releases. For the versions available, see the [tags on this repository](https://github.com/nex-platform/terraform-scripts/tags).