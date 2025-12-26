variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "ap-northeast-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "tortoise-ai-bedrock-agent-core"
}

# S3 Vectors Configuration
variable "vector_dimension" {
  description = "Dimension of vector embeddings (Titan Text Embeddings V2)"
  type        = number
  default     = 1024

  validation {
    condition     = contains([256, 384, 1024], var.vector_dimension)
    error_message = "Vector dimension must be 256, 384, or 1024 for Titan Text Embeddings V2."
  }
}

variable "distance_metric" {
  description = "Distance metric for vector similarity search"
  type        = string
  default     = "cosine"

  validation {
    condition     = contains(["cosine", "euclidean"], var.distance_metric)
    error_message = "Distance metric must be 'cosine' or 'euclidean'."
  }
}

# Bedrock Configuration
variable "embedding_model_id" {
  description = "Bedrock embedding model ID"
  type        = string
  default     = "amazon.titan-embed-text-v2:0"
}

variable "foundation_model_id" {
  description = "Bedrock foundation model ID or inference profile ARN for the agent"
  type        = string
  # ap-northeast-1ではクロスリージョンInference Profileを使用
  default = "apac.anthropic.claude-3-5-sonnet-20241022-v2:0"
}

# AgentCore Runtime Configuration
variable "agentcore_runtime_image_tag" {
  description = "Docker image tag for AgentCore Runtime container. Leave empty to skip Runtime/Endpoint creation (useful for initial ECR setup)"
  type        = string
  default     = ""
}
