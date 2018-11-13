$Folders = foreach ($F in $(gci D:\OneDrive\ -directory -recurse ))
{
    $Folderfullname = $F.Fullname


    $Pics = $(gci -path "$Folderfullname\*" -include "*.jpg","*.png","*.jpeg","*.bmp" | measure-object).count

    

    if ($Pics -gt 0)
    {
        # [string]$Fullname = $F.Fullname
        [string]$Count = $Pics
        write-output "$Count : $FolderFullname"
    }
}