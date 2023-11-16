#Set Variables
$SiteURL= "https://arilabms365.sharepoint.com/sites/BGInfo"
$ListName="Documents"
  
#Connect to PnP Online
Connect-PnPOnline -Url $SiteURL -Interactive
 
#Get All Files from the document library - In batches of 500
$ListItems = Get-PnPListItem -List $ListName -PageSize 500 | Where {$_.FileSystemObjectType -eq "File"}
Write-host "Total Number of Files in the Folder:" $ListItems.Count -foregroundcolor Green
#Loop through all documents
$DocumentsData=@()
ForEach($Item in $ListItems)
{
    #Collect Documents Data
    $DocumentsData += New-Object PSObject -Property @{
    FileName = $Item.FieldValues['FileLeafRef']
    FileURL = $Item.FieldValues['FileRef']
    }
}
#sharepoint online get all files in document library powershell
$DocumentsData


#Read more: https://www.sharepointdiary.com/2018/08/sharepoint-online-powershell-to-get-all-files-in-document-library.html#ixzz8GUc15S1Y