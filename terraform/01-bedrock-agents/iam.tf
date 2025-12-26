# =============================================================================
# IAM Role for Bedrock Knowledge Base
# =============================================================================

resource "aws_iam_role" "bedrock_knowledge_base" {
  name = "${var.project_name}-kb-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "bedrock.amazonaws.com"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
          ArnLike = {
            "aws:SourceArn" = "arn:${data.aws_partition.current.partition}:bedrock:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:knowledge-base/*"
          }
        }
      }
    ]
  })
}

# Policy for accessing S3 documents bucket
resource "aws_iam_role_policy" "bedrock_kb_s3_access" {
  name = "${var.project_name}-kb-s3-access"
  role = aws_iam_role.bedrock_knowledge_base.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.documents.arn,
          "${aws_s3_bucket.documents.arn}/*"
        ]
        Condition = {
          StringEquals = {
            "aws:PrincipalAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

# Policy for accessing S3 Vectors
resource "aws_iam_role_policy" "bedrock_kb_s3vectors_access" {
  name = "${var.project_name}-kb-s3vectors-access"
  role = aws_iam_role.bedrock_knowledge_base.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3vectors:CreateIndex",
          "s3vectors:DeleteIndex",
          "s3vectors:GetIndex",
          "s3vectors:ListIndexes",
          "s3vectors:PutVectors",
          "s3vectors:GetVectors",
          "s3vectors:DeleteVectors",
          "s3vectors:ListVectors",
          "s3vectors:QueryVectors"
        ]
        Resource = [
          aws_s3vectors_vector_bucket.knowledge_vectors.vector_bucket_arn,
          aws_s3vectors_index.knowledge_index.index_arn
        ]
      }
    ]
  })
}

# Policy for invoking Bedrock embedding model
resource "aws_iam_role_policy" "bedrock_kb_model_access" {
  name = "${var.project_name}-kb-model-access"
  role = aws_iam_role.bedrock_knowledge_base.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel"
        ]
        Resource = [
          "arn:${data.aws_partition.current.partition}:bedrock:${data.aws_region.current.name}::foundation-model/${var.embedding_model_id}"
        ]
      }
    ]
  })
}

# =============================================================================
# IAM Role for Bedrock Agent
# =============================================================================

resource "aws_iam_role" "bedrock_agent" {
  name = "${var.project_name}-agent-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "bedrock.amazonaws.com"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
          ArnLike = {
            "aws:SourceArn" = "arn:${data.aws_partition.current.partition}:bedrock:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:agent/*"
          }
        }
      }
    ]
  })
}

# Policy for agent to invoke foundation model (via Inference Profile)
resource "aws_iam_role_policy" "bedrock_agent_model_access" {
  name = "${var.project_name}-agent-model-access"
  role = aws_iam_role.bedrock_agent.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream"
        ]
        Resource = [
          # Cross-region inference profile (apac.*)
          "arn:${data.aws_partition.current.partition}:bedrock:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:inference-profile/${var.foundation_model_id}",
          # Foundation models accessed via inference profile
          "arn:${data.aws_partition.current.partition}:bedrock:*::foundation-model/anthropic.claude-*"
        ]
      }
    ]
  })
}

# Policy for agent to retrieve from knowledge base
resource "aws_iam_role_policy" "bedrock_agent_kb_access" {
  name = "${var.project_name}-agent-kb-access"
  role = aws_iam_role.bedrock_agent.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "bedrock:Retrieve"
        ]
        Resource = [
          aws_bedrockagent_knowledge_base.tortoise.arn
        ]
      }
    ]
  })
}
