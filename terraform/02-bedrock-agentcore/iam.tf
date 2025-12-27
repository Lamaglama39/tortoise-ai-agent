# =============================================================================
# IAM Role for Bedrock Knowledge Base
# =============================================================================

resource "aws_iam_role" "bedrock_knowledge_base" {
  name = "${var.project_name}-agentcore-kb-role"

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

# -----------------------------------------------------------------------------
# IAM Role for AgentCore Runtime
# -----------------------------------------------------------------------------

resource "aws_iam_role" "agentcore_runtime" {
  name = "${var.project_name}-agentcore-runtime-role-${random_id.suffix.hex}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "bedrock-agentcore.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-agentcore-runtime-role"
  }
}

# Policy for invoking Bedrock models
resource "aws_iam_role_policy" "agentcore_runtime_bedrock" {
  name = "${var.project_name}-agentcore-runtime-bedrock-policy"
  role = aws_iam_role.agentcore_runtime.id

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
          "arn:${data.aws_partition.current.partition}:bedrock:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:inference-profile/${var.foundation_model_id}",
          "arn:${data.aws_partition.current.partition}:bedrock:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:inference-profile/apac.anthropic.claude-*",
          "arn:${data.aws_partition.current.partition}:bedrock:*::foundation-model/anthropic.claude-*"
        ]
      }
    ]
  })
}

# Policy for retrieving from Knowledge Base
resource "aws_iam_role_policy" "agentcore_runtime_kb" {
  name = "${var.project_name}-agentcore-runtime-kb-policy"
  role = aws_iam_role.agentcore_runtime.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "bedrock:Retrieve",
          "bedrock:RetrieveAndGenerate"
        ]
        Resource = [
          aws_bedrockagent_knowledge_base.tortoise.arn
        ]
      }
    ]
  })
}

# Policy for ECR access
resource "aws_iam_role_policy" "agentcore_runtime_ecr" {
  name = "${var.project_name}-agentcore-runtime-ecr-policy"
  role = aws_iam_role.agentcore_runtime.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchCheckLayerAvailability"
        ]
        Resource = [
          aws_ecr_repository.agentcore_runtime.arn
        ]
      }
    ]
  })
}

# Policy for CloudWatch Logs
resource "aws_iam_role_policy" "agentcore_runtime_logs" {
  name = "${var.project_name}-agentcore-runtime-logs-policy"
  role = aws_iam_role.agentcore_runtime.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
      }
    ]
  })
}

# Policy for X-Ray Tracing
resource "aws_iam_role_policy" "agentcore_runtime_xray" {
  name = "${var.project_name}-agentcore-runtime-xray-policy"
  role = aws_iam_role.agentcore_runtime.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords",
          "xray:GetSamplingRules",
          "xray:GetSamplingTargets"
        ]
        Resource = "*"
      }
    ]
  })
}

# Policy for CloudWatch Metrics
resource "aws_iam_role_policy" "agentcore_runtime_metrics" {
  name = "${var.project_name}-agentcore-runtime-metrics-policy"
  role = aws_iam_role.agentcore_runtime.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "cloudwatch:namespace" = "bedrock-agentcore"
          }
        }
      }
    ]
  })
}

# Policy for Workload Access Tokens
resource "aws_iam_role_policy" "agentcore_runtime_workload" {
  name = "${var.project_name}-agentcore-runtime-workload-policy"
  role = aws_iam_role.agentcore_runtime.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "bedrock-agentcore:GetWorkloadAccessToken"
        ]
        Resource = "*"
      }
    ]
  })
}
