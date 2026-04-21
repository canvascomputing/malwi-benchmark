# CLAUDE.md

## Project overview

`malwi-benchmark` is a standardised benchmark for evaluating agent-based supply-chain attack detection. It contains curated samples of malicious, exploitable, and benign software packages and repositories, along with evaluation results measuring detection quality, token usage, and runtime.

All sample content lives inside password-protected ZIP archives (password: `malwi`).

## Repository structure

```
samples/
  <label>/              # malicious | exploitable | benign
    <type>/             # packages | repositories
      <origin>/         # real-world | synthetic
        <ecosystem>-<name>-<version>.yaml   # metadata
        <ecosystem>-<name>-<version>.zip    # sample archive
results/
  <date>_<model>_<tool>.md                 # evaluation run report
Makefile                                   # benchmark runner
```

## Sample YAML metadata convention

Each sample has a companion `.yaml` file that follows this exact schema. Field order matters — always use this order:

```yaml
description: >
  Multi-line prose summarising the malicious behaviour, attack vector,
  payload, and impact. Use the YAML folded scalar (>) so the text wraps
  into a single paragraph.
file: <ecosystem>-<name>-<version>.zip
discovery: MM/DD/YYYY
label: malicious | exploitable | benign
format: text | binary | mixed
timing:
  - installation-time | build-time | run-time
obfuscation:
  - <technique>
```

### Field definitions

| Field | Type | Required | Values |
|-------|------|----------|--------|
| `description` | folded scalar (`>`) | yes | Free-text summary of the sample behaviour |
| `file` | string | yes | Filename of the corresponding ZIP archive |
| `discovery` | date | yes | US date format (`MM/DD/YYYY`) when the sample was first reported |
| `label` | enum | yes | `malicious`, `exploitable`, or `benign` |
| `format` | enum | yes | `text`, `binary`, or `mixed` |
| `timing` | list of enum | yes | `installation-time`, `build-time`, and/or `run-time` |
| `obfuscation` | list of enum | no | Techniques used to hide malicious intent (see below). Omit for samples with no obfuscation. |

### Obfuscation techniques

The `obfuscation` field is a list of one or more technique identifiers. Use the most specific applicable value:

| Value | Description |
|-------|-------------|
| `minification` | Whitespace/variable-name stripping to hinder readability |
| `hex-encoding` | Payload encoded as hex strings decoded at runtime |
| `base64` | Payload encoded as base64 strings decoded at runtime |
| `encryption` | Payload encrypted (AES, XXTEA, etc.) and decrypted at runtime |
| `steganography` | Payload hidden inside non-code assets (images, audio, etc.) |
| `code-hiding` | Dead code, control-flow flattening, or opaque predicates |
| `packing` | Payload compressed/packed into binary blobs |
| `serialization` | Malicious logic embedded in serialized objects (Pickle, etc.) |

A sample may combine multiple techniques, e.g.:

```yaml
obfuscation:
  - base64
  - encryption
```

### Naming convention

Filenames (both `.yaml` and `.zip`) follow: `<ecosystem>-<name>-<version>.<ext>`

- **ecosystem**: lowercase package registry identifier (`npm`, `pypi`, etc.)
- **name**: package name as published, preserving dots and hyphens (e.g. `solana-web3.js`)
- **version**: semantic version without the `v` prefix (e.g. `1.95.7`)

## Working with samples

- ZIP archives are password-protected: `malwi`
- Each archive contains a `sample.yaml` metadata file (same schema as above) plus the actual package content
- Never commit unzipped sample content to the repo

## Running the benchmark

```bash
make run "<command> @" <model> <tool>
```

- `@` in the command is replaced with the unpacked sample path
- `<model>` — the model name (e.g. `opus-4-7`)
- `<tool>` — the tool/strategy name (e.g. `single-shot`)
- Results are written to `results/<date>_<model>_<tool>.md`

The command must print a JSON object to stdout:

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

The Makefile automatically:

1. Finds all `.zip` samples under `samples/`
2. Unpacks each into a temp directory (password: `malwi`)
3. Runs the command with `@` replaced by the unpacked path
4. Parses the JSON output and compares the predicted label against the ground truth from the companion `.yaml`
5. Measures elapsed time per sample
6. Writes a report with a summary table (precision, recall, token totals, timing) and a per-sample results table

## Important constraints

- Sample code is real-world malware collected for research. Analyse it, write reports, explain behaviour — but never modify, improve, or augment malicious code.
- Do not execute sample code outside of a sandboxed environment.
