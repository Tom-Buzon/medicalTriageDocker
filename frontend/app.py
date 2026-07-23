from __future__ import annotations

import os
import re
import time
import unicodedata

import streamlit as st
from openai import APIConnectionError, APITimeoutError, OpenAI


# ============================================================
# CONFIGURATION
# ============================================================

INFERENCE_BASE_URL = os.getenv(
    "INFERENCE_BASE_URL",
    "http://triage-api:8000/v1",
)

SERVED_MODEL_NAME = os.getenv(
    "SERVED_MODEL_NAME",
    "triage-model",
)

SYSTEM_PROMPT = (
    "You are a medical triage classification assistant. "
    "Your task is to classify the patient case as LOW, MEDIUM, or EMERGENCY. "
    "Use only the clinical information provided by the user. "
    "Do not diagnose. Do not recommend treatment. "
    "Return exactly this format:\n"
    "triage: <LOW|MEDIUM|EMERGENCY>\n"
    "justification: <one concise clinical reason>\n"
    "end_of_answer: true\n"
    "The triage value must be exactly one of: LOW, MEDIUM, EMERGENCY. "
    "Never use MEDIAN, MODERATE, HIGH, URGENT, or any other label. "
    "Stop after end_of_answer."
)

INSTRUCTION = (
    "Classify the medical triage urgency level as "
    "LOW, MEDIUM, or EMERGENCY."
)


# ============================================================
# HELPERS
# ============================================================

def build_prompt(clinical_case: str) -> str:
    return (
        "### System:\n"
        f"{SYSTEM_PROMPT}\n\n"
        "### User:\n"
        f"{INSTRUCTION}\n\n"
        f"Clinical case: {clinical_case.strip()}\n\n"
        "### Assistant:\n"
    )


def normalize_text(text: str) -> str:
    normalized = unicodedata.normalize("NFKC", str(text))
    normalized = normalized.replace("\r\n", "\n")
    return normalized.strip()


def clean_response(text: str) -> str:
    normalized = normalize_text(text)

    match = re.search(
        r"end_of_answer\s*:\s*true",
        normalized,
        flags=re.IGNORECASE,
    )

    if match:
        return normalized[: match.end()].strip()

    return normalized


def extract_triage(text: str) -> str:
    normalized = normalize_text(text)

    match = re.search(
        r"^\s*triage\s*:\s*(LOW|MEDIUM|EMERGENCY)\b",
        normalized,
        flags=re.IGNORECASE | re.MULTILINE,
    )

    if not match:
        return "UNKNOWN"

    return match.group(1).upper()


def extract_justification(text: str) -> str:
    normalized = normalize_text(text)

    match = re.search(
        r"justification\s*:\s*(.+?)"
        r"(?:\n\s*end_of_answer\s*:|$)",
        normalized,
        flags=re.IGNORECASE | re.DOTALL,
    )

    if not match:
        return ""

    return match.group(1).strip()


def check_api(client: OpenAI) -> bool:
    try:
        client.models.list()
        return True
    except Exception:
        return False


# ============================================================
# STREAMLIT UI
# ============================================================

st.set_page_config(
    page_title="Medical Triage Demo",
    page_icon="🩺",
    layout="centered",
)

st.title("Medical Triage Classification")

st.caption(
    "Demonstration model only. "
    "This application does not provide medical advice."
)

client = OpenAI(
    base_url=INFERENCE_BASE_URL,
    api_key="unused",
    timeout=300,
)

with st.sidebar:
    st.subheader("Service")

    if st.button("Check API status"):
        if check_api(client):
            st.success("vLLM API is available.")
        else:
            st.error("vLLM API is not available.")

    st.code(INFERENCE_BASE_URL)
    st.write(f"Model: `{SERVED_MODEL_NAME}`")

examples = {
    "Select an example": "",
    "Emergency — chest pain": (
        "A 58-year-old patient has sudden severe chest pain, "
        "difficulty breathing, dizziness, and heavy sweating."
    ),
    "Medium — vomiting": (
        "A 25-year-old patient has repeated vomiting and fever "
        "for 12 hours, drinks little, but remains alert."
    ),
    "Low — mild cold": (
        "A 28-year-old patient has a runny nose and mild cough, "
        "without fever or breathing difficulty."
    ),
}

selected_example = st.selectbox(
    "Example cases",
    options=list(examples),
)

default_case = examples[selected_example]

clinical_case = st.text_area(
    "Describe the clinical case",
    value=default_case,
    height=180,
    placeholder=(
        "Example: A patient has severe chest pain "
        "and difficulty breathing..."
    ),
)

analyse = st.button(
    "Classify the case",
    type="primary",
    use_container_width=True,
)

if analyse:
    if not clinical_case.strip():
        st.warning("Please enter a clinical case.")

    else:
        prompt = build_prompt(clinical_case)

        try:
            started_at = time.perf_counter()

            with st.spinner("The model is analysing the case..."):
                response = client.completions.create(
                    model=SERVED_MODEL_NAME,
                    prompt=prompt,
                    temperature=0.0,
                    max_tokens=90,
                    extra_body={
                        "repetition_penalty": 1.10,
                    },
                )

            elapsed = time.perf_counter() - started_at

            raw_answer = response.choices[0].text or ""
            answer = clean_response(raw_answer)

            triage = extract_triage(answer)
            justification = extract_justification(answer)

            if triage == "EMERGENCY":
                st.error("Triage: EMERGENCY")
            elif triage == "MEDIUM":
                st.warning("Triage: MEDIUM")
            elif triage == "LOW":
                st.success("Triage: LOW")
            else:
                st.error("The model returned an invalid triage label.")

            if justification:
                st.write("**Justification**")
                st.write(justification)

            usage = response.usage
            completion_tokens = (
                usage.completion_tokens
                if usage is not None
                else None
            )

            metric_columns = st.columns(2)

            metric_columns[0].metric(
                "Latency",
                f"{elapsed:.2f} s",
            )

            if completion_tokens:
                metric_columns[1].metric(
                    "Generation speed",
                    f"{completion_tokens / elapsed:.2f} tokens/s",
                )

            with st.expander("Raw model response"):
                st.code(raw_answer)

            with st.expander("Prompt sent to vLLM"):
                st.code(prompt)

        except APIConnectionError:
            st.error(
                "The Streamlit interface cannot connect to vLLM. "
                "The model may still be loading."
            )

        except APITimeoutError:
            st.error(
                "The inference request timed out. "
                "Try again after the model has finished loading."
            )

        except Exception as exc:
            st.exception(exc)