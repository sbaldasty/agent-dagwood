import argparse
import json
import os
import subprocess
import sys
import time
from pathlib import Path
from typing import Any

from litellm import completion


TOOL_SPECS = [
    {
        "type": "function",
        "function": {
            "name": "add_numbers",
            "description": "Add two numbers and return the sum.",
            "parameters": {
                "type": "object",
                "properties": {
                    "a": {"type": "number", "description": "First number"},
                    "b": {"type": "number", "description": "Second number"},
                },
                "required": ["a", "b"],
            },
        },
    }
]


def _request_overrides(model: str) -> dict[str, Any]:
    overrides: dict[str, Any] = {}
    if model.startswith("ollama/"):
        overrides["api_base"] = os.getenv("OLLAMA_BASE_URL", "http://localhost:11434")
    if os.getenv("LITELLM_API_KEY"):
        overrides["api_key"] = os.environ["LITELLM_API_KEY"]
    return overrides


def _parse_models(model_arg: str | None) -> list[str]:
    source = model_arg or os.getenv("MODEL", "ollama/qwen2.5:7b-instruct")
    return [m.strip() for m in source.split(",") if m.strip()]


def _tool_script_path(name: str) -> Path:
    return Path(__file__).resolve().parent / "scripts" / f"{name}.py"


def _run_tool_script(name: str, arguments: dict[str, Any]) -> dict[str, Any]:
    script_path = _tool_script_path(name)
    if not script_path.exists():
        return {"error": f"Tool script not found: {script_path}"}

    completed = subprocess.run(
        [sys.executable, str(script_path)],
        input=json.dumps(arguments),
        capture_output=True,
        text=True,
        check=False)

    if completed.returncode != 0:
        stderr = completed.stderr.strip() or "tool script failed"
        return {"error": stderr}

    return json.loads(completed.stdout)


def _run_tool(name: str, arguments: dict[str, Any]) -> dict[str, Any]:
    if name == "add_numbers":
        return _run_tool_script(name, arguments)
    return {"error": f"Unknown tool: {name}"}


def _coerce_dict(payload: Any) -> dict[str, Any]:
    if hasattr(payload, "model_dump"):
        return payload.model_dump()
    if isinstance(payload, dict):
        return payload
    return dict(payload)


def _call_model(
    *,
    model: str,
    messages: list[dict[str, Any]],
    temperature: float,
    max_tokens: int,
    tools: list[dict[str, Any]] | None = None,
) -> Any:
    kwargs: dict[str, Any] = {
        "model": model,
        "messages": messages,
        "temperature": temperature,
        "max_tokens": max_tokens,
        **_request_overrides(model),
    }
    if tools is not None:
        kwargs["tools"] = tools
        kwargs["tool_choice"] = "auto"
    return completion(**kwargs)


def run_once(
    *,
    model: str,
    prompt: str,
    temperature: float,
    max_tokens: int,
    tool_demo: bool,
) -> dict[str, Any]:
    system = (
        "You are a concise assistant. "
        "If tools are available, call them only when needed."
    )
    messages: list[dict[str, Any]] = [
        {"role": "system", "content": system},
        {"role": "user", "content": prompt},
    ]

    start = time.perf_counter()
    response = _call_model(
        model=model,
        messages=messages,
        temperature=temperature,
        max_tokens=max_tokens,
        tools=TOOL_SPECS if tool_demo else None,
    )

    steps = 1
    while tool_demo:
        message = _coerce_dict(response.choices[0].message)
        tool_calls = message.get("tool_calls") or []
        print(f"Attemping tool calls: {message}")
        if not tool_calls:
            break
        if steps > 6:
            break

        messages.append(message)
        for call in tool_calls:
            fn = call["function"]
            name = fn["name"]
            arguments = json.loads(fn.get("arguments") or "{}")
            result = _run_tool(name, arguments)
            messages.append(
                {
                    "role": "tool",
                    "tool_call_id": call["id"],
                    "name": name,
                    "content": json.dumps(result),
                }
            )

        response = _call_model(
            model=model,
            messages=messages,
            temperature=temperature,
            max_tokens=max_tokens,
            tools=TOOL_SPECS,
        )
        steps += 1

    elapsed = time.perf_counter() - start
    final_msg = _coerce_dict(response.choices[0].message)
    usage = _coerce_dict(response.usage) if getattr(response, "usage", None) else {}

    return {
        "model": model,
        "steps": steps,
        "elapsed_s": round(elapsed, 3),
        "prompt_tokens": usage.get("prompt_tokens"),
        "completion_tokens": usage.get("completion_tokens"),
        "content": final_msg.get("content", ""),
    }


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="LiteLLM local-first loop with easy provider swapping"
    )
    parser.add_argument(
        "--prompt",
        default="Explain backdoor adjustment in DAGs in 4 bullet points.",
        help="Prompt sent to each model.",
    )
    parser.add_argument(
        "--models",
        default=None,
        help=(
            "Comma-separated LiteLLM model names. "
            "Examples: ollama/qwen2.5:7b-instruct,openai/gpt-4o-mini"))
    parser.add_argument("--temperature", type=float, default=0.2)
    parser.add_argument("--max-tokens", type=int, default=300)
    parser.add_argument(
        "--tool-demo",
        action="store_true",
        help="Enable one simple function-calling loop (add_numbers).")
    return parser


if __name__ == "__main__":
    args = build_parser().parse_args()
    models = _parse_models(args.models)

    for model in models:
        print(f"\n=== {model} ===")
        result = run_once(
            model=model,
            prompt=args.prompt,
            temperature=args.temperature,
            max_tokens=args.max_tokens,
            tool_demo=args.tool_demo)
        print(
            "elapsed_s={elapsed_s} steps={steps} prompt_tokens={prompt_tokens} "
            "completion_tokens={completion_tokens}".format(**result))
        print(result["content"])
