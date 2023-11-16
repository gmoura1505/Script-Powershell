<# Conectar no ambiente #>
Connect-MgGraph -Scopes "User.ReadWrite.All","Group.ReadWrite.All"

<# Comando checa se a senha de um unico usuario esta definida para nunca expirar #>

Get-MGuser -UserId <user id or UPN> -Property UserPrincipalName, PasswordPolicies | Select-Object UserPrincipalName,@{
    N="PasswordNeverExpires";E={$_.PasswordPolicies -contains "DisablePasswordExpiration"}
}


<# Comando Checa se a configuraração Senha nunca expira para todos os usuario #>
Get-MGuser -All -Property UserPrincipalName, PasswordPolicies | Select-Object UserprincipalName,@{
    N="PasswordNeverExpires";E={$_.PasswordPolicies -contains "DisablePasswordExpiration"}
 }
 
 <# Para obter um relatÃ³rio de todos os usuÃ¡rios com PasswordNeverExpires no CSV na Area de trabalho do usuario atual com o nome ReportPasswordNeverExpires.csv
 Salva na area de trabalho com nome ReportPasswordNeverExpires #>
 Get-MGuser -All -Property UserPrincipalName, PasswordPolicies | Select-Object UserprincipalName,@{
    N="PasswordNeverExpires";E={$_.PasswordPolicies -contains "DisablePasswordExpiration"}
} | ConvertTo-Csv -NoTypeInformation | Out-File $env:userprofile\Desktop\ReportPasswordNeverExpires.csv


<# Para definir a senha de um usuario para nunca expirar #>
Update-MgUser -UserId <user ID> -PasswordPolicies DisablePasswordExpiration

<# Para definir a senha de todos os usuarios para nunca expirar #>
Get-MGuser -All | Update-MgUser -PasswordPolicies DisablePasswordExpiration

<# Para Definir a senha de um usuario para que a senha expire #>
Update-MgUser -UserId <user ID> -PasswordPolicies None


<# Para definir se a senha de todos os usuarios para expirar #>
Get-MGuser -All | Update-MgUser -PasswordPolicies None