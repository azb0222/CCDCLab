# Import the Active Directory module
Import-Module ActiveDirectory

$groupName = "Developers"
New-ADGroup -Name $groupName -GroupScope Global -Path "OU=Users,OU=umasscybersec,DC=umasscybersec,DC=com"

# Predefined lists of first and last names and passwords
$firstNames = @('James', 'Mary', 'John', 'Patricia', 'Robert', 'Jennifer', 'Michael', 'Linda', 'William', 'Elizabeth')
$lastNames = @('Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller', 'Davis', 'Rodriguez', 'Martinez')
$passwords = @(
    'f5XzCJEuC9$*NMG',
    'xWYG!Gd2X5vk4jf',
    'X2t$TtMGq8Kmy?T',
    '6m49*GvckYPJg@*',
    'dO6rs5N$oOh!Z8S',
    '?zT@hKkMX7$*iWv',
    '@ssCYZ7whaWGppd',
    '2!7uE8PKkkqVy5@',
    'CJZw*6FRsyJ*Nij',
    'wr@rhf*WpCod9dW'
)

# Generate 10 users and add them to the group
for ($i = 0; $i -lt 10; $i++) {
    $firstName = $firstNames[$i]
    $lastName = $lastNames[$i]
    $username = "$($firstName.Substring(0,1).ToLower())$lastName".ToLower().Replace(' ', '')
    $plainPassword = $passwords[$i]
    $password = ConvertTo-SecureString $plainPassword -AsPlainText -Force

    # Create new user
    New-ADUser -Name $username -GivenName $firstName -Surname $lastName -UserPrincipalName "$username@umasscybersec.com" -AccountPassword $password -Enabled $true -Path "OU=umasscybersec,DC=umasscybersec,DC=com"

    # Add user to group
    Add-ADGroupMember -Identity $groupName -Members $username

    # Output username and password
    Write-Output "Username: $username, Password: $plainPassword"
}

# Output the group members
Get-ADGroupMember -Identity $groupName


