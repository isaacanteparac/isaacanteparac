function new {
    param (
        [Parameter(Mandatory=$true)]
        [string]$fileName
    )

    # Construir la ruta completa
    $fullPath = Join-Path -Path (Get-Location) -ChildPath $fileName

    # Identificar si es un archivo o carpeta
    if ($fileName -match "\.") {
        # Caso: Es un archivo porque tiene un punto en el nombre
        Set-Content -Path $fullPath -Value ""
        Write-Host "New File Created 📄" -ForegroundColor Green
    } else {
        # Caso: Es una carpeta porque no tiene un punto en el nombre
        New-Item -Path $fullPath -ItemType Directory
        Write-Host "New Directory Created 📁" -ForegroundColor Yellow
    }
}

function click-all {
    <#
    .SYNOPSIS
        Opens or executes all files in the current working directory.
    .DESCRIPTION
        This function uses Get-ChildItem to find all files in the current location
        and then uses Invoke-Item to simulate a double-click action on each one.
    .EXAMPLE
        click-all
        
        # Starts executing/opening all files in the current folder.
    #>
    [CmdletBinding()]
    param()

    Write-Host "Starting 'click-all' process..." -ForegroundColor Yellow

    # Define the path to the current directory where the command is being executed
    $CurrentPath = Get-Location

    Write-Host "Current Directory: $($CurrentPath.Path)" -ForegroundColor Cyan
    
    # Get all files within the current directory
    # -File ensures only files are processed, not folders
    $files = Get-ChildItem -Path $CurrentPath -File

    if ($files.Count -eq 0) {
        Write-Host "No files found in the current directory to process." -ForegroundColor Red
        return
    }

    Write-Host "Found $($files.Count) files. Starting execution/opening..." -ForegroundColor Green
    
    # Iterate over each file found
    $files | ForEach-Object {
        # $_ represents the current file object in the loop
        $FilePath = $_.FullName
        Write-Host "  -> Executing/Opening file: $($_.Name)" -ForegroundColor Magenta
        
        # 'Invoke-Item' (alias: 'ii') simulates the double-click action
        Invoke-Item $FilePath
        
        # Optional: Pause between opening files (uncomment to enable)
        # Start-Sleep -Seconds 1
    }

    Write-Host "Process 'click-all' completed." -ForegroundColor Yellow
}

function hash {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    # Check if the file exists before proceeding
    if (-not (Test-Path $Path -PathType Leaf)) {
        Write-Error "The file was not found at the path: $Path"
        return
    }

    $algorithmsMap = @{
        1 = 'MD5'
        2 = 'SHA1'
        3 = 'SHA256'
    }
    
    # Store for calculated hashes
    $calculatedHashes = @{}

    ## 1. Calculate All Hashes (Always) 💾
    Write-Host "--- Initiating Hash Calculation for '$Path' ---" -ForegroundColor Cyan
    
    # Calculate all three hashes and store them
    foreach ($key in $algorithmsMap.Keys) {
        $algorithmName = $algorithmsMap[$key]
        $hashObject = Get-FileHash -Path $Path -Algorithm $algorithmName
        $calculatedHashes.Add($algorithmName, $hashObject.Hash)
    }

    ## 2. Display and Verification Menu 📝

    Write-Host "`n--- Options Menu ---" -ForegroundColor Yellow
    Write-Host "1. MD5 (Verify)"
    Write-Host "2. SHA1 (Verify)"
    Write-Host "3. SHA256 (Verify)"
    Write-Host "0. Show all calculated hashes"
    
    # Prompt the user for the option
    [string]$optionInput = Read-Host "Enter the option number (0-3)"
    
    # Fix for [ref] in TryParse: declare and initialize $option first
    [int]$option = -1 
    if (-not [int]::TryParse($optionInput, [ref]$option)) {
        Write-Error "Invalid input. Please enter a valid number (0-3)."
        return
    }

    # Option 0: Show all hashes
    if ($option -eq 0) {
        Write-Host "`nDisplaying **ALL** calculated hashes:" -ForegroundColor Green
        
        # Display the stored results
        $calculatedHashes | Format-List
    } 
    # Options 1, 2, or 3: Show only one and verify
    elseif ($option -ge 1 -and $option -le 3) {
        
        $selectedAlgorithm = $algorithmsMap[$option]
        $calculatedHashValue = $calculatedHashes[$selectedAlgorithm]
        
        Write-Host "`nSelected Algorithm: **$selectedAlgorithm**" -ForegroundColor Green
        
        # Prompt user for hash
        $userHash = Read-Host "Enter the **$selectedAlgorithm** hash for verification"
        
        # Convert the entered hash to uppercase
        $userHash = $userHash.ToUpper()

        Write-Host "--- Verification Result ---" -ForegroundColor Cyan
        
        # Display Calculated Hash once (before the pass/fail result)
        Write-Host "Calculated Hash ($selectedAlgorithm): $calculatedHashValue" -ForegroundColor Yellow

        # Compare the hashes
        if ($userHash -ceq $calculatedHashValue) {
            Write-Host "**VERIFICATION SUCCESSFUL: YES** - The entered hash is identical to the calculated one." -ForegroundColor Green
        } else {
            Write-Host "**VERIFICATION FAILED: NO** - The entered hash does NOT match the calculated one." -ForegroundColor Red
            Write-Host "Entered Hash (UPPER): $userHash"
            # REMOVED: Write-Host "Calculated Hash: $calculatedHashValue" <-- This line was redundant
        }
    } 
    # Invalid option
    else {
        Write-Host "Option '$option' is invalid. The function has finished." -ForegroundColor Red
    }
}

function delete {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Path
    )

    # Eliminar archivos o carpetas
    Remove-Item -Path $Path -Force -Recurse
    Write-Host "Successfully removed" -ForegroundColor Green

}

function ipc {
    <#
    .SYNOPSIS
        Retrieves and displays detailed system hardware and network information.
    .DESCRIPTION
        This function uses PowerShell cmdlets (Get-ComputerInfo, Get-CimInstance) 
        to gather and display information about the CPU, RAM, GPU, OS, and network configuration.
    .EXAMPLE
        pc-info
        
        # Displays the hardware and system details of the local computer.
    #>
    [CmdletBinding()]
    param()

    # Get basic system information
    $systemInfo = Get-ComputerInfo
    $cpuInfo = Get-CimInstance -ClassName Win32_Processor
    $memoryInfo = Get-CimInstance -ClassName Win32_PhysicalMemory
    $gpuInfo = Get-CimInstance -ClassName Win32_VideoController
    $networkInfo = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq $true }

    # Display system information
    Write-Host "== System Information ==" -ForegroundColor Cyan
    Write-Host "Computer Name: $($systemInfo.CsName)"
    Write-Host "Operating System: $($systemInfo.OsName)"
    Write-Host "OS Version: $($systemInfo.OsVersion)"
    Write-Host "System Manufacturer: $($systemInfo.Manufacturer)"
    Write-Host "Model: $($systemInfo.Model)"
    Write-Host "==================================="

    Write-Host "== CPU Information ==" -ForegroundColor Cyan
    $cpuInfo | ForEach-Object {
        Write-Host "Processor Name: $($_.Name)"
        Write-Host "Cores: $($_.NumberOfCores)"
        Write-Host "Logical Processors: $($_.NumberOfLogicalProcessors)"
    }
    Write-Host "==================================="

    Write-Host "== RAM Memory Information ==" -ForegroundColor Cyan
    # Calculate Total RAM Capacity and display details for each stick
    $totalRamGB = ($memoryInfo | Measure-Object -Property Capacity -Sum).Sum / 1GB
    Write-Host "Total Installed Memory: $([int]$totalRamGB) GB"
    
    $memoryInfo | ForEach-Object {
        Write-Host "  -> Capacity: $(($_.Capacity / 1GB) -as [int]) GB"
        Write-Host "  -> Manufacturer: $($_.Manufacturer)"
        Write-Host "  -> Speed: $($_.Speed) MHz"
    }
    Write-Host "==================================="

    Write-Host "== GPU Information ==" -ForegroundColor Cyan
    $gpuInfo | ForEach-Object {
        Write-Host "GPU Name: $($_.Name)"
        Write-Host "Driver Version: $($_.DriverVersion)"
        # Note: AdapterRAM is often reported in bytes, convert to MB
        Write-Host "Video Memory: $([int]($_.AdapterRAM / 1MB)) MB"
    }
    Write-Host "==================================="

    Write-Host "== Network Information ==" -ForegroundColor Cyan
    $networkInfo | ForEach-Object {
        Write-Host "Interface: $($_.Description)"
        Write-Host "MAC Address: $($_.MACAddress)"
        if ($_.IPAddress) {
            Write-Host "IP Addresses:"
            # Filter out IPv6 addresses starting with fe80:: (link-local)
            $_.IPAddress | Where-Object { $_ -notlike "fe80:*" } | ForEach-Object { Write-Host "- $_" }
        }
        Write-Host "-----------------------------------"
    }
    Write-Host "==================================="
}

function server {
    # Generar un puerto aleatorio entre 1024 y 65535
    $randomPort = Get-Random -Minimum 1024 -Maximum 65535

    # Obtener la IP pública
    try {
        $publicIP = Invoke-WebRequest -Uri "https://api64.ipify.org?format=text" | Select-Object -ExpandProperty Content
    } catch {
        $publicIP = "Unable to retrieve public IP"
    }

    # Obtener todas las IPs locales (IPv4) de todos los adaptadores
    $networkInterfaces = Get-NetIPAddress | Where-Object { $_.AddressFamily -eq "IPv4" } | Select-Object InterfaceAlias, IPAddress

    # Mostrar información en la consola
    Write-Host "Server Started -> IP Port ${randomPort}" -ForegroundColor Green
    Write-Host "Adapters:" -ForegroundColor Green
    # Listar todas las IPs asociadas a cada adaptador
    foreach ($adapter in $networkInterfaces) {
        Write-Host "   $($adapter.InterfaceAlias)" -ForegroundColor Yellow
        Write-Host "    -> http://$($adapter.IPAddress):$randomPort" -ForegroundColor Cyan
    }

    Write-Host "IP Public: http://${publicIP}:${randomPort}" -ForegroundColor Cyan

    # Ejecutar el servidor HTTP en el proceso actual
    python -m http.server $randomPort
}
# Para usar la función, solo tienes que escribir su nombre en la consola de PowerShell:
# Generate-Letter

function open {
    param (
        [string]$target
    )

    # Definir la ruta completa
    $fullPath = if (-not $target) { 
        Get-Location.Path 
    } else { 
        Join-Path -Path (Get-Location) -ChildPath $target
    }

    # Verificar si el archivo o carpeta existe
    if (Test-Path $fullPath) {
        # 'Invoke-Item' (alias 'ii') abre cualquier archivo o carpeta 
        # con la aplicación predeterminada del sistema (simula el doble clic).
        Invoke-Item $fullPath 
        Write-Host "Opening '$fullPath' with the system's default application." -ForegroundColor Green
    } else {
        Write-Host "The file or folder '$target' doesn't exist." -ForegroundColor Red
    }
}

function edit-commands {
    $fullPath = "C:\Users\user\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"

    # Verificar si el archivo existe
    if (Test-Path $fullPath) {
        # Abrir el archivo en Visual Studio Code directamente
        code $fullPath
        Write-Host "Opening configuration file '$fullPath'." -ForegroundColor Green
    } else {
        Write-Host "The file '$fullPath' does not exist." -ForegroundColor Red
    }
}

function copy {
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$source,       # Archivo o carpeta que deseas copiar
        [Parameter(Mandatory = $true, Position = 1)]
        [string]$destination   # Carpeta o ruta destino donde pegar la copia
    )

    # Verificar si el archivo o carpeta de origen existe
    if (-not (Test-Path $source)) {
        Write-Host "Error: The source file or folder '$source' does not exist." -ForegroundColor Red
        return
    }

    # Verificar si la carpeta de destino existe
    if (-not (Test-Path (Split-Path -Parent $destination))) {
        Write-Host "Error: The destination folder does not exist. Please create it first." -ForegroundColor Red
        return
    }

    # Intentar copiar el archivo o carpeta
    try {
        Copy-Item -Path $source -Destination $destination -Recurse
        Write-Host "Successfully copied '$source' to '$destination'." -ForegroundColor Green
    } catch {
        Write-Host "Error: Failed to copy '$source' to '$destination'. $_" -ForegroundColor Red
    }
}

function find {
    param (
        [Parameter(Mandatory = $true)]
        [string]$query,      # Criterio de búsqueda: extensión (.psd) o nombre parcial (docu)
        [switch]$near,       # Interruptor para búsqueda en subcarpetas inmediatas
        [switch]$deep        # Interruptor para habilitar búsqueda profunda en todos los niveles
    )

    # Validar entrada
    if (-not $query) {
        Write-Host "You must provide a query (e.g., .psd or docu)." -ForegroundColor Red
        return
    }

    # Determinar alcance de la búsqueda
    if ($deep) {
        Write-Host "Performing a deep search in all nested subdirectories..." -ForegroundColor Green

        # Búsqueda profunda en todos los niveles (archivos y carpetas)
        $results = Get-ChildItem -Path . -Recurse | Where-Object {
            ($query.StartsWith('.') -and $_.Extension -like "$query") -or
            (-not $query.StartsWith('.') -and $_.Name -like "*$query*")
        }
    } elseif ($near) {
        Write-Host "Performing search limited to subdirectories..." -ForegroundColor Cyan

        # Búsqueda limitada a subcarpetas inmediatas (archivos y carpetas)
        $results = Get-ChildItem -Path . -Directory | ForEach-Object {
            Get-ChildItem -Path $_.FullName | Where-Object {
                ($query.StartsWith('.') -and $_.Extension -like "$query") -or
                (-not $query.StartsWith('.') -and $_.Name -like "*$query*")
            }
        }
    } else {
        Write-Host "Performing search in the current folder..." -ForegroundColor Green

        # Búsqueda en la carpeta actual (archivos y carpetas)
        $results = Get-ChildItem -Path . | Where-Object {
            ($query.StartsWith('.') -and $_.Extension -like "$query") -or
            (-not $query.StartsWith('.') -and $_.Name -like "*$query*")
        }
    }

    # Mostrar resultados
    if ($results) {
        $results | ForEach-Object {
            [PSCustomObject]@{
                Name       = $_.Name
                Extension  = if ($_.PSIsContainer) { "" } else { $_.Extension }
                FullName   = $_.FullName
            }
        } | Format-Table -AutoSize
    } else {
        Write-Host "No matches found for '$query'." -ForegroundColor Red
        Write-Host "Example: To search for files with the '.txt' extension in subdirectories, use:" -ForegroundColor Yellow
        Write-Host "         find .txt -near" -ForegroundColor Cyan
        Write-Host "Example: To search deeply for folders or files containing 'project', use:" -ForegroundColor Yellow
        Write-Host "         find project -deep" -ForegroundColor Cyan
    }
}

function environment {
    param (
        [switch]$create,    # Interruptor para crear un entorno virtual
        [switch]$active,    # Interruptor para activar un entorno virtual
        [Parameter(Mandatory = $true)]
        [string]$envName    # Nombre del entorno virtual
    )

    if ($create -and $active) {
        Write-Host "You cannot specify both -create and -active at the same time." -ForegroundColor Red
        return
    }

    if ($create) {
        # Crear entorno virtual
        if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
            Write-Host "Python is not installed or not added to PATH." -ForegroundColor Red
            return
        }

        Write-Host "Creating Python environment named '$envName' in the current folder..." -ForegroundColor Green
        python -m venv $envName

        # Verificar si se creó correctamente
        if (Test-Path "$PWD\$envName") {
            Write-Host "Environment '$envName' created successfully!" -ForegroundColor Cyan
        } else {
            Write-Host "Failed to create the environment '$envName'. Please check for errors." -ForegroundColor Red
        }
    } elseif ($active) {
        # Activar entorno virtual
        $activateScript = ".\$envName\Scripts\activate"
        if (Test-Path "$PWD\$envName\Scripts\activate") {
            Write-Host "Activating the environment '$envName'..." -ForegroundColor Green
            Invoke-Expression $activateScript
            Write-Host "Environment '$envName' is now active!" -ForegroundColor Cyan
        } else {
            Write-Host "Failed to find the activation script for '$envName'. Ensure the environment exists or create it first with:" -ForegroundColor Red
            Write-Host "    environment -create $envName" -ForegroundColor Cyan
        }
    } else {
        Write-Host "You must specify either -create or -active as the action." -ForegroundColor Red
    }
}

function rename {
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$oldName,  # Nombre original del archivo o carpeta
        [Parameter(Mandatory = $true, Position = 1)]
        [string]$newName   # Nuevo nombre del archivo o carpeta
    )

    # Verificar si el archivo o carpeta original existe
    if (-not (Test-Path $oldName)) {
        Write-Host "Error: The file or folder '$oldName' does not exist." -ForegroundColor Red
        return
    }

    # Verificar si ya existe un archivo o carpeta con el nuevo nombre
    if (Test-Path $newName) {
        Write-Host "Error: A file or folder with the name '$newName' already exists." -ForegroundColor Red
        return
    }

    # Intentar renombrar
    try {
        Rename-Item -Path $oldName -NewName $newName
        Write-Host "Successfully renamed '$oldName' to '$newName'." -ForegroundColor Green
    } catch {
        Write-Host "Error: Failed to rename '$oldName' to '$newName'. $_" -ForegroundColor Red
    }
}

function move {
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$source,       # Archivo o carpeta que deseas mover
        [Parameter(Mandatory = $true, Position = 1)]
        [string]$destination   # Carpeta o ruta destino
    )

    # Verificar si el origen existe
    if (-not (Test-Path $source)) {
        Write-Host "Error: The source file or folder '$source' does not exist." -ForegroundColor Red
        return
    }

    # Verificar si la carpeta de destino existe
    if (-not (Test-Path (Split-Path -Parent $destination))) {
        Write-Host "Error: The destination folder does not exist. Please create it first." -ForegroundColor Red
        return
    }

    # Intentar mover el archivo o carpeta
    try {
        Move-Item -Path $source -Destination $destination
        Write-Host "Successfully moved '$source' to '$destination'." -ForegroundColor Green
    } catch {
        Write-Host "Error: Failed to move '$source' to '$destination'. $_" -ForegroundColor Red
    }
}

function auto-shutdown {
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [int]$value,  # Cantidad de tiempo

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateSet("min", "hr")]
        [string]$unit # Unidad de tiempo: minutos o horas
    )

    # Validar que el valor sea positivo
    if ($value -le 0) {
        Write-Host "❌ Error: The time value must be greater than zero." -ForegroundColor Red
        Write-Host "`n✅ Example commands:" -ForegroundColor Yellow
        Write-Host "  auto-shutdown 10 -min   # Shutdown in 10 minutes" -ForegroundColor Cyan
        Write-Host "  auto-shutdown 1 -hr     # Shutdown in 1 hour" -ForegroundColor Cyan
        return
    }

    # Convertir a segundos
    switch ($unit) {
        "min" { $seconds = $value * 60 }
        "hr"  { $seconds = $value * 3600 }
    }

    # Ejecutar el comando de apagado
    try {
        shutdown.exe -s -t $seconds
        Write-Host "🕒 Shutdown scheduled in $value $unit ($seconds seconds)." -ForegroundColor Green
    } catch {
        Write-Host "❌ Error: Failed to schedule shutdown. $_" -ForegroundColor Red
    }
}

function commands {
    $commands = @(
        [PSCustomObject]@{ Name = "open"; Description = "Abre un archivo o carpeta con la **aplicación predeterminada** del OS. Si no se especifica ruta, abre la carpeta actual en el Explorador." },
        # ... (Resto de los comandos sin cambios)
        [PSCustomObject]@{ Name = "delete"; Description = "Elimina de forma forzada y recursiva un archivo o carpeta del OS. Uso: delete nombre_o_ruta" },
        [PSCustomObject]@{ Name = "new"; Description = "Crea un nuevo archivo (si el nombre tiene un punto) o un nuevo directorio/carpeta (si no tiene punto) en la ubicación actual. Uso: new archivo.txt o new carpeta_nombre" },
        [PSCustomObject]@{ Name = "ipc"; Description = "Muestra información detallada sobre los componentes de hardware (CPU, RAM, GPU, OS) y la configuración de red de tu PC." },
        [PSCustomObject]@{ Name = "server"; Description = "Inicia un servidor HTTP web simple con Python en la carpeta actual, seleccionando un puerto aleatorio. Muestra las IPs local y pública." },
        [PSCustomObject]@{ Name = "environment"; Description = "Gestiona entornos virtuales de Python. Usa -create para crear uno nuevo (environment -create myenv) o -active para activarlo (environment -active myenv)." }
        [PSCustomObject]@{ Name = "move"; Description = "Mueve un archivo o carpeta de una ubicación a otra. Uso: move archivo_o_carpeta_origen ruta_destino" }
        [PSCustomObject]@{ Name = "copy"; Description = "Copia un archivo o carpeta a una nueva ubicación. Uso: copy archivo_o_carpeta_origen ruta_destino" }
        [PSCustomObject]@{ Name = "hash"; Description = "Calcula el hash (MD5, SHA1, SHA256) de un archivo y permite verificarlo contra un hash introducido por el usuario. Uso: hash ruta_del_archivo" }
        [PSCustomObject]@{ Name = "auto-shutdown"; Description = "Programa el apagado del PC después de un tiempo especificado. Uso: auto-shutdown 30 -min o auto-shutdown 1 -hr" }
        [PSCustomObject]@{ Name = "click-all"; Description = "Simula un 'doble clic' o ejecución para todos los archivos dentro del directorio de trabajo actual. **¡Usar con precaución!**" }
        [PSCustomObject]@{
                                 Name = "rename";
                                 Description = "Renombra un archivo o carpeta existente. Requiere el nombre original y el nuevo nombre. Uso: rename nombre_antiguo.txt nuevo_nombre.txt"
        }
        [PSCustomObject]@{
                          Name = "find";
                          Description = "Busca archivos/carpetas en la ubicación actual. Usa -near para subdirectorios inmediatos o -deep para búsqueda recursiva en todos los niveles. Búsqueda por extensión (.ext) o por nombre parcial."
        }
        [PSCustomObject]@{ Name = "edit-commands"; Description = "Abre el archivo de perfil de PowerShell (`Microsoft.PowerShell_profile.ps1`) en VS Code para editar tus comandos personalizados." }
    )

    # Mostrar la tabla en pantalla
    $commands | Format-Table -Property Name, Description -AutoSize
}