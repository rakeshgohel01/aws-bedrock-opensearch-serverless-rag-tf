variable "region" {
  default     = "us-east-1"
  description = "The region you want to deploy the solution"
}

variable "kb_s3_bucket_name_prefix" {
  description = "The name prefix of the S3 bucket for the data source of the knowledge base."
  type        = string
  default     = "kb-insuranc-collection-store"
}

variable "kb_oss_collection_name" {
  description = "The name of the OSS collection for the knowledge base."
  type        = string
  default     = "kb-insurance-collection"
}

variable "kb_oss_vector_index_name" {
  type    = string
  default = "bedrock-knowledge-base-default-index"
}

variable "kb_model_id" {
  description = "The ID of the foundational model used by the knowledge base."
  type        = string
  default     = "amazon.titan-embed-text-v2:0"
}

variable "kb_name" {
  description = "The knowledge base name."
  type        = string
  default     = "InsuranceKB"
}

variable "text_field" {
  type    = string
  default = "AMAZON_BEDROCK_TEXT_CHUNK"
}

variable "vector_field" {
  type    = string
  default = "bedrock-knowledge-base-default-vector"
}

variable "metadata_field" {
  type    = string
  default = "AMAZON_BEDROCK_METADATA"
}