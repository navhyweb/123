<#
.SYNOPSIS
    Da de alta en GAM los usuarios con Rol Despachante, invocando el procedimiento
    GeneXus "Alta_Usuarios_GAM_Excel" (Main program, Call Protocol = HTTP).

.DESCRIPTION
    Lee usuarios_despachante.csv (generado desde la pestaña
    "DESPACHANTE (Rol Despachante)" del Excel de usuarios) y por cada fila invoca
    el procedimiento pasando los parametros en el orden del parm():
        parm(&Name,&UserEmail,&FirstName,&LastName,&password,&rolID);

    GeneXus, para un Main program HTTP invocado por URL, recibe los parametros
    de forma posicional separados por coma en el query string:
        http://server/app/Alta_Usuarios_GAM_Excel.aspx?val1,val2,val3,val4,val5,val6

    Cada valor se url-encodea individualmente (nombres con espacios, password con
    caracteres especiales, etc.) antes de armar la URL.

.PARAMETER BaseUrl
    URL base de la aplicacion .NET (sin el nombre del procedimiento).

.PARAMETER CsvPath
    Ruta al CSV con columnas: Name,UserEmail,FirstName,LastName,password,rolID

.PARAMETER WhatIf
    Si se pasa, solo imprime las URLs que se invocarian, sin llamarlas.

.EXAMPLE
    # Prueba en desa02 sin ejecutar nada (solo mostrar URLs)
    .\Alta_Usuarios_GAM_Despachante.ps1 -WhatIf

.EXAMPLE
    # Ejecucion real contra desa02
    .\Alta_Usuarios_GAM_Despachante.ps1 -BaseUrl "https://desa02.rendelit.ar/RendelMoveDFWeb17_VDesarrollo.NetEnvironment"
#>

param(
    [string]$BaseUrl = "https://desa02.rendelit.ar/RendelMoveDFWeb17_VDesarrollo.NetEnvironment",
    [string]$ProcedureName = "Alta_Usuarios_GAM_Excel",
    [string]$CsvPath = (Join-Path $PSScriptRoot "usuarios_despachante.csv"),
    [string]$LogPath = (Join-Path $PSScriptRoot "alta_usuarios_despachante.log"),
    [switch]$WhatIf
)

if (-not (Test-Path $CsvPath)) {
    Write-Error "No se encontro el CSV en: $CsvPath"
    exit 1
}

$users = Import-Csv -Path $CsvPath

if ($users.Count -eq 0) {
    Write-Warning "El CSV no tiene filas de usuarios."
    exit 0
}

$procUrl = "$($BaseUrl.TrimEnd('/'))/$ProcedureName.aspx"

"Inicio: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $($users.Count) usuarios a procesar" | Tee-Object -FilePath $LogPath

$ok = 0
$fail = 0

foreach ($u in $users) {
    $params = @(
        $u.Name,
        $u.UserEmail,
        $u.FirstName,
        $u.LastName,
        $u.password,
        $u.rolID
    ) | ForEach-Object { [System.Uri]::EscapeDataString($_) }

    $url = "$procUrl`?" + ($params -join ",")

    if ($WhatIf) {
        Write-Host "[WHATIF] $url"
        continue
    }

    try {
        $response = Invoke-WebRequest -Uri $url -Method Get -UseBasicParsing -TimeoutSec 30
        $line = "OK   - $($u.Name) ($($u.UserEmail)) - HTTP $($response.StatusCode)"
        Write-Host $line -ForegroundColor Green
        $ok++
    }
    catch {
        $line = "FAIL - $($u.Name) ($($u.UserEmail)) - $($_.Exception.Message)"
        Write-Host $line -ForegroundColor Red
        $fail++
    }

    $line | Add-Content -Path $LogPath
}

if (-not $WhatIf) {
    $summary = "Fin: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - OK: $ok - FAIL: $fail"
    Write-Host $summary
    $summary | Add-Content -Path $LogPath
}
