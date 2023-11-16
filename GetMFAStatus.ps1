 <#
=============================================================================================
Nome:       Exportar relatario de status de MFA M365
Descrição: 	Este script exporta o relatório de status do Microsoft 365 MFA para CSV
Version:    1.0
Script:     William Marques

============================================================================================
#>
Param
(
    [Parameter(Mandatory = $false)]
    [switch]$DisabledOnly,
    [switch]$EnabledOnly,
    [switch]$EnforcedOnly,
    [switch]$ConditionalAccessOnly,
    [switch]$AdminOnly,
    [switch]$LicensedUserOnly,
    [Nullable[boolean]]$SignInAllowed = $null,
    [string]$UserName,
    [string]$Password
)
#Check for MSOnline module
$Modules=Get-Module -Name MSOnline -ListAvailable
if($Modules.count -eq 0)
{
  Write-Host  Please install MSOnline module using below command: `nInstall-Module MSOnline  -ForegroundColor yellow
  Exit
}

#Storing credential in script for scheduling purpose/ Passing credential as parameter
if(($UserName -ne "") -and ($Password -ne ""))
{
 $SecuredPassword = ConvertTo-SecureString -AsPlainText $Password -Force
 $Credential  = New-Object System.Management.Automation.PSCredential $UserName,$SecuredPassword
 Connect-MsolService -Credential $credential
}
else
{
 Connect-MsolService | Out-Null
}
$Result=""
$Results=@()
$UserCount=0
$PrintedUser=0

#Output file declaration
$ExportCSV=".\MFADisabledUserReport_$((Get-Date -format yyyy-MMM-dd-ddd` hh-mm` tt).ToString()).csv"
$ExportCSVReport=".\MFAEnabledUserReport_$((Get-Date -format yyyy-MMM-dd-ddd` hh-mm` tt).ToString()).csv"


#Loop through each user
Get-MsolUser -All | foreach{
 $UserCount++
 $DisplayName=$_.DisplayName
 $Upn=$_.UserPrincipalName
 $MFAStatus=$_.StrongAuthenticationRequirements.State
 $MethodTypes=$_.StrongAuthenticationMethods
 $RolesAssigned=""
 Write-Progress -Activity "`n     Processed user count: $UserCount "`n"  Currently Processing: $DisplayName"
 if($_.BlockCredential -eq "True")
 {
  $SignInStatus="False"
  $SignInStat="Denied"
 }
 else
 {
  $SignInStatus="True"
  $SignInStat="Allowed"
 }

 #Filter result based on SignIn status
 if(($SignInAllowed -ne $null) -and ([string]$SignInAllowed -ne [string]$SignInStatus))
 {
  return
 }

 #Filter result based on License status
 if(($LicensedUserOnly.IsPresent) -and ($_.IsLicensed -eq $False))
 {
  return
 }

 if($_.IsLicensed -eq $true)
 {
  $LicenseStat="Licensed"
 }
 else
 {
  $LicenseStat="Unlicensed"
 }

 #Check for user's Admin role
 $Roles=(Get-MsolUserRole -UserPrincipalName $upn).Name
 if($Roles.count -eq 0)
 {
  $RolesAssigned="No roles"
  $IsAdmin="False"
 }
 else
 {
  $IsAdmin="True"
  foreach($Role in $Roles)
  {
   $RolesAssigned=$RolesAssigned+$Role
   if($Roles.indexof($role) -lt (($Roles.count)-1))
   {
    $RolesAssigned=$RolesAssigned+","
   }
  }
 }

 #Filter result based on Admin users
 if(($AdminOnly.IsPresent) -and ([string]$IsAdmin -eq "False"))
 {
  return
 }

 #Check for MFA enabled user
 if(($MethodTypes -ne $Null) -or ($MFAStatus -ne $Null) -and (-Not ($DisabledOnly.IsPresent) ))
 {
  #Check for Conditional Access
  if($MFAStatus -eq $null)
  {
   $MFAStatus='Enabled via Conditional Access'
  }

  #Filter result based on EnforcedOnly filter
  if((([string]$MFAStatus -eq "Enabled") -or ([string]$MFAStatus -eq "Enabled via Conditional Access")) -and ($EnforcedOnly.IsPresent))
  {
   return
  }

  #Filter result based on EnabledOnly filter
  if(([string]$MFAStatus -eq "Enforced") -and ($EnabledOnly.IsPresent))
  {
   return
  }

  #Filter result based on MFA enabled via Other source
  if((($MFAStatus -eq "Enabled") -or ($MFAStatus -eq "Enforced")) -and ($ConditionalAccessOnly.IsPresent))
  {
   return
  }

  $Methods=""
  $MethodTypes=""
  $MethodTypes=$_.StrongAuthenticationMethods.MethodType
  $DefaultMFAMethod=($_.StrongAuthenticationMethods | where{$_.IsDefault -eq "True"}).MethodType
  $MFAPhone=$_.StrongAuthenticationUserDetails.PhoneNumber
  $MFAEmail=$_.StrongAuthenticationUserDetails.Email

  if($MFAPhone -eq $Null)
  { $MFAPhone="-"}
  if($MFAEmail -eq $Null)
  { $MFAEmail="-"}

  if($MethodTypes -ne $Null)
  {
   $ActivationStatus="Yes"
   foreach($MethodType in $MethodTypes)
   {
    if($Methods -ne "")
    {
     $Methods=$Methods+","
    }
    $Methods=$Methods+$MethodType
   }
  }

  else
  {
   $ActivationStatus="No"
   $Methods="-"
   $DefaultMFAMethod="-"
   $MFAPhone="-"
   $MFAEmail="-"
  }

  #Print to output file
  $PrintedUser++
  $Result=@{'DisplayName'=$DisplayName;'UserPrincipalName'=$upn;'MFAStatus'=$MFAStatus;'ActivationStatus'=$ActivationStatus;'DefaultMFAMethod'=$DefaultMFAMethod;'AllMFAMethods'=$Methods;'MFAPhone'=$MFAPhone;'MFAEmail'=$MFAEmail;'LicenseStatus'=$LicenseStat;'IsAdmin'=$IsAdmin;'AdminRoles'=$RolesAssigned;'SignInStatus'=$SigninStat}
  $Results= New-Object PSObject -Property $Result
  $Results | Select-Object DisplayName,UserPrincipalName,MFAStatus,ActivationStatus,DefaultMFAMethod,AllMFAMethods,MFAPhone,MFAEmail,LicenseStatus,IsAdmin,AdminRoles,SignInStatus | Export-Csv -Path $ExportCSVReport -Notype -Append
 }

 #Check for MFA disabled user
 elseif(($DisabledOnly.IsPresent) -and ($MFAStatus -eq $Null) -and ($_.StrongAuthenticationMethods.MethodType -eq $Null))
 {
  $MFAStatus="Disabled"
  $Department=$_.Department
  if($Department -eq $Null)
  { $Department="-"}
  $PrintedUser++
  $Result=@{'DisplayName'=$DisplayName;'UserPrincipalName'=$upn;'Department'=$Department;'MFAStatus'=$MFAStatus;'LicenseStatus'=$LicenseStat;'IsAdmin'=$IsAdmin;'AdminRoles'=$RolesAssigned; 'SignInStatus'=$SigninStat}
  $Results= New-Object PSObject -Property $Result
  $Results | Select-Object DisplayName,UserPrincipalName,Department,MFAStatus,LicenseStatus,IsAdmin,AdminRoles,SignInStatus | Export-Csv -Path $ExportCSV -Notype -Append
 }
}

#Open output file after execution
Write-Host `nScript executed successfully

if((Test-Path -Path $ExportCSV) -eq "True")
{
 Write-Host "MFA Disabled user report available in: $ExportCSV"
 Write-Host `nCheck out """AdminDroid Office 365 Reporting tool""" to get access to 950+ Office 365 reports.`n -ForegroundColor Green
 $Prompt = New-Object -ComObject wscript.shell
 $UserInput = $Prompt.popup("Do you want to open output file?",`
 0,"Open Output File",4)
 If ($UserInput -eq 6)
 {
  Invoke-Item "$ExportCSV"
 }
 Write-Host Exported report has $PrintedUser users
}
elseif((Test-Path -Path $ExportCSVReport) -eq "True")
{
 Write-Host "MFA Enabled user report available in: $ExportCSVReport"
 Write-Host `nCheck out """AdminDroid Office 365 Reporting tool""" to get access to 950+ Office 365 reports.`n -ForegroundColor Green
 $Prompt = New-Object -ComObject wscript.shell
 $UserInput = $Prompt.popup("Do you want to open output file?",`
 0,"Open Output File",4)
 If ($UserInput -eq 6)
 {
  Invoke-Item "$ExportCSVReport"
 }
 Write-Host Exported report has $PrintedUser users
}
Else
{
  Write-Host No user found that matches your criteria.
}
#Clean up session
Get-PSSession | Remove-PSSession

<# Exemplos de filtros:

 Como administrador do Office 365, muitas vezes voc� pergunta 'Como verificar se o MFA est� habilitado no escrit�rio 365'? A solu��o est� aqui. Usando o par�metro (EnabledOnly), voc� pode exportar usu�rios habilitados para MFA para arquivo CSV.

 ./GetMFAStatus.ps1 -EnabledOnly

 

Alguns usu�rios podem habilitar mfa mas n�o for�ados (processo de registro n�o conclu�do) para MFA. Voc� pode obter uma lista de usu�rios aplicados do MFA usando -EnforcedOnly .

 ./GetMFAStatus.ps1 -EnforcedOnly

  

O MFA fornece um n�vel adicional de seguran�a �s contas. Para exibir usu�rios com defici�ncia do MFA, voc� pode executar este script com -DisabledOnly .

 ./GetMFAStatus.ps1 -DisabledOnly

  

Como as contas administrativas t�m mais privil�gios, requer aten��o especial. De acordo com uma pesquisa recente, 78% dos administradores da Microsoft 365 n�o ativam o MFA para suas contas. Para encontrar administradores sem autentica��o multifatorial, execute o script usando �AdminOnly .

 ./GetMFAStatus.ps1 -AdminOnly -DisabledOnly

 

 Em vez de gerar relat�rio de status MFA para todos os usu�rios, voc� pode obter status MFA apenas para usu�rios licenciados. Voc� pode usar �LicensedUserOnly param para obter o status MFA dos usu�rios licenciados  

 

Para exibir o status de ativa��o do MFA para usu�rios licenciados,

./GetMFAStatus.ps1 -LicensedUserOnly

  

Para visualizar todos os usu�rios licenciados que n�o configuraram MFA,

./GetMFAStatus.ps1 -LicensedUserOnly -DisabledOnly

  

A maioria das organiza��es mant�m as contas dos ex-funcion�rios em um estado de defici�ncia. Ent�o, temos -SignInAllowed param, para filtrar o resultado com base no status SignIn,

Para visualizar o login permitido usu�rios sem MFA

./GetMFAStatus.ps1 -SignInAllowed $True -DisabledOnly

Para listar usu�rios de login negados com MFA,

./GetMFAStatus.ps1 -SignInAllowed $False

 

Nota:

 Voc� pode usar v�rios filtros juntos para obter um relat�rio de status MFA mais granular. Por exemplo:

 Voc� pode obter uma lista de usu�rios habilitados para status MFA cujo status sign-in � negado.

 ./GetMFAStatus.ps1 -EnabledOnly �SignInAllowed $False

    Voc� pode obter uma lista de usu�rios de administra��o desativados do MFA cujo status sign-in � permitido.

 ./GetMFAStatus.ps1 -DisabledOnly �AdminOnly �SignInAllowed $True 
 
 #>