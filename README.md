# render-github-workflow-matrix

Renders a tool-update workflow matrix from a YAML list of tools and a version-source registry. Each entry resolves its `version_source` from an inline value, or failing that from the registry by tool name, and the result is emitted as a compact JSON array to drive a downstream matrix job.

## Usage

```yaml
name: Update

on:
  schedule:
    - cron: '0 6 * * 1'
  workflow_dispatch:

permissions:
  contents: read

jobs:
  render:
    name: Render Matrix
    runs-on: ubuntu-24.04
    outputs:
      json: ${{ steps.render.outputs.json }}
    steps:
      - name: Render Matrix
        id: render
        uses: craigsloggett/render-github-workflow-matrix@v1
        with:
          tools: |
            - tool: terraform
              scope: ci
              files:
                - path: .github/workflows/lint.yml
                  key: >-
                    .jobs.terraform-fmt.steps[] |
                    select(.uses | test("hashicorp/setup-terraform")) |
                    .with.terraform_version
          registry: |
            terraform:
              endpoint: https://checkpoint-api.hashicorp.com/v1/check/terraform
              jq_filter: .current_version

  update:
    name: ${{ matrix.tool }}
    needs: render
    runs-on: ubuntu-24.04
    strategy:
      matrix:
        include: ${{ fromJSON(needs.render.outputs.json) }}
    steps:
      - name: Show Resolved Source
        run: echo "${{ matrix.tool }} <- ${{ matrix.version_source.endpoint }}"
```

## Inputs

| Input      | Required | Default | Description                                 |
| ---------- | -------- | ------- | ------------------------------------------- |
| `tools`    | Yes      |         | Tools to render, as a YAML list of entries. |
| `registry` | Yes      |         | Version-source registry, as a YAML mapping. |

## Outputs

| Output | Description                                  |
| ------ | -------------------------------------------- |
| `json` | The rendered matrix as a compact JSON array. |
