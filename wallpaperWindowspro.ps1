#Open the folder en Windows Explorer under C:\Users\USERNAME\AppData\Roaming\CustomerXXXX
########################################################################################
$path = [Environment]::GetFolderPath('ApplicationData') + "\m88s-MS365"

 

If(!(test-path $path))
{
      New-Item -ItemType Directory -Force -Path $path
}
########################################################################################
#Download the image from ImGur to user profile
########################################################################################

 


$url = "https://gtestehmg.blob.core.windows.net/papeldeparede/Wallpaper1.jpg"
$output = $path + "\intune.jpg"
Start-BitsTransfer -Source $url -Destination $output

 

########################################################################################
# Update the background of the desktop
########################################################################################
# Code for settings TileStyle and Wallpaper Style
Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name wallpaperstyle -Value 6
Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name TileWallpaper -Value 1
Set-ItemProperty -path 'HKCU:\Control Panel\Desktop\' -name wallpaper -value $output

 

rundll32.exe user32.dll, UpdatePerUserSystemParameters

 

########################################################################################