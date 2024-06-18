# Recoge información del equipo
$systemInfo = @{
    # General
    computerName = $env:COMPUTERNAME
    operatingSystem = (Get-WmiObject -Class Win32_OperatingSystem).Caption
    osVersion = (Get-WmiObject -Class Win32_OperatingSystem).Version

    # CPU
    processorModel = (Get-WmiObject -Class Win32_Processor).Name
    processorArchitecture = (Get-WmiObject -Class Win32_Processor).AddressWidth
    processorCores = (Get-WmiObject -Class Win32_Processor).NumberOfCores
    processorThreads = (Get-WmiObject -Class Win32_Processor).NumberOfLogicalProcessors
    processorClockSpeedGHz = [math]::Round((Get-WmiObject -Class Win32_Processor).MaxClockSpeed / 1024, 2)

    # RAM
    totalPhysicalMemoryGB = [math]::Round((Get-WmiObject -Class Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)

    # DISK
    diskModel = (Get-WmiObject -Class Win32_DiskDrive | Select-Object -First 1).Model
    totalDiskSpaceGB = [math]::Round((Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='C:'").Size / 1GB, 2)
    freeDiskSpaceGB = [math]::Round((Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='C:'").FreeSpace / 1GB, 2)
    usedDiskSpaceGB = [math]::Round(((Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='C:'").Size - (Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='C:'").FreeSpace) / 1GB, 2)

    # NET ADAPTER
    networkAdapterDescription = (Get-WmiObject -Class Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq $true } | Select-Object -First 1).Description
    macAddress = (Get-WmiObject -Class Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq $true } | Select-Object -First 1).MACAddress
    ipAddress = (Get-WmiObject -Class Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq $true } | Select-Object -First 1).IPAddress -join ", "
}

# Convierte la información a formato JSON
$jsonOutput = $systemInfo | ConvertTo-Json -Depth 4

# URL de la API REST en NestJS
$apiUrl = "http://api.formateya.es/api/inventory"  # Reemplaza con la URL correcta de tu API

try {
    # Envía la solicitud POST a la API REST
    Invoke-RestMethod -Uri $apiUrl -Method Post -Body $jsonOutput -ContentType "application/json"
} catch {
    Write-Error "Error al enviar la solicitud a la API"
}