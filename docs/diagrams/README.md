# Diagrams

Source-controlled Mermaid sources. PNG exports are deferred (same as screenshots)
— render them when preparing the portfolio:

```bash
# Mermaid CLI
npx -y @mermaid-js/mermaid-cli -i aws-infrastructure.mmd -o aws-infrastructure.png
npx -y @mermaid-js/mermaid-cli -i ci-cd-flow.mmd -o ci-cd-flow.png
npx -y @mermaid-js/mermaid-cli -i kubernetes-architecture.mmd -o kubernetes-architecture.png
```

Or paste into <https://mermaid.live> and export.

| Source | Renders | Referenced by |
|--------|---------|---------------|
| `aws-infrastructure.mmd` | `aws-infrastructure.png` | README, architecture.md |
| `ci-cd-flow.mmd` | `ci-cd-flow.png` | architecture.md |
| `kubernetes-architecture.mmd` | `kubernetes-architecture.png` | architecture.md |

The README and architecture.md also embed inline Mermaid that GitHub renders
natively, so the `.png` exports are only needed for slide decks / PDFs.
