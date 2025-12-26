"""
Tortoise Expert Agent using Strands Agents Framework with BedrockAgentCoreApp.

This agent uses Amazon Bedrock Knowledge Base to answer questions about tortoises.
It retrieves relevant information from the knowledge base and generates responses
with proper citations.
"""

import json
import os
from typing import Optional

import boto3
from strands import Agent, tool
from bedrock_agentcore.runtime import BedrockAgentCoreApp


# Environment variables
KNOWLEDGE_BASE_ID = os.environ.get("KNOWLEDGE_BASE_ID", "")
AWS_REGION = os.environ.get("AWS_REGION", "ap-northeast-1")
MODEL_ID = os.environ.get("MODEL_ID", "apac.anthropic.claude-3-5-sonnet-20241022-v2:0")

# Initialize BedrockAgentCoreApp
app = BedrockAgentCoreApp()

# Bedrock Agent Runtime client
bedrock_agent_runtime = boto3.client(
    "bedrock-agent-runtime",
    region_name=AWS_REGION
)


@tool
def kb_search(query: str, max_results: Optional[int] = 5) -> str:
    """
    Search the tortoise knowledge base for relevant information.

    Args:
        query: The search query about tortoises
        max_results: Maximum number of results to return (default: 5)

    Returns:
        JSON string containing search results with content, source URIs, and metadata
    """
    if not KNOWLEDGE_BASE_ID:
        return json.dumps({"error": "KNOWLEDGE_BASE_ID environment variable is not set"})

    try:
        response = bedrock_agent_runtime.retrieve(
            knowledgeBaseId=KNOWLEDGE_BASE_ID,
            retrievalQuery={"text": query},
            retrievalConfiguration={
                "vectorSearchConfiguration": {
                    "numberOfResults": max_results,
                    "overrideSearchType": "SEMANTIC",
                }
            },
        )

        results = []
        for i, result in enumerate(response.get("retrievalResults", []), 1):
            content = result.get("content", {}).get("text", "")
            location = result.get("location", {})
            score = result.get("score", 0)

            # Extract S3 URI if available
            s3_location = location.get("s3Location", {})
            s3_uri = s3_location.get("uri", "Unknown")

            # Extract metadata
            metadata = result.get("metadata", {})

            results.append({
                "rank": i,
                "content": content,
                "source_uri": s3_uri,
                "score": score,
                "metadata": metadata,
            })

        return json.dumps(results, ensure_ascii=False, indent=2)

    except Exception as e:
        return json.dumps({"error": str(e)})


# System prompt for the tortoise expert agent
SYSTEM_PROMPT = """You are an expert AI assistant specialized in tortoises (land-dwelling turtles).
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

**Important Instructions**:
- Use the kb_search tool to find relevant information from the knowledge base before answering
- Always cite your sources using the format: [Source: filename]
- Respond in a friendly and educational manner
- Provide specific, actionable advice
- Include safety warnings when relevant
- Recommend professional veterinary consultation for health concerns
- Support both English and Japanese responses based on user's language

When citing sources, use the following format at the end of your response:

---
**References**:
[1] filename - s3://bucket/path/file
"""


def create_agent() -> Agent:
    """Create and configure the tortoise expert agent."""
    agent = Agent(
        system_prompt=SYSTEM_PROMPT,
        tools=[kb_search],
    )
    return agent


@app.entrypoint
async def invoke(payload: dict) -> dict:
    """
    Main entrypoint for AgentCore Runtime.

    Args:
        payload: Request payload containing the user's question

    Returns:
        Response dictionary with the agent's answer
    """
    # Extract user message from payload
    user_message = payload.get("prompt", payload.get("message", ""))

    if not user_message:
        return {
            "status": "error",
            "error": "No prompt or message provided"
        }

    try:
        agent = create_agent()

        # Generate response
        response = agent(user_message)
        response_text = str(response)

        return {
            "status": "success",
            "response": response_text,
            "knowledge_base_id": KNOWLEDGE_BASE_ID,
        }

    except Exception as e:
        return {
            "status": "error",
            "error": str(e)
        }


# Entry point for AgentCore Runtime
if __name__ == "__main__":
    app.run()
