# Amazon Bedrock AgentCore Runtime container
# NOTE: AgentCore only supports ARM64 architecture
FROM public.ecr.aws/docker/library/python:3.11-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Create non-root user for security
RUN useradd -m -u 1000 bedrock_agentcore
USER bedrock_agentcore

# Expose ports for AgentCore Runtime
EXPOSE 8080
EXPOSE 8000

# Copy application code
COPY . .

# Health check endpoint
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/ping || exit 1

# Entry point with OpenTelemetry instrumentation
CMD ["opentelemetry-instrument", "python", "-m", "agent"]
