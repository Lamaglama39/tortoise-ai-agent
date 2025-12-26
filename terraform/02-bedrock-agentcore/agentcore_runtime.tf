# =============================================================================
# Amazon Bedrock AgentCore Runtime Resources
# =============================================================================
# This file creates AgentCore Runtime resources for deploying a Strands Agents
# container that connects to the existing Knowledge Base.
# =============================================================================

# -----------------------------------------------------------------------------
# ECR Repository for Agent Container
# -----------------------------------------------------------------------------

resource "aws_ecr_repository" "agentcore_runtime" {
  name                 = "${var.project_name}-agentcore-runtime"
  image_tag_mutability = "MUTABLE"
  force_delete = true

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name = "${var.project_name}-agentcore-runtime"
  }
}

resource "aws_ecr_lifecycle_policy" "agentcore_runtime" {
  repository = aws_ecr_repository.agentcore_runtime.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 5 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 5
        }
        action = {
          type = "expire"
        }
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

# AWS Managed Policy for BedrockAgentCore
# Note: AmazonBedrockAgentCoreExecutionRolePolicy may not be available in all regions yet
# Commenting out until the policy becomes generally available
# resource "aws_iam_role_policy_attachment" "agentcore_runtime_managed" {
#   role       = aws_iam_role.agentcore_runtime.name
#   policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonBedrockAgentCoreExecutionRolePolicy"
# }

# -----------------------------------------------------------------------------
# Wait for IAM Role propagation
# -----------------------------------------------------------------------------

resource "time_sleep" "wait_for_runtime_iam" {
  depends_on = [
    aws_iam_role.agentcore_runtime,
    aws_iam_role_policy.agentcore_runtime_bedrock,
    aws_iam_role_policy.agentcore_runtime_kb,
    aws_iam_role_policy.agentcore_runtime_ecr,
    aws_iam_role_policy.agentcore_runtime_logs,
    aws_iam_role_policy.agentcore_runtime_xray,
    aws_iam_role_policy.agentcore_runtime_metrics,
    aws_iam_role_policy.agentcore_runtime_workload
  ]

  create_duration = "15s"
}

# -----------------------------------------------------------------------------
# AgentCore Runtime
# -----------------------------------------------------------------------------
# NOTE: container_uri must point to an existing image in ECR.
# Run the following commands to build and push the image before terraform apply:
#
#   cd agentcore-runtime
#   docker build -t tortoise-agentcore-runtime .
#   aws ecr get-login-password --region ap-northeast-1 | docker login --username AWS --password-stdin <account_id>.dkr.ecr.ap-northeast-1.amazonaws.com
#   docker tag tortoise-agentcore-runtime:latest <account_id>.dkr.ecr.ap-northeast-1.amazonaws.com/<repo_name>:latest
#   docker push <account_id>.dkr.ecr.ap-northeast-1.amazonaws.com/<repo_name>:latest
# -----------------------------------------------------------------------------

resource "awscc_bedrockagentcore_runtime" "tortoise" {
  count = var.agentcore_runtime_image_tag != "" ? 1 : 0

  agent_runtime_name = "tortoise_kb_agent_${random_id.suffix.hex}"
  description        = "Tortoise expert agent using Strands Agents framework with Knowledge Base integration"
  role_arn           = aws_iam_role.agentcore_runtime.arn

  agent_runtime_artifact = {
    container_configuration = {
      container_uri = "${aws_ecr_repository.agentcore_runtime.repository_url}:${var.agentcore_runtime_image_tag}"
    }
  }

  network_configuration = {
    network_mode = "PUBLIC"
  }

  environment_variables = {
    "KNOWLEDGE_BASE_ID"  = aws_bedrockagent_knowledge_base.tortoise.id
    "AWS_REGION"         = var.aws_region
    "AWS_DEFAULT_REGION" = var.aws_region
    "MODEL_ID"           = var.foundation_model_id
  }

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  depends_on = [time_sleep.wait_for_runtime_iam]
}

# -----------------------------------------------------------------------------
# AgentCore Runtime Endpoint
# -----------------------------------------------------------------------------

resource "awscc_bedrockagentcore_runtime_endpoint" "tortoise" {
  count = var.agentcore_runtime_image_tag != "" ? 1 : 0

  name             = "tortoise_kb_endpoint_${random_id.suffix.hex}"
  description      = "Endpoint for tortoise expert agent"
  agent_runtime_id = awscc_bedrockagentcore_runtime.tortoise[0].agent_runtime_id

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
