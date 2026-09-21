# ============================================================
# 01 - JOINER: BULK ONBOARDING FROM CSV
# ============================================================
# Replace placeholders before running.
# Never commit real passwords, tokens, or secrets to GitHub.

$TenantId = "<TENANT-ID>"
$Domain   = "<tenant>.onmicrosoft.com"
$CsvPath  = ".\Day1_CybersecContractors_Joiners.csv"

Connect-MgGraph `
    -TenantId $TenantId `
    -Scopes "User.ReadWrite.All","Group.ReadWrite.All","Domain.Read.All" `
    -ContextScope Process

$Users = Import-Csv $CsvPath

foreach ($Row in $Users) {

    # Convert source CSV UPN to the current lab tenant domain.
    $Alias  = ($Row.UserPrincipalName -split "@")[0]
    $NewUPN = "$Alias@$Domain"

    # Skip if the account already exists.
    $ExistingUser = Get-MgUser -Filter "userPrincipalName eq '$NewUPN'" -ErrorAction SilentlyContinue

    if ($ExistingUser) {
        Write-Host "SKIPPED: $NewUPN already exists"
        continue
    }

    # Use a secure temporary-password workflow in production.
    $PasswordProfile = @{
        Password = "<TEMP-PASSWORD>"
        ForceChangePasswordNextSignIn = $true
    }

    $Params = @{
        AccountEnabled    = $true
        DisplayName       = $Row.DisplayName
        GivenName         = $Row.FirstName
        Surname           = $Row.LastName
        UserPrincipalName = $NewUPN
        MailNickname      = $Alias
        JobTitle          = $Row.JobTitle
        Department        = $Row.Department
        EmployeeType      = $Row.EmployeeType
        UsageLocation     = $Row.UsageLocation
        PasswordProfile   = $PasswordProfile
    }

    try {
        $NewUser = New-MgUser -BodyParameter $Params -ErrorAction Stop
        Write-Host "CREATED: $($NewUser.DisplayName) -> $NewUPN"
    }
    catch {
        Write-Host "FAILED: $NewUPN"
        Write-Host $_.Exception.Message
    }
}

# Verification
Get-MgUser -All |
    Where-Object { $_.UserPrincipalName -like "*@$Domain" } |
    Select-Object DisplayName,UserPrincipalName,JobTitle,Department,AccountEnabled
