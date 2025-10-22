param(
    [string]$DatabaseName = "dune_messenger",
    [string]$DbUser = "postgres",
    [string]$DbPassword = "postgres",
    [int]$Port = 5432,
    [switch]$SkipInstall,
    [switch]$SkipPrisma,
    [switch]$NoStart,
    [switch]$ForceEnv
)

$ErrorActionPreference = "Stop"

function Write-Info([string]$Message) {
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Write-WarnMessage([string]$Message) {
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-ErrorMessage([string]$Message) {
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
Write-Info "Repository root resolved to $repoRoot"

if (-not $IsWindows) {
    Write-WarnMessage "This script targets Windows 11. Detected platform: $([System.Environment]::OSVersion.VersionString)."
}

function Get-PostgresVersion {
    $psql = Get-Command psql -ErrorAction SilentlyContinue
    if (-not $psql) {
        return $null
    }

    $output = & $psql.Source "--version"
    if ($LASTEXITCODE -ne 0) {
        Write-WarnMessage "Failed to read psql version (exit code $LASTEXITCODE)."
        return $null
    }

    if ($output -match "(\d+)\.(\d+)") {
        return [version]::new([int]$Matches[1], [int]$Matches[2])
    }

    Write-WarnMessage "Unable to parse psql version output: $output"
    return $null
}

function Ensure-Postgres {
    $version = Get-PostgresVersion
    if ($null -ne $version -and $version.Major -ge 14) {
        Write-Info "PostgreSQL $($version.ToString()) detected."
        return
    }

    if ($SkipInstall) {
        throw "PostgreSQL 14+ not found and installation skipped."
    }

    Write-Info "Installing PostgreSQL 14 via Chocolatey..."
    $choco = Get-Command choco -ErrorAction SilentlyContinue
    if (-not $choco) {
        throw "Chocolatey not available. Install Chocolatey or PostgreSQL manually, then re-run the script."
    }

    $installArgs = @("install", "postgresql14", "--yes", "--params", "'/Password:$DbPassword /Port:$Port'")
    & $choco.Source @installArgs
    if ($LASTEXITCODE -ne 0) {
        throw "Chocolatey installation failed with exit code $LASTEXITCODE."
    }

    Start-Sleep -Seconds 5
    $version = Get-PostgresVersion
    if ($null -eq $version -or $version.Major -lt 14) {
        throw "PostgreSQL 14+ not detected after installation."
    }

    Write-Info "PostgreSQL $($version.ToString()) installed successfully."
}

function Invoke-Psql([string]$Sql) {
    $psql = Get-Command psql -ErrorAction Stop
    $env:PGPASSWORD = $DbPassword
    $arguments = @("-h", "localhost", "-p", $Port, "-U", $DbUser, "-c", $Sql)
    & $psql.Source @arguments
    $lastCode = $LASTEXITCODE
    Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
    if ($lastCode -ne 0) {
        throw "psql command failed with exit code $lastCode."
    }
}

function Ensure-Role {
    Write-Info "Ensuring role '$DbUser' exists with provided password."
    $sql = @"
DO
$$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '$DbUser') THEN
        EXECUTE format('CREATE ROLE %I LOGIN PASSWORD %L SUPERUSER CREATEDB CREATEROLE;', '$DbUser', '$DbPassword');
    ELSE
        EXECUTE format('ALTER ROLE %I WITH PASSWORD %L SUPERUSER CREATEDB CREATEROLE;', '$DbUser', '$DbPassword');
    END IF;
END
$$;
"@
    Invoke-Psql $sql
}

function Ensure-Database {
    Write-Info "Ensuring database '$DatabaseName' exists."
    $sql = "SELECT 'created' FROM pg_database WHERE datname = '$DatabaseName';"
    $psql = Get-Command psql -ErrorAction Stop
    $env:PGPASSWORD = $DbPassword
    $arguments = @("-h", "localhost", "-p", $Port, "-U", $DbUser, "-tA", "-c", $sql)
    $result = & $psql.Source @arguments
    $lastCode = $LASTEXITCODE
    Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
    if ($lastCode -ne 0) {
        throw "Failed to query for existing database (exit code $lastCode)."
    }

    if (-not $result -or -not $result.Trim()) {
        Invoke-Psql "CREATE DATABASE \"$DatabaseName\" OWNER \"$DbUser\";"
        Write-Info "Database '$DatabaseName' created."
    } else {
        Write-Info "Database '$DatabaseName' already present."
    }
}

function Ensure-EnvFile {
    $envFile = Join-Path $repoRoot ".env"
    if (Test-Path $envFile -and -not $ForceEnv) {
        Write-WarnMessage ".env already exists. Use -ForceEnv to overwrite or update it manually."
        return
    }

    $connection = "DATABASE_URL=postgresql://$DbUser:$DbPassword@localhost:$Port/$DatabaseName"
    $content = @(
        $connection,
        "JWT_SECRET=change-me",
        "NEXTAUTH_SECRET=change-me",
        "NEXTAUTH_URL=http://localhost:3000"
    )
    Set-Content -Path $envFile -Value $content -Encoding UTF8
    Write-Info "Created $envFile with default secrets."
}

function Invoke-PnpmCommand([string]$Command) {
    $pnpm = Get-Command pnpm -ErrorAction SilentlyContinue
    if (-not $pnpm) {
        throw "pnpm is not available. Enable pnpm with 'corepack enable pnpm' or install it manually."
    }

    Push-Location $repoRoot
    try {
        Write-Info "Running pnpm $Command"
        & $pnpm.Source $Command
        if ($LASTEXITCODE -ne 0) {
            throw "pnpm $Command failed with exit code $LASTEXITCODE."
        }
    }
    finally {
        Pop-Location
    }
}

function Run-Prisma {
    if ($SkipPrisma) {
        Write-WarnMessage "Skipping Prisma commands as requested."
        return
    }

    Invoke-PnpmCommand "db:push"
    Invoke-PnpmCommand "db:seed"
}

function Start-Services {
    if ($NoStart) {
        Write-WarnMessage "Service auto-start skipped."
        return
    }

    $pnpm = Get-Command pnpm -ErrorAction SilentlyContinue
    if (-not $pnpm) {
        Write-WarnMessage "pnpm not available; cannot start dev servers automatically."
        return
    }

    $apiArgs = "-NoExit", "-Command", "cd `"$repoRoot`"; pnpm dev:api"
    $webArgs = "-NoExit", "-Command", "cd `"$repoRoot`"; pnpm dev:web"

    Write-Info "Starting API dev server (http://localhost:4000) in new PowerShell window."
    Start-Process -FilePath "powershell" -ArgumentList $apiArgs | Out-Null

    Start-Sleep -Seconds 2

    Write-Info "Starting Web dev server (http://localhost:3000) in new PowerShell window."
    Start-Process -FilePath "powershell" -ArgumentList $webArgs | Out-Null
}

try {
    Ensure-Postgres
    Ensure-Role
    Ensure-Database
    Ensure-EnvFile
    Run-Prisma
    Start-Services
    Write-Info "Database setup completed successfully."
}
catch {
    Write-ErrorMessage $_
    throw
}
