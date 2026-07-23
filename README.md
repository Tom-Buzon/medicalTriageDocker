---
title: Medical Triage vLLM Demo
emoji: 🩺
colorFrom: blue
colorTo: indigo
sdk: docker
app_port: 7860
fullWidth: true
models:
  - qneaup/qwen3-1.7b-medical-triage-sft-dpo
short_description: Medical triage classification demo served with vLLM.
---

# Medical Triage vLLM Demo

This Space demonstrates a Qwen3-1.7B model fine-tuned with SFT and DPO
for medical triage classification.

## Architecture

- vLLM CPU inference server
- OpenAI-compatible API
- Streamlit demonstration interface
- Nginx reverse proxy

## Endpoints

- UI: `/`
- Models: `/v1/models`
- Completions: `/v1/completions`

## Disclaimer

This project is a technical demonstration and does not provide medical
advice, diagnosis, or treatment recommendations.