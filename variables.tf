variable "region" {
  default     = "us-east-1"
  description = "The region you want to deploy the solution"
}

variable "kb_s3_bucket_name_prefix" {
  description = "The name prefix of the S3 bucket for the data source of the knowledge base."
  type        = string
  default     = "kb-insurance"
}

variable "kb_oss_collection_name" {
  description = "The name of the OSS collection for the knowledge base."
  type        = string
  default     = "kb-insurance"
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


# variable "agent_model_id" {
#   description = "The ID of the foundational model used by the agent."
#   type        = string
#   default     = "anthropic.claude-3-haiku-20240307-v1:0"
# }

# variable "agent_name" {
#   description = "The agent name."
#   type        = string
#   default     = "InsuranceAssistant"
# }

# variable "agent_desc" {
#   description = "The agent description."
#   type        = string
#   default     = "An assisant that provides Insurance rate information."
# }

# variable "action_group_name" {
#   description = "The action group name."
#   type        = string
#   default     = "InsuranceAPI"
# }

# variable "action_group_desc" {
#   description = "The action group description."
#   type        = string
#   default     = "The currency exchange rates API."
# }

