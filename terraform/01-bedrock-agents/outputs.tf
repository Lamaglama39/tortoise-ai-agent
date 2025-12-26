output "s3_documents_bucket" {
  description = "S3 bucket for tortoise knowledge documents"
  value = {
    name = aws_s3_bucket.documents.bucket
    arn  = aws_s3_bucket.documents.arn
  }
}

output "s3_vectors" {
  description = "S3 Vectors configuration"
  value = {
    bucket_name = aws_s3vectors_vector_bucket.knowledge_vectors.vector_bucket_name
    bucket_arn  = aws_s3vectors_vector_bucket.knowledge_vectors.vector_bucket_arn
    index_name  = aws_s3vectors_index.knowledge_index.index_name
    index_arn   = aws_s3vectors_index.knowledge_index.index_arn
  }
}

output "knowledge_base" {
  description = "Bedrock Knowledge Base information"
  value = {
    id   = aws_bedrockagent_knowledge_base.tortoise.id
    arn  = aws_bedrockagent_knowledge_base.tortoise.arn
    name = aws_bedrockagent_knowledge_base.tortoise.name
  }
}

output "data_source" {
  description = "Bedrock Data Source information"
  value = {
    id   = aws_bedrockagent_data_source.tortoise_docs.data_source_id
    name = aws_bedrockagent_data_source.tortoise_docs.name
  }
}

output "agent" {
  description = "Bedrock Agent information"
  value = {
    id      = aws_bedrockagent_agent.tortoise_expert.agent_id
    arn     = aws_bedrockagent_agent.tortoise_expert.agent_arn
    name    = aws_bedrockagent_agent.tortoise_expert.agent_name
    version = aws_bedrockagent_agent.tortoise_expert.agent_version
  }
}

output "foundation_model" {
  description = "Foundation model configuration for Knowledge Base queries"
  value = {
    id  = var.foundation_model_id
    arn = "arn:aws:bedrock:${var.aws_region}:${data.aws_caller_identity.current.account_id}:inference-profile/${var.foundation_model_id}"
  }
}

output "env_file" {
  description = "Environment variables for Python scripts (.env format)"
  value       = <<-EOT
# AWS Configuration
AWS_REGION=${var.aws_region}

# S3 Configuration
DOCUMENTS_BUCKET=${aws_s3_bucket.documents.bucket}

# Bedrock Configuration
KNOWLEDGE_BASE_ID=${aws_bedrockagent_knowledge_base.tortoise.id}
DATA_SOURCE_ID=${aws_bedrockagent_data_source.tortoise_docs.data_source_id}
AGENT_ID=${aws_bedrockagent_agent.tortoise_expert.agent_id}
AGENT_ALIAS_ID=TSTALIASID
  EOT
}
