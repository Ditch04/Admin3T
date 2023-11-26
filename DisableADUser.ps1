# Ce script désactive les comptes Active Directory en fonction du contenu d'un fichier CSV avec la structure indiquée sur les deux lignes suivantes :
# samAccountName
# loicdero

# Les paramètres du script sont le délimiteur du fichier CSV (par défaut ;) et le chemin du fichier CSV contenant les utilisateurs à désactiver.
# Author: Loïc Dero & Dylan Feron

param(
    $path,
    $delimiter=';'
)

# Importer le CSV
$csv = Import-Csv -Delimiter $delimiter -Path $path

# Parcourir chaque ligne du CSV
$csv | ForEach-Object {
    $row = $_
    $sam = $row.samAccountName
    $exists = [bool](Get-ADUser -Filter {SamAccountName -eq $sam})

    if ($exists) {
        $user = Get-ADUser -Filter {SamAccountName -eq $sam}

        if ($user.Enabled) {
            Disable-ADAccount -Identity $sam
            Write-Host "L'utilisateur $sam a été désactivé." -ForegroundColor Green
        } else {
            Write-Host "L'utilisateur $sam est déjà désactivé." -ForegroundColor Yellow
        }
    } else {
        Write-Host "L'utilisateur $sam n'existe pas." -ForegroundColor Red
    }
}
