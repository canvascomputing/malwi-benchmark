<p align="center">
  <img src="logo.png" width="200" />
</p>

<h1 align="center">👹 malwi benchmark</h1>

<p align="center">
  <strong>A benchmark for evaluating agentic detection of supply-chain attacks</strong>
</p>

<p align="center">
  <em>Measurable, reproducible evaluation is the foundation of trustworthy security tooling. This benchmark focuses on one of the largest attack surfaces in modern software.</em>
</p>

## Overview

`malwi-benchmark` is a standardised test suite for agent-based supply-chain attack detection. It covers multiple ecosystems, artefact types, and difficulty levels, and reports precision, recall, runtime, and cost across agent architectures and models.

## Metrics

The benchmark compares agent architectures and models along three dimensions.

- **Cost**: average spend in USD per sample.
- **Time**: average runtime per sample.
- **Detection quality**: precision and recall per label.

## Characteristics

Each sample is described by the following axes:

| Axis | Value | Description |
| --- | --- | --- |
| **Labels** | Malicious | intentionally harmful code (e.g. credential theft, remote execution) |
| | Exploitable | abusable behaviour without overt intent (e.g. side-loading, exfiltration) |
| | Benign | legitimate code |
| **Sample type** | Package | self-contained artefact following a clear packaging convention (npm, PyPI, tarball) |
| | Repository | free-form source that may mix languages and ecosystems (GitHub, GitLab) |
| **Data origin** | Real-world | samples collected from actual attacks |
| | Synthetic | samples constructed for the benchmark |
| **Format** | Text | source code, manifests, scripts |
| | Binary | compiled blobs, archives, media |
| | Mixed | combination of text and binary content |

## Folder Structure

```
malwi-benchmark/
├── samples/
│   ├── malicious/
│   │   ├── packages/
│   │   │   ├── npm/
│   │   │   │   ├── real-world/
│   │   │   │   └── synthetic/
│   │   │   └── pypi/
│   │   └── repositories/
│   │       ├── github/
│   │       └── gitlab/
│   ├── exploitable/
│   │   └── …
│   └── benign/
│       └── …
├── results/
│   └── 2026-04-18_opus-4-7_single-shot/
└── README.md
```
