<#
    Module de gestion des logs Powershell sur la console et/ou dans un fichier
#>

<#

    L'énumération contient la liste des niveaux de criticité supportés
    Le niveau NONE permet de désactiver les traces

#>
Add-Type -TypeDefinition @"
   public enum LoggingLevel
   {
      NONE = 50,
      DEBUG = 10,
      INFO = 20,
      WARN = 30,
      ERROR = 40
   }
"@

# Valeur par défaut des variables de configuration du module
[LoggingLevel] $consoleLevel = [LoggingLevel]::ERROR;
[LoggingLevel] $fileLevel = [LoggingLevel]::ERROR;
[string] $filePath = "$env:TEMP";
[string] $fileName = "logger.log";

<#

.SYNOPSIS

Initialisation du logger


.DESCRIPTION

Fonction qui permet d'initialiser le logger avec les paramètres fournis ou des paramètres par défaut
si certains paramètres sont manquants


.PARAMETER $consoleLevel

Doit être une valeur de l'enumération LoggingLevel. Il définit le niveau à partir duquel il faut commencer à afficher
les logs sur la console


.PARAMETER $fileLevel

Doit être une valeur de l'enumération LoggingLevel. Il définit le niveau à partir duquel il faut commencer à afficher
les logs dans le fichier


.PARAMETER $filePath

Dossier dans lequel déposer le fichier contenant les logs


.PARAMETER $fileName

Nom du fichier contenant les logs


.EXAMPLE
Initialize-Logger -consoleLevel $([LoggingLevel]::INFO) -fileLevel $([LoggingLevel]::DEBUG) `
    -fileName $([string]::Format("{0}_{1}.log", "mon application", $(Get-Date -Format yyyy-MM-dd_hh-mm-ss-fff ))) `
    -filePath "C:\windows\temp";

#>
function Initialize-Logger {
    Param(
        [LoggingLevel] $consoleLevel = [LoggingLevel]::ERROR,
        [LoggingLevel] $fileLevel = [LoggingLevel]::ERROR,
        [string] $filePath = "$env:TEMP",
        [string] $fileName = "logger.log"
    )
    $Script:consoleLevel = $consoleLevel;
    $Script:fileLevel = $fileLevel;
    $Script:filePath = $filePath;
    $Script:fileName = $fileName;
    try {
        if($fileLevel.value__ -lt $([LoggingLevel]::NONE).value__) {
            if(-Not (Test-Path $filePath -PathType Container)) {
                New-Item -path $filePath -type Directory -ErrorAction Stop | Out-Null;
            }
            if(-Not (Test-Path $([string]::Format("{0}\{1}", $filePath, $fileName)) -PathType Leaf)) {
                New-Item -path $([string]::Format("{0}\{1}", $filePath, $fileName)) -type File -ErrorAction Stop | Out-Null;
            }
            [io.file]::OpenWrite($([string]::Format("{0}\{1}", $filePath, $fileName))).close();
        }
    } catch {
        throw $([string]::Format("Impossible d'écrire des logs dans le fichier [{0}\{1}] car le fichier ne peut pas être créé ou n'est pas accessible en écriture. (Exception [{2}] [{3}])", `
            $filePath, $fileName, $_.Exception.GetType().Name, $_.Exception.Message));
    }
    Write-Log $([LoggingLevel]::DEBUG) `
    $([string]::Format("Configuration du logger : répertoire de destination [{0}\{1}], niveau d'affichage sur la console [{2}], niveau d'affichage dans le fichier [{3}]", `
        $filePath, `
        $fileName, `
        $consoleLevel, `
        $fileLevel `
    ));
}

<#

.SYNOPSIS

Ecrire une ligne dans un fichier log


.DESCRIPTION

Fonction qui permet d'écrire si nécessaire une ligne dans un fichier de logs et/ou sur la console


.PARAMETER $level

Doit être une valeur de l'enumération LoggingLevel. Il définit le niveau de criticité de la ligne à écrire


.PARAMETER $contenu

Chaîne qui contient le message à écrire


.EXAMPLE
Write-Log $([LoggingLevel]::DEBUG) "Ceci est un message de débogage";

#>
function Write-Log {
    Param(
        [LoggingLevel] $level,
        [string] $contenu
    )
    if($contenu.Length.Equals(0)) {
        return;
    }
    if([int]$level.value__ -ge [int]$consoleLevel.value__) {
        Write-Host $contenu -ForegroundColor $(Get-ColorForLoggingLevel($level));
    }
    if([int]$level.value__ -ge [int]$fileLevel.value__) {
        try {
            $ligneLog = [string]::Format("{0} | {1,5} | {2}", $(Get-Date -Format "yyyy-MM-dd hh:mm:ss.fff" ), $level, $contenu);
            Out-File $([string]::Format("{0}\{1}", $filePath, $fileName)) -InputObject $ligneLog -NoClobber -Append -Width $ligneLog.Length
        } catch {
            Write-Host $([string]::Format("Impossible d'écrire les logs dans le fichier de destination [{0}\{1}], une exception [{2}] a été levée avec le message [{3}]", `
                $filePath, `
                $fileName, `
                $_.Exception.GetType().Name, `
                $_.Exception.Message `
            )) -ForegroundColor Red;
            throw $_.Exception;
        }
    }
}

<#

.SYNOPSIS

Permet de définir la couleur d'écriture sur la console selon le niveau de criticité


.DESCRIPTION

Fonction interne au module qui permet de choisir la couleur d'écriture sur la console en fonction du niveau de criticité d'un message


.PARAMETER $level

Doit être une valeur de l'enumération LoggingLevel. Il définit le niveau de criticité de la ligne à écrire

#>
function Get-ColorForLoggingLevel([LoggingLevel] $level) {
    switch($level.value__) {
        10 { return "Cyan"; }
        20 { return "Green"; }
        30 { return "Yellow"; }
        40 { return "Red"; }
        default { return "Black"; }
    }
}
