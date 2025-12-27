# Bedrock Knowledge Base with S3 Vectors
resource "aws_bedrockagent_knowledge_base" "tortoise" {
  name     = "${var.project_name}-kb"
  role_arn = aws_iam_role.bedrock_knowledge_base.arn

  description = "Knowledge base containing tortoise care information, species details, and health management guidelines."

  knowledge_base_configuration {
    type = "VECTOR"

    vector_knowledge_base_configuration {
      # Titan Text Embeddings V2 model
      embedding_model_arn = "arn:${data.aws_partition.current.partition}:bedrock:${data.aws_region.current.name}::foundation-model/${var.embedding_model_id}"

      embedding_model_configuration {
        bedrock_embedding_model_configuration {
          dimensions          = var.vector_dimension
          embedding_data_type = "FLOAT32"
        }
      }
    }
  }

  # S3 Vectors as the vector store
  storage_configuration {
    type = "S3_VECTORS"

    s3_vectors_configuration {
      index_arn = aws_s3vectors_index.knowledge_index.index_arn
    }
  }

  depends_on = [
    aws_iam_role_policy.bedrock_kb_s3_access,
    aws_iam_role_policy.bedrock_kb_s3vectors_access,
    aws_iam_role_policy.bedrock_kb_model_access
  ]
}

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
