# SAIA Model Configuration for openCode & oh-my-opencode

## Recommended Model Assignment

### opencode.json (Provider Configuration)

Add these models to your existing `saia` provider:

```json
{
  "provider": {
    "saia": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "SAIA AI",
      "options": {
        "baseURL": "https://chat-ai.academiccloud.de/v1",
        "apiKey": "YOUR_API_KEY_HERE"
      },
      "models": {
        "glm-4.7": {
          "name": "glm-4.7",
          "description": "General purpose, good for most tasks"
        },
        "qwen3-235b-a22b": {
          "name": "qwen3-235b-a22b",
          "description": "High-capacity reasoning (235B), use for oracle/complex logic"
        },
        "devstral-2-123b-instruct-2512": {
          "name": "devstral-2-123b-instruct-2512",
          "description": "Coding specialist (123B)"
        },
        "deepseek-r1-distill-llama-70b": {
          "name": "deepseek-r1-distill-llama-70b",
          "description": "Reasoning specialist (70B)"
        },
        "mistral-large-3-675b-instruct-2512": {
          "name": "mistral-large-3-675b-instruct-2512",
          "description": "Largest model (675B), complex tasks"
        },
        "qwen3-32b": {
          "name": "qwen3-32b",
          "description": "Balanced text model (32B)"
        },
        "qwen3-30b-a3b-instruct-2507": {
          "name": "qwen3-30b-a3b-instruct-2507",
          "description": "General text (30B)"
        },
        "gemma-3-27b-it": {
          "name": "gemma-3-27b-it",
          "description": "General purpose with image (27B)"
        },
        "llama-3.3-70b-instruct": {
          "name": "llama-3.3-70b-instruct",
          "description": "Strong text model (70B)"
        },
        "meta-llama-3.1-8b-instruct": {
          "name": "meta-llama-3.1-8b-instruct",
          "description": "Lightweight, fast (8B)"
        },
        "qwen3-vl-30b-a3b-instruct": {
          "name": "qwen3-vl-30b-a3b-instruct",
          "description": "Vision/Language (30B)"
        },
        "llama-3.1-sauerkrautlm-70b-instruct": {
          "name": "llama-3.1-sauerkrautlm-70b-instruct",
          "description": "Arcana/RAG support (70B)"
        }
      }
    }
  }
}
```

### oh-my-opencode.json (Agent Assignment)

```json
{
  "$schema": "https://raw.githubusercontent.com/code-yeongyu/oh-my-opencode/master/assets/oh-my-opencode.schema.json",
  "google_auth": false,
  "agents": {
    "sisyphus": {
      "model": "saia/qwen3-235b-a22b",
      "description": "Orchestration - needs strong reasoning"
    },
    "prometheus": {
      "model": "saia/qwen3-235b-a22b",
      "description": "Planning - needs deep thinking"
    },
    "atlas": {
      "model": "saia/llama-3.3-70b-instruct",
      "description": "Execution - fast and capable"
    },
    "metis": {
      "model": "saia/deepseek-r1-distill-llama-70b",
      "description": "Pre-planning analysis - reasoning specialist"
    },
    "momus": {
      "model": "saia/deepseek-r1-distill-llama-70b",
      "description": "Plan review - critical reasoning"
    },
    "librarian": {
      "model": "saia/qwen3-30b-a3b-instruct-2507",
      "description": "Documentation research - good for research"
    },
    "explore": {
      "model": "saia/qwen3-32b",
      "description": "Code searching - balanced performance"
    },
    "oracle": {
      "model": "saia/qwen3-235b-a22b",
      "description": "High-IQ consultant - maximum reasoning"
    },
    "frontend-ui-ux-engineer": {
      "model": "saia/gemma-3-27b-it",
      "description": "UI/UX - with image capabilities"
    },
    "multimodal-looker": {
      "model": "saia/qwen3-vl-30b-a3b-instruct",
      "description": "Image/PDF analysis - vision specialist"
    },
    "document-writer": {
      "model": "saia/llama-3.3-70b-instruct",
      "description": "Technical writing - strong text generation"
    },
    "quick": {
      "model": "saia/meta-llama-3.1-8b-instruct",
      "description": "Fast tasks - lightweight"
    },
    "build": {
      "model": "saia/devstral-2-123b-instruct-2512",
      "description": "Code execution - coding specialist"
    }
  }
}
```

## Rationale

### Agent → Model Mapping Strategy

| Agent | Model | Why |
|-------|-------|-----|
| **Sisyphus** (orchestrator) | `qwen3-235b-a22b` | Maximium reasoning for complex task delegation |
| **Prometheus** (planner) | `qwen3-235b-a22b` | Deep thinking needed for comprehensive planning |
| **Metis** (analysis) | `deepseek-r1-distill-llama-70b` | Reasoning specialist for ambiguity detection |
| **Momus** (reviewer) | `deepseek-r1-distill-llama-70b` | Critical reasoning for plan evaluation |
| **Oracle** (consultant) | `qwen3-235b-a22b` | High-IQ needs maximum capacity |
| **Atlas** (executor) | `llama-3.3-70b-instruct` | Fast, capable for implementation |
| **Librarian** (researcher) | `qwen3-30b-a3b-instruct-2507` | Good balance for doc/code searching |
| **Explore** (search) | `qwen3-32b` | Efficient for grep-style searches |
| **Frontend-UI-UX** | `gemma-3-27b-it` | Image capabilities for visual work |
| **Multimodal-looker** | `qwen3-vl-30b-a3b-instruct` | Vision specialist for images/PDFs |
| **Document-writer** | `llama-3.3-70b-instruct` | Strong text generation for docs |
| **Quick** | `meta-llama-3.1-8b-instruct` | Fastest model for simple tasks |
| **Build** | `devstral-2-123b-instruct-2512` | Coding specialist for code changes |

### Alternative Configurations

#### Performance-Optimized (faster, cheaper)
```json
{
  "sisyphus": "saia/llama-3.3-70b-instruct",
  "oracle": "saia/deepseek-r1-distill-llama-70b",
  "metis": "saia/llama-3.3-70b-instruct",
  "momus": "saia/deepseek-r1-distill-llama-70b",
  "prometheus": "saia/llama-3.3-70b-instruct",
  "atlas": "saia/qwen3-30b-a3b-instruct-2507",
  "quick": "saia/meta-llama-3.1-8b-instruct"
}
```

#### Quality-Optimized (best results, slower)
```json
{
  "sisyphus": "saia/mistral-large-3-675b-instruct-2512",
  "oracle": "saia/mistral-large-3-675b-instruct-2512",
  "metis": "saia/qwen3-235b-a22b",
  "momus": "saia/qwen3-235b-a22b",
  "prometheus": "saia/mistral-large-3-675b-instruct-2512",
  "atlas": "saia/qwen3-235b-a22b"
}
```

## Implementation Notes

1. **Replace API key**: Update the `apiKey` in `opencode.json` with your actual key
2. **Provider reference**: Use `saia/model-name` format in oh-my-opencode.json
3. **Testing**: Start with balanced config, adjust based on performance/quality needs
4. **Model availability**: Check `/v1/models` endpoint for current model list
5. **Rate limits**: Monitor headers for quota management (1000/min, 10000/hr, 50000/day)

## Migration Steps

1. Backup current configs:
   ```bash
   cp ~/.config/opencode/opencode.json ~/.config/opencode/opencode.json.backup
   cp ~/.config/opencode/oh-my-opencode.json ~/.config/opencode/oh-my-opencode.json.backup
   ```

2. Apply recommended configuration

3. Restart openCode:
   ```bash
   # Restart your openCode session
   ```

4. Verify with test prompts