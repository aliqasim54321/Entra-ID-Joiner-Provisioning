# ============================================================
# 02 - GROUPS & ADMINISTRATIVE UNITS
# ============================================================

$Domain = "<tenant>.onmicrosoft.com"

# ------------------------------------------------------------
# A. IAM Staff - PowerShell-driven attribute-based membership
# ------------------------------------------------------------

$IAMGroup = Get-MgGroup -Filter "displayName eq 'IAM Staff'"

if (-not $IAMGroup) {
    $IAMGroup = New-MgGroup `
        -DisplayName "IAM Staff" `
        -MailEnabled:$false `
        -MailNickname "iamstaff" `
        -SecurityEnabled:$true
}

$IAMUsers = Get-MgUser -All |
    Where-Object {
        $_.JobTitle -like "*IAM*" -or
        $_.JobTitle -like "*Identity*"
    }

$IAMMembers = Get-MgGroupMember -GroupId $IAMGroup.Id -All

foreach ($User in $IAMUsers) {
    if ($IAMMembers.Id -contains $User.Id) {
        Write-Host "SKIPPED: $($User.DisplayName) already in IAM Staff"
    }
    else {
        New-MgGroupMemberByRef `
            -GroupId $IAMGroup.Id `
            -BodyParameter @{
                "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$($User.Id)"
            }
        Write-Host "ADDED: $($User.DisplayName) -> IAM Staff"
    }
}

# ------------------------------------------------------------
# B. Cybersecurity Contractors group
# ------------------------------------------------------------

$CyberGroup = Get-MgGroup -Filter "displayName eq 'Cybersecurity Contractors'"

if (-not $CyberGroup) {
    $CyberGroup = New-MgGroup `
        -DisplayName "Cybersecurity Contractors" `
        -MailEnabled:$false `
        -MailNickname "cybersecuritycontractors" `
        -SecurityEnabled:$true
}

$Contractors = Get-MgUser -All |
    Where-Object {
        $_.Department -eq "Cybersecurity Contractors" -or
        $_.EmployeeType -eq "Contractor"
    }

$CyberMembers = Get-MgGroupMember -GroupId $CyberGroup.Id -All

foreach ($User in $Contractors) {
    if ($CyberMembers.Id -notcontains $User.Id) {
        New-MgGroupMemberByRef `
            -GroupId $CyberGroup.Id `
            -BodyParameter @{
                "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$($User.Id)"
            }
        Write-Host "ADDED: $($User.DisplayName) -> Cybersecurity Contractors"
    }
}

# ------------------------------------------------------------
# C. Administrative Unit example
# ------------------------------------------------------------

$AUName = "Security Contractors AU"
$AU = Get-MgDirectoryAdministrativeUnit -Filter "displayName eq '$AUName'"

if (-not $AU) {
    $AU = New-MgDirectoryAdministrativeUnit `
        -DisplayName $AUName `
        -Description "Administrative scope for lab security contractors"
}

$Aleksei = Get-MgUser -UserId "aleksei.volkov@$Domain"

New-MgDirectoryAdministrativeUnitMemberByRef `
    -AdministrativeUnitId $AU.Id `
    -BodyParameter @{
        "@odata.id" = "https://graph.microsoft.com/v1.0/users/$($Aleksei.Id)"
    }
