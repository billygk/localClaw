# Local Agentic Stack: OpenClaw + Ollama (NVIDIA GPU)

This repository provisions a locally hosted, fully private autonomous agent environment using OpenClaw, backed by Ollama for LLM inference. It is optimized for Windows hosts utilizing Docker Desktop with native WSL2 NVIDIA GPU passthrough.

## Architecture 

The stack relies on a declarative Docker Compose setup to ensure deterministic deployments and strict network boundaries:
1. **Ollama Container:** Acts exclusively as the API inference engine. It is granted direct access to the host's NVIDIA GPU.
2. **OpenClaw Container:** The autonomous agent environment. Built from a transparent Node.js image to avoid opaque third-party security risks. It communicates with Ollama over an internal Docker bridge network.

## Prerequisites

* Windows 10/11 with WSL2 enabled.
* Docker Desktop installed and configured to use the WSL2 backend.
* NVIDIA Display Drivers installed on the Windows host.
* At least 8GB of VRAM (12GB+ recommended for agentic workloads).

## Quick Start

1. **Deploy the Infrastructure:**
   Ensure your Docker engine is running, navigate to the project root, and execute:
   ```bash
   docker compose up -d --build
   ```

2. **Model Initialization:**
   The first run will automatically pull the `qwen3:8b` model. This may take several minutes depending on your internet connection.

2.1. Pull the Model: Once the containers are up, execute the pull command directly into the Ollama container. (I am using qwen3:8b as it fits comfortably in standard 8GB-12GB VRAM cards while handling agentic tasks well).

    ```bash
    docker exec -it ollama ollama pull qwen3:8b
    ```

2.2. Onboard OpenClaw: Because we skipped the interactive script, you need to generate a pairing token to access the Web UI:

    ```bash
    docker exec -it openclaw npx openclaw onboard
    ```

2.3 Usefull commands:

    ```bash
    docker exec -it openclaw npx openclaw onboard
    ```
   Execute this for a normal session
    ```bash
    docker exec -it openclaw bash
    ```


    Execute this on your host machine to inject a root session
    ```bash
    docker exec -u root -it openclaw bash
    ```

3. **Access the Interface:**
   Open your web browser and navigate to: `http://localhost:18789`

## Security & Privacy Model

This deployment is designed to operate as a **Closed-Loop System**:
* **No External Access:** The `ai_network` is isolated. The OpenClaw container cannot initiate outbound connections to the internet.
* **Data Locality:** All LLM inference occurs locally. No prompts, code snippets, or generated artifacts leave the host machine.
* **Transparency:** The Dockerfile is available for audit. You can inspect the exact base image and installation steps.

## Troubleshooting

* **GPU Issues:** If the Ollama container fails to start, verify that Docker Desktop is configured to use the WSL2 backend and that your NVIDIA drivers are up to date.
* **Connection Refused:** Ensure the `OLLAMA_HOST` environment variable in `docker-compose.yml` correctly points to the internal service name `ollama`.
