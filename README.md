# AWS Bedrock Knowledge Base with OpenSearch Serverless

This repository contains OpenTofu scripts for deploying an AWS Bedrock Knowledge Base integrated with OpenSearch Serverless. This setup utilizes AWS's managed services to build a scalable retrieval-augmented generation (RAG) system, storing and retrieving vector embeddings for various use cases.

## Overview

The solution consists of the following components:

- **AWS Bedrock**: Used for generating text embeddings with models like Amazon Titan.
- **OpenSearch Serverless**: Serves as the vector database for storing embeddings and supports retrieval operations.
- **Amazon S3**: Acts as a storage for input data files, which can be in multiple formats like .txt, .md, .csv, etc.

## Prerequisites

Before deploying the solution, ensure you have the following prerequisites set up:

1. **OpenTofu**: Install OpenTofu on your local machine. You can download it from [OpenTofu's official site](https://opentofu.org/docs/intro/install/).

2. **AWS CLI**: Configure the AWS CLI with the necessary credentials. You can install it from the [AWS CLI website](https://aws.amazon.com/cli/).

3. **AWS Account**: Ensure you have access to an AWS account with the necessary permissions to create resources.

## Variables

Here are the key variables used in the Terraform scripts:

- **region**: The AWS region where the resources will be deployed. Default is `us-east-1`.

- **kb_s3_bucket_name_prefix**: The prefix for the S3 bucket name where data files for the knowledge base will be stored. Default is `kb-insurance`.

- **kb_oss_collection_name**: The name of the OpenSearch Serverless collection for the knowledge base. Default is `kb-insurance`.

- **kb_oss_vector_index_name**: The name of the vector index within the OpenSearch Serverless collection. Default is `bedrock-knowledge-base-default-index`.

- **kb_model_id**: The ID of the foundational model used by the knowledge base. Default is `amazon.titan-embed-text-v2:0`.

- **kb_name**: The name of the knowledge base. Default is `InsuranceKB`.

- **text_field**: The name of the field for storing text chunks in OpenSearch. Default is `AMAZON_BEDROCK_TEXT_CHUNK`.

- **vector_field**: The name of the field for storing vector embeddings in OpenSearch. Default is `bedrock-knowledge-base-default-vector`.

- **metadata_field**: The name of the field for storing metadata in OpenSearch. Default is `AMAZON_BEDROCK_METADATA`.

## Steps for Deployment

### 1. Clone the Repository

Clone the repository to your local machine:

```bash
git clone git@github.com:rakeshgohel01/aws-bedrock-opensearch-serverless-rag-tf.git
cd aws-bedrock-opensearch-serverless-rag-tf
```

# 2. Configure Variables

Edit the variables.tf file to configure any specific variables or use the defaults provided.

# 3. Deploy with OpenTofu

Deploy the infrastructure using OpenTofu:
    
```bash
tofu init
tofu apply -auto-approve
```

This deployment will set up an OpenSearch Serverless collection and a Bedrock Knowledge Base using the parameters defined in your variables.tf.

# 4. Upload Data to S3

Upload your data files to the S3 bucket created by the deployment. Supported formats include .txt, .md, .csv, .docx, and more.

# 5. Use the Knowledge Base

Once the deployment is complete, you can start using the knowledge base to perform retrieval-augmented generation tasks. Ensure you have the necessary IAM permissions configured for accessing the Bedrock API and OpenSearch resources.

# Cleanup

To destroy the resources created by OpenTofu:

```bash
tofu destroy
```

# Contributing

See CONTRIBUTING for more information on contributing to this project.

# License

This source code is licensed under the MIT License. See the LICENSE file for details.