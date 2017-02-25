<#
    Module de gestion des logs Powershell sur la console et/ou dans un fichier
#>

<#

    L'�num�ration contient la liste des niveaux de criticit� support�s
    Le niveau NONE permet de d�sactiver les traces

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

# Valeur par d�faut des variables de configuration du module
[LoggingLevel] $consoleLevel = [LoggingLevel]::ERROR;
[LoggingLevel] $fileLevel = [LoggingLevel]::ERROR;
[string] $filePath = "$env:TEMP";
[string] $fileName = "logger.log";

<#

.SYNOPSIS

Initialisation du logger


.DESCRIPTION

Fonction qui permet d'initialiser le logger avec les param�tres fournis ou des param�tres par d�faut
si certains param�tres sont manquants


.PARAMETER $consoleLevel

Doit �tre une valeur de l'enum�ration LoggingLevel. Il d�finit le niveau � partir duquel il faut commencer � afficher
les logs sur la console


.PARAMETER $fileLevel

Doit �tre une valeur de l'enum�ration LoggingLevel. Il d�finit le niveau � partir duquel il faut commencer � afficher
les logs dans le fichier


.PARAMETER $filePath

Dossier dans lequel d�poser le fichier contenant les logs


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
        throw $([string]::Format("Impossible d'�crire des logs dans le fichier [{0}\{1}] car le fichier ne peut pas �tre cr�� ou n'est pas accessible en �criture. (Exception [{2}] [{3}])", `
            $filePath, $fileName, $_.Exception.GetType().Name, $_.Exception.Message));
    }
    Write-Log $([LoggingLevel]::DEBUG) `
    $([string]::Format("Configuration du logger : r�pertoire de destination [{0}\{1}], niveau d'affichage sur la console [{2}], niveau d'affichage dans le fichier [{3}]", `
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

Fonction qui permet d'�crire si n�cessaire une ligne dans un fichier de logs et/ou sur la console


.PARAMETER $level

Doit �tre une valeur de l'enum�ration LoggingLevel. Il d�finit le niveau de criticit� de la ligne � �crire


.PARAMETER $contenu

Cha�ne qui contient le message � �crire


.EXAMPLE
Write-Log $([LoggingLevel]::DEBUG) "Ceci est un message de d�bogage";

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
            Write-Host $([string]::Format("Impossible d'�crire les logs dans le fichier de destination [{0}\{1}], une exception [{2}] a �t� lev�e avec le message [{3}]", `
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

Permet de d�finir la couleur d'�criture sur la console selon le niveau de criticit�


.DESCRIPTION

Fonction interne au module qui permet de choisir la couleur d'�criture sur la console en fonction du niveau de criticit� d'un message


.PARAMETER $level

Doit �tre une valeur de l'enum�ration LoggingLevel. Il d�finit le niveau de criticit� de la ligne � �crire

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
