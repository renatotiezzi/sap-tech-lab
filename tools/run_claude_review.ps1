param(
    [string]$RepoPath = ".",
    [string]$Model = "claude-4.7",
    [string]$ApiKey = $env:ANTHROPIC_API_KEY,
    [string]$PromptFile = "tools/claude_review_prompt.txt",
    [string]$OutputFile = "tools/claude_review_output.md",
    [string]$ReportFile = "tools/claude_corrections_report.md",
    [switch]$AutoApply,
    [int]$MaxFileChars = 12000,
    [int]$MaxFiles = 25
)

$ErrorActionPreference = "Stop"

function Fail($msg) {
    Write-Error $msg
    exit 1
}

if ([string]::IsNullOrWhiteSpace($ApiKey)) {
    Fail "ANTHROPIC_API_KEY nao informado. Defina a variavel de ambiente ou passe -ApiKey."
}

if (-not (Test-Path $RepoPath)) {
    Fail "RepoPath nao encontrado: $RepoPath"
}

Push-Location $RepoPath
try {
    $gitCheck = git rev-parse --is-inside-work-tree 2>$null
    if ($LASTEXITCODE -ne 0) {
        Fail "A pasta nao e um repositorio git: $RepoPath"
    }

    if (-not (Test-Path $PromptFile)) {
        Fail "Prompt file nao encontrado: $PromptFile"
    }

    $basePrompt = Get-Content -Path $PromptFile -Raw

    $candidateFiles = @(
        git ls-files "CR51/**" "CR51_APP/**" "CR51_SVR/**"
    ) | Where-Object {
        $_ -match "\.(txt|md|abap|ddlx)$"
    } | Select-Object -First $MaxFiles

    if (-not $candidateFiles -or $candidateFiles.Count -eq 0) {
        Fail "Nenhum arquivo alvo encontrado em CR51/CR51_APP/CR51_SVR."
    }

    $fileBlocks = New-Object System.Collections.Generic.List[string]

    foreach ($relPath in $candidateFiles) {
        if (-not (Test-Path $relPath)) { continue }

        $raw = Get-Content -Path $relPath -Raw
        if ($raw.Length -gt $MaxFileChars) {
            $raw = $raw.Substring(0, $MaxFileChars)
        }

        $fileBlocks.Add("### FILE: $relPath`n$raw")
    }

    $changed = git status --short

    $finalPrompt = @"
$basePrompt

## Repository Context
- Path: $((Resolve-Path .).Path)
- Branch: $(git rev-parse --abbrev-ref HEAD)

## Current git status
$changed

## Files for review
$($fileBlocks -join "`n`n")

## Expected output format
1) Findings (critical/high/medium) with file path and why.
2) Minimal correction plan.
3) A single unified diff patch block.
"@

    $body = @{
        model = $Model
        max_tokens = 4000
        temperature = 0
        messages = @(
            @{
                role = "user"
                content = $finalPrompt
            }
        )
    }

    $headers = @{
        "x-api-key" = $ApiKey
        "anthropic-version" = "2023-06-01"
        "content-type" = "application/json"
    }

    Write-Host "Chamando Claude model: $Model"

    $response = Invoke-RestMethod -Uri "https://api.anthropic.com/v1/messages" -Method Post -Headers $headers -Body ($body | ConvertTo-Json -Depth 10)

    if (-not $response.content -or $response.content.Count -eq 0) {
        Fail "Resposta vazia da API Claude."
    }

    $text = ($response.content | ForEach-Object { $_.text }) -join "`n"
    $outPath = Join-Path (Get-Location) $OutputFile
    Set-Content -Path $outPath -Value $text -Encoding UTF8

    Write-Host "Review salvo em: $outPath"

    if ($AutoApply) {
        $diffStart = $text.IndexOf('```diff')
        if ($diffStart -lt 0) {
            Fail "AutoApply habilitado, mas a resposta nao trouxe bloco diff."
        }

        $diffEnd = $text.IndexOf('```', $diffStart + 7)
        if ($diffEnd -lt 0) {
            Fail "Bloco diff incompleto na resposta."
        }

        $patch = $text.Substring($diffStart + 7, $diffEnd - ($diffStart + 7)).Trim()
        if ([string]::IsNullOrWhiteSpace($patch)) {
            Fail "Bloco diff vazio."
        }

        $patchFile = Join-Path (Get-Location) "tools/claude_review.patch"
        Set-Content -Path $patchFile -Value $patch -Encoding UTF8

        git apply --index $patchFile
        if ($LASTEXITCODE -ne 0) {
            Fail "Falha ao aplicar patch automaticamente. Verifique $patchFile"
        }

        Write-Host "Patch aplicado com sucesso (staged)."

        $stagedFiles = @(git diff --cached --name-only)
        $stagedStat = git diff --cached --shortstat
        $stagedDiff = git diff --cached

        $appliedDiffPath = Join-Path (Get-Location) "tools/claude_applied.diff"
        Set-Content -Path $appliedDiffPath -Value $stagedDiff -Encoding UTF8

        $reportPath = Join-Path (Get-Location) $ReportFile
        $filesList = if ($stagedFiles.Count -gt 0) {
            ($stagedFiles | ForEach-Object { "- $_" }) -join "`n"
        } else {
            "- Nenhum arquivo staged"
        }

        $report = @"
# Claude Corrections Report

- Model: $Model
- Review output: $OutputFile
- Patch file: tools/claude_review.patch
- Applied diff: tools/claude_applied.diff
- Generated at: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Summary
$stagedStat

## Corrected Files
$filesList

## Next Steps
1. Revisar o conteúdo de tools/claude_applied.diff
2. Rodar testes/ATC no ADT
3. Commitar as correções validadas
"@

        Set-Content -Path $reportPath -Value $report -Encoding UTF8
        Write-Host "Relatorio salvo em: $reportPath"
    }
}
finally {
    Pop-Location
}
