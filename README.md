# render-github-workflow-matrix

Renders a GitHub Actions workflow matrix.

## Usage

```yaml
name: Render Matrix

on: pull_request

permissions:
  contents: read

jobs:
  render:
    name: Render Matrix
    runs-on: ubuntu-24.04
    steps:
      - name: Checkout
        uses: actions/checkout@v6

      - name: Render Matrix
        uses: craigsloggett/render-github-workflow-matrix@v1
```

## Inputs

| Input      | Required | Default                    | Description        |
| ---------- | -------- | -------------------------- | ------------------ |
| `my-input` | No       | `The default description.` | Placeholder input. |

## Outputs

| Output      | Description         |
| ----------- | ------------------- |
| `my-output` | Placeholder output. |
