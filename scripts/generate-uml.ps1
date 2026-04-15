$ErrorActionPreference = 'Stop'

Set-Location (Join-Path $PSScriptRoot '..')

$version = '11.6.0'

npx -y "@mermaid-js/mermaid-cli@$version" -i docs/uml/class-diagram.mmd -o docs/uml/class-diagram.svg -b transparent
npx -y "@mermaid-js/mermaid-cli@$version" -i docs/uml/sequence-publicar-drop.mmd -o docs/uml/sequence-publicar-drop.svg -b transparent
npx -y "@mermaid-js/mermaid-cli@$version" -i docs/uml/components.mmd -o docs/uml/components.svg -b transparent
npx -y "@mermaid-js/mermaid-cli@$version" -i docs/uml/deployment.mmd -o docs/uml/deployment.svg -b transparent

Write-Host "[OK] UML diagrams generated in docs/uml/*.svg"
