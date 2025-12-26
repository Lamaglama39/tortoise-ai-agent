# Data Source - S3 bucket containing tortoise knowledge documents
resource "aws_bedrockagent_data_source" "tortoise_docs" {
  knowledge_base_id = aws_bedrockagent_knowledge_base.tortoise.id
  name              = "${var.project_name}-knowledge-docs"

  description = "Source documents containing tortoise care guides, species information, and health management tips."

  data_source_configuration {
    type = "S3"

    s3_configuration {
      bucket_arn = aws_s3_bucket.documents.arn
      # Specify prefix to limit scope to tortoise-related documents
      inclusion_prefixes = ["tortoise-knowledge/"]
    }
  }
}
