<p align="center">
  <img src="logo.png" width="200" />
</p>

<h1 align="center">👹 malwi benchmark</h1>

<p align="center">
  <strong>A benchmark for evaluating agentic detection of supply-chain attacks.</strong>
</p>

<p align="center">
  <em>Measurable, reproducible evaluation is the foundation of trustworthy security tooling. This benchmark focuses on one of the largest attack surfaces in modern software.</em>
</p>

## Overview

`malwi-benchmark` is a standardised test suite for agent-based supply-chain attack detection. It covers multiple ecosystems, artefact types, and difficulty levels, and reports precision, recall, runtime, and token usage across agent architectures and models.

### Metrics

The benchmark compares agent architectures and models along three dimensions.

- **Tokens**: average input and output tokens per sample.
- **Time**: average elapsed runtime per sample.
- **Detection quality**: precision and recall per label.

### Characteristics

Each sample is described by the following axes:

| Axis | Value | Description |
| --- | --- | --- |
| **Type** | Package | self-contained artefact following a clear packaging convention (npm, PyPI, tarball) |
| | Repository | free-form source that may mix languages and ecosystems (GitHub, GitLab) |
| **Origin** | Real-world | samples collected from actual attacks |
| | Synthetic | samples constructed for the benchmark |
| **Label** | Malicious | intentionally harmful code (e.g. credential theft, remote execution) |
| | Exploitable | abusable behaviour without overt intent (e.g. side-loading, exfiltration) |
| | Benign | legitimate code |
| **Format** | Text | source code, manifests, scripts |
| | Binary | compiled blobs, archives, media |
| | Mixed | combination of text and binary content |
| **Timing** | Installation-time | malicious behaviour triggered during package installation |
| | Build-time | malicious behaviour triggered during source parsing or compilation |
| | Run-time | malicious behaviour triggered when package code executes |
| **Obfuscation** | Minification | whitespace/variable-name stripping to hinder readability |
| | Hex-encoding | payload encoded as hex strings decoded at runtime |
| | Base64 | payload encoded as base64 strings decoded at runtime |
| | Encryption | payload encrypted (AES, XXTEA, etc.) and decrypted at runtime |
| | Steganography | payload hidden inside non-code assets (images, audio, etc.) |
| | Code-hiding | dead code, control-flow flattening, or opaque predicates |
| | Packing | payload compressed/packed into binary blobs |
| | Serialization | malicious logic embedded in serialized objects (Pickle, etc.) |

### Structure

```
malwi-benchmark/
├── samples/
│   ├── malicious/
│   │   ├── packages/
│   │   │   ├── real-world/
│   │   │   │   ├── npm-<name>-<version>.yaml
│   │   │   │   ├── npm-<name>-<version>.zip
│   │   │   │   ├── pypi-<name>-<version>.yaml
│   │   │   │   └── pypi-<name>-<version>.zip
│   │   │   └── synthetic/
│   │   └── repositories/
│   │       ├── real-world/
│   │       └── synthetic/
│   ├── exploitable/
│   │   └── …
│   └── benign/
│       └── …
├── results/
│   └── <date>_<model>_<tool>.md
├── Makefile
└── README.md
```

Archives are password-protected ZIPs (password: `malwi`), named `<ecosystem>-<package>-<version>.zip`. Each contains the package content and a `<ecosystem>-<package>-<version>.yaml` following the metadata format above.

## Usage

> **Warning:** Samples contain real-world malware. You are responsible for running the benchmark in a properly isolated environment (e.g. a container or VM with no network access). The authors assume no liability for damage caused by misuse of the samples.

Run your agentic system against every sample in the benchmark:

```bash
make run "<command> @" <model> <tool>
```

| Argument | Description |
|----------|-------------|
| `<command> @` | The shell command to evaluate. `@` is replaced with the path to each unpacked sample. |
| `<model>` | Name of the model being evaluated (e.g. `opus-4-7`). |
| `<tool>` | Name of the tool or strategy (e.g. `single-shot`). |

Examples:

```bash
# Dry run — always predicts "benign" with zero tokens
make run "examples/testtool @" none dummy

# Real tool
make run "my-scanner analyse @" claude-sonnet-4-20250514 my-scanner
```

The Makefile will:

1. Find all `.zip` samples under `samples/`.
2. Unpack each into a temporary directory (password: `malwi`).
3. Run the command with `@` replaced by the unpacked sample path.
4. Parse the JSON output and compare the predicted label against the ground-truth label from the companion `.yaml`.
5. Measure elapsed time per sample.
6. Write a report to `results/<date>_<model>_<tool>.md` containing a summary table (precision, recall, token totals, average time) and a per-sample results table.

### Tool output contract

The command under evaluation must print a single JSON object to stdout:

```json
{
  "label": "malicious",
  "input_tokens": 12500,
  "output_tokens": 830
}
```

| Field | Type | Description |
|-------|------|-------------|
| `label` | string | Predicted label: `malicious`, `exploitable`, or `benign` |
| `input_tokens` | integer | Total input/prompt tokens consumed |
| `output_tokens` | integer | Total output/completion tokens consumed |