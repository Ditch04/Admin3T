# Author: Loïc Dero & Dylan Feron

param($path, $delimiter=';')

# Charger le contenu CSV
$csvData = Import-Csv -Delimiter $delimiter -Path $path

# Parcourir chaque ligne du CSV
foreach ($entry in $csvData) {
    # Récupérer les informations nécessaires
    $username = $entry.Username

    # Rechercher l'utilisateur dans Active Directory
    $user = Get-ADUser -Filter {SamAccountName -eq $username} -Properties BadPwdCount,LockedOut

    # Vérifier si l'utilisateur a été trouvé
    if ($user) {
        # Vérifier si le compte utilisateur est verrouillé et a dépassé le nombre autorisé de tentatives de connexion échouées
        if ($user.LockedOut -and $user.BadPwdCount -ge 3) {
            # Débloquer le compte utilisateur
            Unlock-ADAccount -Identity $username
            Write-Host "Le compte utilisateur $username a été débloqué."
        } else {
            Write-Host "Le compte utilisateur $username n'est pas verrouillé ou n'a pas dépassé le nombre autorisé de tentatives de connexion échouées."
        }
    } else {
        Write-Host "Utilisateur $username non trouvé dans Active Directory."
    }
}

Write-Host "Déblocage des comptes utilisateur terminé."


#.\UnblockADUser.ps1 -path "C:\Chemin\vers\Votre\Fichier.csv"