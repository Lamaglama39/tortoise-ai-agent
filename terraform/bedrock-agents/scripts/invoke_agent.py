#!/usr/bin/env python3
"""
Bedrock Agent Invocation Script

This script provides functionality to invoke an Amazon Bedrock Agent
and handle streaming responses.
"""

import io
import os
import sys
import uuid
import argparse

import boto3

from dotenv import load_dotenv

# 標準入出力のエンコーディングをUTF-8に設定
sys.stdin = io.TextIOWrapper(sys.stdin.buffer, encoding="utf-8", errors="replace")
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")


def load_config() -> dict:
    """
    Load configuration from environment variables.

    Returns:
        dict: Configuration dictionary with AWS and Bedrock settings.

    Raises:
        ValueError: If required environment variables are missing.
    """
    load_dotenv()

    required_vars = ["AGENT_ID", "AGENT_ALIAS_ID"]
    missing_vars = [var for var in required_vars if not os.getenv(var)]

    if missing_vars:
        raise ValueError(f"Missing required environment variables: {', '.join(missing_vars)}")

    return {
        "region": os.getenv("AWS_REGION", "ap-northeast-1"),
        "agent_id": os.getenv("AGENT_ID"),
        "agent_alias_id": os.getenv("AGENT_ALIAS_ID"),
    }


def create_bedrock_agent_runtime_client(region: str):
    """
    Create a Bedrock Agent Runtime client.

    Args:
        region: AWS region name.

    Returns:
        boto3 client for Bedrock Agent Runtime.
    """
    return boto3.client("bedrock-agent-runtime", region_name=region)


def invoke_agent(
    client,
    agent_id: str,
    agent_alias_id: str,
    input_text: str,
    session_id: str | None = None,
    enable_trace: bool = False,
) -> tuple[str, str]:
    """
    Invoke a Bedrock Agent with the given input text.

    Args:
        client: Bedrock Agent Runtime client.
        agent_id: The ID of the Bedrock Agent.
        agent_alias_id: The alias ID of the Bedrock Agent.
        input_text: The user's input text.
        session_id: Optional session ID for conversation continuity.
        enable_trace: Whether to enable trace output for debugging.

    Returns:
        tuple: (response_text, session_id) - The agent's response and session ID.
    """
    if session_id is None:
        session_id = str(uuid.uuid4())

    response = client.invoke_agent(
        agentId=agent_id,
        agentAliasId=agent_alias_id,
        sessionId=session_id,
        inputText=input_text,
        enableTrace=enable_trace,
    )

    completion_text = ""
    event_stream = response.get("completion", [])

    for event in event_stream:
        if "chunk" in event:
            chunk_data = event["chunk"]
            if "bytes" in chunk_data:
                text = chunk_data["bytes"].decode("utf-8")
                completion_text += text
                print(text, end="", flush=True)

        if enable_trace and "trace" in event:
            trace_data = event["trace"]
            print(f"\n[TRACE] {trace_data}", file=sys.stderr)

    print()  # Add newline after streaming output

    return completion_text, session_id


def interactive_mode(client, agent_id: str, agent_alias_id: str, enable_trace: bool = False):
    """
    Run the agent in interactive conversation mode.

    Args:
        client: Bedrock Agent Runtime client.
        agent_id: The ID of the Bedrock Agent.
        agent_alias_id: The alias ID of the Bedrock Agent.
        enable_trace: Whether to enable trace output for debugging.
    """
    session_id = str(uuid.uuid4())
    print("=" * 60)
    print("Tortoise Expert Agent - Interactive Mode")
    print("=" * 60)
    print(f"Session ID: {session_id}")
    print("Type 'quit' or 'exit' to end the conversation.")
    print("Type 'new' to start a new session.")
    print("=" * 60)
    print()

    while True:
        try:
            user_input = input("You: ").strip()
        except (EOFError, KeyboardInterrupt):
            print("\nGoodbye!")
            break

        if not user_input:
            continue

        if user_input.lower() in ["quit", "exit"]:
            print("Goodbye!")
            break

        if user_input.lower() == "new":
            session_id = str(uuid.uuid4())
            print(f"\nNew session started: {session_id}\n")
            continue

        print("\nAgent: ", end="")
        _, session_id = invoke_agent(
            client=client,
            agent_id=agent_id,
            agent_alias_id=agent_alias_id,
            input_text=user_input,
            session_id=session_id,
            enable_trace=enable_trace,
        )
        print()


def main():
    """Main entry point for the script."""
    parser = argparse.ArgumentParser(
        description="Invoke Amazon Bedrock Agent for tortoise expertise",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Single query mode
  python invoke_agent.py "What do tortoises eat?"

  # Interactive mode
  python invoke_agent.py --interactive

  # With debug tracing
  python invoke_agent.py --trace "How to set up a tortoise enclosure?"
        """,
    )
    parser.add_argument(
        "query",
        nargs="?",
        help="The question to ask the agent (omit for interactive mode)",
    )
    parser.add_argument(
        "-i",
        "--interactive",
        action="store_true",
        help="Run in interactive conversation mode",
    )
    parser.add_argument(
        "-t",
        "--trace",
        action="store_true",
        help="Enable trace output for debugging",
    )
    parser.add_argument(
        "-s",
        "--session",
        type=str,
        default=None,
        help="Session ID for conversation continuity",
    )

    args = parser.parse_args()

    try:
        config = load_config()
    except ValueError as e:
        print(f"Configuration error: {e}", file=sys.stderr)
        print("Please ensure .env file exists with required variables.", file=sys.stderr)
        sys.exit(1)

    client = create_bedrock_agent_runtime_client(config["region"])

    if args.interactive or args.query is None:
        interactive_mode(
            client=client,
            agent_id=config["agent_id"],
            agent_alias_id=config["agent_alias_id"],
            enable_trace=args.trace,
        )
    else:
        print("Agent: ", end="")
        invoke_agent(
            client=client,
            agent_id=config["agent_id"],
            agent_alias_id=config["agent_alias_id"],
            input_text=args.query,
            session_id=args.session,
            enable_trace=args.trace,
        )


if __name__ == "__main__":
    main()
