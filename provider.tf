terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    opensearch = {
      source  = "opensearch-project/opensearch"
      version = "= 2.2.0"
    }
    awscc = {
      source  = "hashicorp/awscc"
      version = "1.7.0"
    }
  }
}

provider "aws" {
  region = var.region
}

provider "awscc" {
  region = var.region
}

## This is for demo porpuses, for production use, use a remote state backed by Amazon S3
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
