#Cet script permet de créer des utilisateurs dans un domaine Active Directory à partir d'un fichier CSV.
# Le fichier CSV doit contenir les colonnes suivantes:
# userLogonNamefirstName,lastName,OU,securityGroup
# userLogonName: nom d'utilisateur (sans le domaine)
# firstName: prénom de l'utilisateur
# lastName: nom de famille de l'utilisateur
# OU: unité d'organisation dans laquelle l'utilisateur doit être créé
# securityGroup: groupe de sécurité auquel l'utilisateur doit appartenir
# Le script va créer un mot de passe aléatoire de 8 caractères pour chaque utilisateur et l'ajouter au groupe de sécurité spécifié.

# Exemple de fichier CSV:
# userLogonName,firstName,lastName,OU,securityGroup
# Loicdero,Loic,Dero,utilisateurs,etudiants
# Author: Loïc Dero & Dylan Feron

param($path, $delimiter=';', $exportFolder)
$exportPath = Join-Path $exportFolder ("Results_" + (Get-Date -Format "yyyy-MM-dd-HH-mm") + '.csv')

$csv = Import-Csv -Delimiter $delimiter -Path $path
$export = $csv | Select-Object *,@{Name="initialPassword";Expression={""}},@{Name="existsAlready";Expression={""}}

function Get-RandomPassword {
    param([int]$Length)
    $Numbers = 1..9
    $LettersLower = 'abcdefghijklmnopqrstuvwxyz'.ToCharArray()
    $LettersUpper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.ToCharArray()
    $Special = '!@#$%^&*();.,\'.ToCharArray()

    $N_Count = [math]::Round($Length * 0.2)
    $L_Count = [math]::Round($Length * 0.2)
    $U_Count = [math]::Round($Length * 0.2)
    $S_Count = [math]::Round($Length * 0.2)

    $psswrd = $LettersLower | Get-Random -Count $L_Count
    $psswrd += $LettersUpper | Get-Random -Count $U_Count
    $psswrd += $Numbers | Get-Random -Count $N_Count
    $psswrd += $Special | Get-Random -Count $S_Count

    if($psswrd.length -lt $Length){
        $psswrd += $Special | Get-Random -Count ($Length - $psswrd.length)
    }

    $psswrd = ($psswrd | Get-Random -Count $Length) -join ''
    return $psswrd
}

Write-Host "Results will be written to $exportPath"

$export | ForEach-Object {
    $user = $_
    $name = $user.firstName
    $surname = $user.lastName
    $group = $user.securityGroup
    $OU = $user.OU
    $samName = $user.userLogonName
    $UPN = "$samName@yourdomain.com"
    $exists = [bool](Get-ADUser -Filter {SamAccountName -eq $samName})

    if ($exists) {
        Write-Host "User $samName already exists" -ForegroundColor Red
        $user.initialPassword = 'N/A'
        $user.existsAlready = 'True'
    } else {
        $psswrd = Get-RandomPassword -Length 8
        $user.initialPassword = $psswrd
        $user.existsAlready = 'False'

        New-ADUser -SamAccountName $samName -UserPrincipalName $UPN -Name "$name $surname" -GivenName $name -Surname $surname -Enabled $true -Path "OU=$OU,DC=yourdomain,DC=com" -AccountPassword (ConvertTo-SecureString -AsPlainText $psswrd -Force)
        Add-ADGroupMember -Identity $group -Members $samName
        Write-Host "Creating user $samName with password: $psswrd" -ForegroundColor Green
    }
}

$export | Export-Csv -Path $exportPath -Delimiter $delimiter -NoTypeInformation
Write-Host "Script execution completed."
