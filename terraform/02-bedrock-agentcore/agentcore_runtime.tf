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
