data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}

data "aws_bedrock_foundation_model" "embedding_model" {
  model_id = var.kb_model_id
}

data "aws_iam_user" "user" {
    user_name = "cloudops"
}

locals {
  account_id            = data.aws_caller_identity.current.account_id
  partition             = data.aws_partition.current.partition
  region                = data.aws_region.current.name
  region_name_tokenized = split("-", local.region)
  region_short          = "${substr(local.region_name_tokenized[0], 0, 2)}${substr(local.region_name_tokenized[1], 0, 1)}${local.region_name_tokenized[2]}"
}

resource "aws_opensearchserverless_security_policy" "encryption_policy" {
  name        = var.kb_oss_collection_name
  type        = "encryption"
  description = "Encryption policy for OpenSearch Serverless"
  policy = jsonencode({
    Rules = [
      {
        Resource = [
          "collection/${var.kb_oss_collection_name}"
        ]
        ResourceType = "collection"
      }
    ],
    AWSOwnedKey = true
  })
}

resource "aws_opensearchserverless_security_policy" "network_policy" {
  name        = var.kb_oss_collection_name
  type        = "network"
  description = "Network policy for OpenSearch Serverless"
  policy = jsonencode([
    {
      Rules = [
        {
          ResourceType = "collection"
          Resource = [
            "collection/${var.kb_oss_collection_name}"
          ]
        },
        {
          ResourceType = "dashboard"
          Resource = [
            "collection/${var.kb_oss_collection_name}"
          ]
        }
      ]
      AllowFromPublic = true
    }
  ])
}

resource "aws_opensearchserverless_access_policy" "access_policy" {
  name        = var.kb_oss_collection_name
  type        = "data"
  description = "Access policy for OpenSearch Serverless"

  policy = jsonencode([
    {
      Rules = [
        {
          ResourceType = "index"
          Resource = [
            "index/${var.kb_oss_collection_name}/*"
          ]
          Permission = [
            "aoss:CreateIndex",
            "aoss:DeleteIndex", # Required for Terraform
            "aoss:DescribeIndex",
            "aoss:ReadDocument",
            "aoss:UpdateIndex",
            "aoss:WriteDocument"
          ]
        },
        {
          ResourceType = "collection"
          Resource = [
            "collection/${var.kb_oss_collection_name}"
          ]
          Permission = [
            "aoss:CreateCollectionItems",
            "aoss:DescribeCollectionItems",
            "aoss:UpdateCollectionItems"
          ]
        }
      ],
      Principal = [
        aws_iam_role.bedrock_kb_role.arn,
        data.aws_caller_identity.current.arn,
        data.aws_iam_user.user.arn
      ]
    }
  ])
}


resource "aws_opensearchserverless_collection" "vector_collection" {
  name        = var.kb_oss_collection_name
  description = "OpenSearch Serverless vector collection"
  type        = "VECTORSEARCH"
  depends_on = [
    aws_opensearchserverless_access_policy.access_policy,
    aws_opensearchserverless_security_policy.encryption_policy,
    aws_opensearchserverless_security_policy.network_policy
  ]
}

resource "aws_iam_role_policy" "bedrock_kb_oss" {
  name = "AmazonBedrockOSSPolicyForKnowledgeBase_${var.kb_name}"
  role = aws_iam_role.bedrock_kb_role.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "aoss:APIAccessAll"
        Effect   = "Allow"
        Resource = aws_opensearchserverless_collection.vector_collection.arn
      }
    ]
  })
}

# create index
provider "opensearch" {
  url         = aws_opensearchserverless_collection.vector_collection.collection_endpoint
  healthcheck = false
}

resource "opensearch_index" "insurance_index" {
  name                           = var.kb_oss_vector_index_name
  number_of_shards               = "1"
  number_of_replicas             = "0"
  index_knn                      = true
  index_knn_algo_param_ef_search = "200" #balance for search performance and recall
  mappings                       = <<-EOF
    {
      "properties": {
        "bedrock-knowledge-base-default-vector": {
          "type": "knn_vector",
          "dimension": 1024,
          "method": {
            "name": "hnsw",
            "engine": "faiss",
            "parameters": {
              "m": 16,
              "ef_construction": 512
            },
            "space_type": "l2"
          }
        },
        "AMAZON_BEDROCK_METADATA": {
          "type": "text",
          "index": "false"
        },
        "AMAZON_BEDROCK_TEXT_CHUNK": {
          "type": "text",
          "index": "true"
        }
      }
    }
  EOF
  force_destroy                  = true
  depends_on                     = [aws_opensearchserverless_collection.vector_collection]
}

# Knowledge base resource role
resource "aws_iam_role" "bedrock_kb_role" {
  name = "AmazonBedrockExecutionRoleForKnowledgeBase_${var.kb_name}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Sid" : "AmazonBedrockKnowledgeBaseTrustPolicy"
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "bedrock.amazonaws.com"
        }
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = local.account_id
          }
          ArnLike = {
            "aws:SourceArn" = "arn:aws:bedrock:${local.region}:${local.account_id}:knowledge-base/*"
          }
        }
      }
    ]
  })
}

########

# Bedrock Knowledge Base
resource "awscc_bedrock_knowledge_base" "knowledge_base" {
  name        = var.kb_name
  description = "Knowledge base"
  role_arn    = aws_iam_role.bedrock_kb_role.arn

  storage_configuration = {
    type = "OPENSEARCH_SERVERLESS"
    opensearch_serverless_configuration = {
      collection_arn    = aws_opensearchserverless_collection.vector_collection.arn
      vector_index_name = var.kb_oss_vector_index_name
      field_mapping = {
        metadata_field = var.metadata_field
        text_field     = var.text_field
        vector_field   = var.vector_field
      }
    }
    depends_on = [
      aws_iam_role_policy.bedrock_kb_model,
      aws_iam_role_policy.s3_kb,
      opensearch_index.insurance_index
    ]
  }

  knowledge_base_configuration = {
    type = "VECTOR"
    vector_knowledge_base_configuration = {
      embedding_model_arn = "arn:${local.partition}:bedrock:${local.region}::foundation-model/${var.kb_model_id}"
    }
  }

}


# Bedrock Data Source
resource "awscc_bedrock_data_source" "data_source" {
  knowledge_base_id = awscc_bedrock_knowledge_base.knowledge_base.id
  name              = var.kb_name
  description       = "s3 data source"
  data_source_configuration = {
    type = "S3"
    s3_configuration = {
      bucket_arn = aws_s3_bucket.s3_kb.arn
    }
  }
  # vector_ingestion_configuration = {
  #   chunking_configuration = {
  #     chunking_strategy = "FIXED_SIZE"
  #     fixed_size_chunking_configuration = {
  #       max_tokens         = 200
  #       overlap_percentage = 20
  #     }
  #   }
  # }
}


########s3

resource "aws_s3_bucket" "s3_kb" {
  bucket        = "${var.kb_s3_bucket_name_prefix}-${local.region_short}-${local.account_id}"
  force_destroy = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "s3_kb" {
  bucket = aws_s3_bucket.s3_kb.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_iam_role_policy" "s3_kb" {
  name = "AmazonBedrockS3PolicyForKnowledgeBase_${var.kb_name}"
  role = aws_iam_role.bedrock_kb_role.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "S3ListBucketStatement"
        Action   = "s3:ListBucket"
        Effect   = "Allow"
        Resource = aws_s3_bucket.s3_kb.arn
        Condition = {
          StringEquals = {
            "aws:PrincipalAccount" = local.account_id
          }
      } },
      {
        Sid      = "S3GetObjectStatement"
        Action   = "s3:GetObject"
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.s3_kb.arn}/*"
        Condition = {
          StringEquals = {
            "aws:PrincipalAccount" = local.account_id
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "bedrock_kb_model" {
  name = "AmazonBedrockFoundationModelPolicyForKnowledgeBase_${var.kb_name}"
  role = aws_iam_role.bedrock_kb_role.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "bedrock:InvokeModel"
        Effect   = "Allow"
        Resource = data.aws_bedrock_foundation_model.embedding_model.model_arn
      }
    ]
  })
}

