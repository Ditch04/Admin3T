# Author: Loïc Dero & Dylan Feron 

param($path,$delimiter=',')

# Load CSV content
$csvData = Import-Csv -Delimiter $delimiter -Path $path

# Browse each line of the CSV
foreach ($entry in $csvData) {
    # Retrieve the necessary information
    $oldUsername = $entry.Username
    $newLastName = $entry.LastName
    $newFirstName = $entry.FirstName
    $newOU = $entry.OU
    $newSecurityGroup = $entry.SecurityGroup

    # Find user in Active Directory
    $user = Get-ADUser -Filter {SamAccountName -eq $oldUsername}

    # Check if the user has been found
    if ($user) {
        # Update user information
        Set-ADUser -Identity $oldUsername -Surname $newLastName -GivenName $newFirstName 
        
        # Move user to specified organizational unit
        if ($newOU) {
            Move-ADObject -Identity $user.DistinguishedName -TargetPath $newOU
        }

        # Add user to specified security group
        if ($newSecurityGroup) {
            Add-ADGroupMember -Identity $newSecurityGroup -Members $user
        }
        Write-Host "$oldUsername information has been updated."
    } else {
        Write-Host "User $oldUsername not found in Active Directory."
    }
}

Write-Host "User modification complete."
