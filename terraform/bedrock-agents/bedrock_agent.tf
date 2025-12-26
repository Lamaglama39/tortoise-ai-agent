# Bedrock Agent - Tortoise Expert
resource "aws_bedrockagent_agent" "tortoise_expert" {
  agent_name              = "tortoise-expert-agent"
  agent_resource_role_arn = aws_iam_role.bedrock_agent.arn
  foundation_model        = var.foundation_model_id

  description = "An AI expert specialized in tortoise care, species identification, and health management."

  # Session timeout: 30 minutes
  idle_session_ttl_in_seconds = 1800

  # Agent instruction - defines the agent's behavior and expertise
  instruction = <<-EOT
    You are an expert AI assistant specialized in tortoises (land-dwelling turtles).
    Your knowledge covers:

    1. **Species Identification**: You can identify various tortoise species including
       Hermann's tortoise, Russian tortoise, Sulcata tortoise, Red-footed tortoise,
       Leopard tortoise, and more.

    2. **Care Guidelines**: You provide detailed guidance on:
       - Proper enclosure setup (indoor and outdoor)
       - Temperature and humidity requirements
       - Lighting needs (UVB and basking)
       - Substrate choices

    3. **Nutrition**: You advise on:
       - Appropriate diet for different species
       - Safe plants and vegetables
       - Calcium and vitamin supplementation
       - Foods to avoid

    4. **Health Management**: You can discuss:
       - Common health issues and symptoms
       - When to seek veterinary care
       - Preventive care measures
       - Hibernation/brumation guidance

    **Communication Style**:
    - Always respond in a friendly and educational manner
    - Provide specific, actionable advice
    - Include safety warnings when relevant
    - Recommend professional veterinary consultation for health concerns
    - Support both English and Japanese responses based on user's language

    Use the knowledge base to provide accurate and up-to-date information about tortoise care.
  EOT

  depends_on = [
    aws_iam_role_policy.bedrock_agent_model_access
  ]
}

# Associate Knowledge Base with Agent
resource "aws_bedrockagent_agent_knowledge_base_association" "tortoise" {
  agent_id             = aws_bedrockagent_agent.tortoise_expert.agent_id
  knowledge_base_id    = aws_bedrockagent_knowledge_base.tortoise.id
  knowledge_base_state = "ENABLED"

  description = "Knowledge base containing tortoise care information for the expert agent."
}

resource "null_resource" "prepare_agent" {
  triggers = {
    agent_id       = aws_bedrockagent_agent.tortoise_expert.agent_id
    kb_association = aws_bedrockagent_agent_knowledge_base_association.tortoise.id
  }

  provisioner "local-exec" {
    command = "aws bedrock-agent prepare-agent --agent-id ${aws_bedrockagent_agent.tortoise_expert.agent_id} --region ${var.aws_region}"
  }

  depends_on = [
    aws_bedrockagent_agent_knowledge_base_association.tortoise,
    aws_iam_role_policy.bedrock_agent_kb_access
  ]
}
