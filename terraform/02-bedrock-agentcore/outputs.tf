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

output "agentcore_runtime_ecr" {
  description = "ECR repository for AgentCore Runtime container"
  value = {
    repository_url  = aws_ecr_repository.agentcore_runtime.repository_url
    repository_arn  = aws_ecr_repository.agentcore_runtime.arn
    repository_name = aws_ecr_repository.agentcore_runtime.name
  }
}

output "agentcore_runtime" {
  description = "AgentCore Runtime information"
  value = var.agentcore_runtime_image_tag != "" ? {
    runtime_id  = awscc_bedrockagentcore_runtime.tortoise[0].agent_runtime_id
    runtime_arn = awscc_bedrockagentcore_runtime.tortoise[0].agent_runtime_arn
    status      = awscc_bedrockagentcore_runtime.tortoise[0].status
  } : null
}

output "agentcore_runtime_endpoint" {
  description = "AgentCore Runtime Endpoint information"
  value = var.agentcore_runtime_image_tag != "" ? {
    endpoint_id  = awscc_bedrockagentcore_runtime_endpoint.tortoise[0].runtime_endpoint_id
    endpoint_arn = awscc_bedrockagentcore_runtime_endpoint.tortoise[0].agent_runtime_endpoint_arn
    status       = awscc_bedrockagentcore_runtime_endpoint.tortoise[0].status
  } : null
}
