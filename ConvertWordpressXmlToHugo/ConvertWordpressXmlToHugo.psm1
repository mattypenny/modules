import-module Logging
function  convert-wpToHugo{ 
<#
.SYNOPSIS
  One-line description

.DESCRIPTION
  Longer description

.PARAMETER WordpressXML
  The wordpress content imported into an xml variable

.PARAMETER PostString
  The wordpress content imported into an xml variable

.PARAMETER PostType
  The type as returned from WordPress, which in my install is one of:`
    attachment   
    nav_menu_item
    page         
    post      

.EXAMPLE
  Example of how to use this cmdlet

#>
  [CmdletBinding()]
  Param( [xml][Alias ("xml")]$WordpressXML = "$wp_xml",
         [string][Alias ("string")]$PostString = "ramone" ,
         [string][Alias ("f")]$ContentFolder = "D:\hugo\sites\example.com\content",
         [string][Alias ("type")]$PostType = "post"
) 

  
  write-startfunction 

  $MatchingWordPressPosts = get-wpMatchingWordpressPosts -WordPressXml $WordPressXML -PostString $Poststring -type $PostType

  foreach ($WordPressPost in $MatchingWordPressPosts)
  { 

    [String]$HugoFileName = get-wpHugoFileName -WordPressPostAsXML $WordPressPost -ContentFolder $contentFolder
    write-debug "`$HugoFileName: $HugoFileName"
    [string]$WordPressLink = $WordPressPost.link
    write-verbose "Converting $WordPressLink to $HugoFilename"

    
    [String]$HugoFrontMatter = get-wpHugoFrontMatterAsString -WordPressPostAsXML $WordPressPost
    write-debug "`$HugoFrontMatter: $HugoFrontMatter"

    [String]$PostBody = get-wpPostContentAsString -WordPressPostAsXML $WordPressPost

    if ($ConvertFootnotes)
    {
      $PostBody = convert-WordpressFootnotesToInternalLinks -Content $PostBody
    }

    if ($ConvertWordpressTableToMarkdownTable)
    {
      $PostBody = convert-WordpressWordpressTableToMarkdownTable -Content $PostBody
    }

    if ($FlagLink)
    {
      $Links = get-wpLinks $PostBody
    }

    # Todo: if file exists back it up?
    
    [string]$HugoPostString = @"
---
$HugoFrontMatter
---
$PostBody
"@
                          
    # write-debug "out-file -InputObject $HugoPostString -FilePath $HugoFileName"
    out-file -InputObject $HugoPostString -FilePath $HugoFileName -encoding default

    write-endfunction 

  }

}


<#
vim: tabstop=2 softtabstop=2 shiftwidth=2 expandtab
#>


function get-wpMatchingWordpressPosts { 
<#
.SYNOPSIS
  Get Matching Wordpress posts

.DESCRIPTION


.PARAMETER WordpressXML
  The wordpress content imported into an xml variable

.PARAMETER PostString
  The wordpress content imported into an xml variable

.EXAMPLE
  get-WordpressPostMetadata -poststring moberly | where-object post_type -eq 'post' 

title          : Moberly Road, Salisbury
link           : http://salisburyandstonehenge.net/streetnames/moberly-road-salisbury
pubDate        : Sat, 01 Aug 2009 20:27:56 +0000
creator        : creator
guid           : guid
description    : 
encoded        : {content:encoded, excerpt:encoded}
post_id        : 1149
post_date      : 2009-08-01 20:27:56
post_date_gmt  : 2009-08-01 20:27:56
comment_status : open
ping_status    : open
post_name      : moberly-road-salisbury
status         : publish
post_parent    : 0
menu_order     : 0
post_type      : post
post_password  : 
is_sticky      : 0
category       : {category, category, category, category...}
postmeta       : {wp:postmeta, wp:postmeta, wp:postmeta, wp:postmeta...}
comment        : {wp:comment, wp:comment, wp:comment, wp:comment...}

#>
  [CmdletBinding()]
  Param( [xml][Alias ("xml")]$WordpressXML = "$wp_xml",
         [string][Alias ("string")]$PostString = "ramone",
         [string][Alias ("Type")]$PostType = "post") 

  

  <#
    select-xml -xml $wp_xml -xpath "//channel/item" | 
    select -expandproperty node | 
    where post_type -ne "attachment" |
    where title -like "*January*" | 
    select -ExpandProperty encoded | fl
  #>

  # [xml]$wp_xml = get-content wp_exp.xml
  $Nodes = select-xml -xml $WordpressXML -xpath "//channel/item" | select -expandproperty node | where-object title -like "*$PostString*" | where-object post_type -eq $PostType

  
  $nodes

  write-endfunction 

}



function get-wpHugoFileName { 
<#
.SYNOPSIS
  One-line description

.DESCRIPTION
  Longer description
  Todo: Could think about putting the category name in here?

.PARAMETER WordpressPostAsXml
  One wordpress post as xml

.PARAMETER ContentFolder
  Folder where the markdown-ed posts are going to go

.EXAMPLE
  Example of how to use this cmdlet

.EXAMPLE
  Another example of how to use this cmdlet
#>
  [CmdletBinding()]
  Param( [system.xml.xmlelement][Alias ("x")]$WordpressPostAsXml,
         [string][Alias ("f")]$ContentFolder = "c:\temp" )

  write-startfunction 
  
  [string]$postname       = $WordpressPostAsXml.post_name     
  write-debug "`$postname: $postname"

  [string]$link = $WordpressPostAsXml.link     
  [string]$category = $($link.split('/'))[3]
  write-debug "`$Category: $Category"

  [string]$FileName = $ContentFolder + '\' + $Category + '\' + $postname + '.md'
  write-debug "`$Filename: $Filename"

  write-endfunction 
  return $Filename

}


function get-wpHugoFrontMatterAsString { 
<#
.SYNOPSIS
  One-line description

.DESCRIPTION
  This is from the help for the Hugo front matter:

  Required variables
    title           - As it appears on screen   
    description     - not sure how this is used
    date            - for sorting
    taxonomies      - These will use the field name of the plural form of the index ??

  Optional variables
    aliases         - An array of one or more aliases (e.g. old published path of a renamed content) that would be created to redirect to this content. 
    draft           - If true, the content will not be rendered unless hugo is called with --buildDrafts
    publishdate     - If in the future, content will not be rendered unless hugo is called with --buildFuture
    type            - ?? The type of the content (will be derived from the directory automatically if unset)
    isCJKLanguage   - If true, explicitly treat the content as CJKLanguage ??
    weight          - Used for sorting
    markup          - (Experimental) Specify "rst" for reStructuredText (requires rst2html) or "md" (default) for Markdown
    slug            - The token to appear in the tail of the URL, or
    url             - The full path to the content from the web root. If neither slug or url is present, the filename will be used.

  YAML example
    ---
    title: "spf13-vim 3.0 release and new website"
    description: "spf13-vim is a cross platform distribution of vim plugins and resources for Vim."
    tags: [ ".vimrc", "plugins", "spf13-vim", "vim" ]
    lastmod: 2015-12-23
    date: "2012-04-06"
    categories:
      - "Development"
      - "VIM"
    slug: "spf13-vim-3-0-release-and-new-website"
    ---

    Content of the file goes Here



  Todo: decide whether to use the front matter for anything else e.g. todo


.PARAMETER folder
  Folder 

.EXAMPLE
  Example of how to use this cmdlet

.EXAMPLE
  Another example of how to use this cmdlet
#>
  [CmdletBinding()]
  Param( [system.xml.xmlelement][Alias ("x")]$WordpressPostAsXml   ) 

  write-startfunction 
  <#
  title          : Moberly Road, Salisbury
  link           : http://salisburyandstonehenge.net/streetnames/moberly-road-salisbury
  pubDate        : Sat, 01 Aug 2009 20:27:56 +0000
  creator        : creator
  guid           : guid
  description    : 
  encoded        : {content:encoded, excerpt:encoded}
  post_id        : 1149
  post_date      : 2009-08-01 20:27:56
  post_date_gmt  : 2009-08-01 20:27:56
  comment_status : open
  ping_status    : open
  post_name      : moberly-road-salisbury
  status         : publish
  post_parent    : 0
  menu_order     : 0
  post_type      : post
  post_password  : 
  is_sticky      : 0
  category       : {category, category, category, category...}
  postmeta       : {wp:postmeta, wp:postmeta, wp:postmeta, wp:postmeta...}
  comment        : {wp:comment, wp:comment, wp:comment, wp:comment...}
  #>


  $attachmenturl  = $WordpressPostAsXml.attachment_url
  $commentstatus  = $WordpressPostAsXml.comment_status
  $creator        = $WordpressPostAsXml.creator       
  $description    = $WordpressPostAsXml.description   
  $encoded        = $WordpressPostAsXml.encoded       
  $guid           = $WordpressPostAsXml.guid          
  $issticky       = $WordpressPostAsXml.is_sticky     
  $link           = $WordpressPostAsXml.link          
  $menuorder      = $WordpressPostAsXml.menu_order    
  $pingstatus     = $WordpressPostAsXml.ping_status   
  $postmeta       = $WordpressPostAsXml.postmeta      
  $postdate       = $WordpressPostAsXml.post_date     
  $postdategmt    = $WordpressPostAsXml.post_date_gmt 
  $postid         = $WordpressPostAsXml.post_id       
  $postname       = $WordpressPostAsXml.post_name     
  $postparent     = $WordpressPostAsXml.post_parent   
  $postpassword   = $WordpressPostAsXml.post_password 
  $posttype       = $WordpressPostAsXml.post_type     
  $pubDate        = $WordpressPostAsXml.pubDate       
  $status         = $WordpressPostAsXml.status        
  $title          = $WordpressPostAsXml.title   

  $Tags = $WordPressPostAsXml | select category | select -ExpandProperty category | 
            ? domain -eq 'post_tag' | select nicename 
            select nicename 

  [string]$TagString = ""
  foreach ($T in $Tags)
  {
    write-debug "`$Tag: $Tag"
    [string]$Tag = $T.nicename
    $TagString = "$Tagstring `"$Tag`", "  
  }
  write-debug "`$TagString: $Tagstring"

  # my blog had the category as the second element of the URL i.e.
  # http://salisburyandstonehenge/on-this-day/Beatles-play-the-City-Hall
  [string]$category = $($link.split('/'))[3]

  # This function is pretty specific to http://salisburyandstonehenge.net!
  if ($category -eq 'on-this-day')
  {
    $weight = get-wpHugoWeightFromWpURL ($link)
  }

  # the alias has to be a relative address
  $LinkAsArray = $link.split('/')
  $DomainName = "$LinkAsArray[0]//$LinkAsArray[2]"
  $Alias = $Link.replace($DomainName, '')
  write-debug "`$Alias: $Alias"

  [string]$category = $($link.split('/'))[3]
  

  # using all the available metadata, except 'type' as I'm not having different types
  # of content
  $YamlString = @"
title: "$titleh
description: "$description"
lastmod: "$(get-date -format "yyyy\-MM\-dd")"
date: "$($postdate.Substring(0,10))"
tags: [ $tagstring ]
categories:
- "$category"
aliases: ["$Alias"]
draft: No
publishdate: "$postdate"
weight: 0
markup: "md"
url: $Alias
"@
 
  # write-debug "`$YamlString: $YamlString"

  write-endfunction 
  return $YamlString

}




function get-wpHugoWeightFromWpURL { 
<#
.SYNOPSIS
  Derives the Hugo 'weight' metadata from a URL which has a date at the start of the title

.DESCRIPTION
  My Wordpress blog had a series of 'on this day' pages. The pages were in the 
  format:

  'http://whatever/whatever/3rd-May-1998-whatever' or
  
  'http://whatever/whatever/3rd-May-whatever'

  In Wordpress I the used ?? to order the pages within a list of the 'on this day'
  pages. The ?? had a number in the format MMDD.

  As far as I can see, this ?? field isn't included in the XML export, so this 
  function is re-deriving it from the title.

.PARAMETER WordPressURL
  The URL of the post

.EXAMPLE
  get-wpHugoWeightFromWpURL http://salisburyandstonehenge.net/on-this-day/april/1st-april-1899-the-automobile-club-visit-stonehenge
  0401

.EXAMPLE
  For testing, this is good:

  foreach ($L in get-wpMatchingWordpressPosts -x $WpXml -string "*" | where-object post_type -eq 'page' | select link) { $Link = $L.link ; "$(get-wpHugoWeightFromWpURL -url $Link) $Link"}
#>
  [CmdletBinding()]
  Param( [string][Alias ("url")]$WordpressUrl   ) 

  write-startfunction 

  write-debug "`$WordPressUrl: $WordpressURL"

  $URLAsArray = $WordPressURL.split('/')
  
  [int]$NumberOfElements = $URLAsArray.length
  write-debug "`$NumberOfElements: $NumberOfElements"
  
  [string]$UrlBasename = $URLAsArray[$URLAsArray.length - 1 ]
  write-debug "`$UrlBaseName: $UrlBaseName"

  $UrlBaseNameAsArray = $UrlBaseName.split('-')

  $DayOfMonth = $UrlBaseNameAsArray[0]

  $Month = $UrlBaseNameAsArray[1]

  $3rdElement = $UrlBaseNameAsArray[2]
  
  write-debug "`$DayOfMonth `$Month `$3rdElement: $DayOfMonth $Month $3rdElement" 

  $MonthAsNumber = convert-monthToNumberString ($month)
  write-debug "`$MonthAsNumber: $MonthAsNumber"
 
  $DayOfMonthAsNumber = $DayOfMonth.replace('r','')
  $DayOfMonthAsNumber = $DayOfMonthAsNumber.replace('d','')
  $DayOfMonthAsNumber = $DayOfMonthAsNumber.replace('s','')
  $DayOfMonthAsNumber = $DayOfMonthAsNumber.replace('t','')
  $DayOfMonthAsNumber = $DayOfMonthAsNumber.replace('h','')
  $DayOfMonthAsNumber = $DayOfMonthAsNumber.replace('n','')
  write-debug "`$DayOfMonthAsNumber: $DayOfMonthAsNumber"
 
  if ($DayOfMonthAsNumber.length -lt 2)
  {
    $DayofMonthAsNumber = "0$DayOfMonthAsNumber"
  }
  write-debug "`$DayOfMonthAsNumber: $DayOfMonthAsNumber"
  
  [string]$Weight = "$MonthAsNumber$DayOfMonthAsNumber"
  write-debug "`$Weight: $Weight"

  write-endfunction 

  return $Weight

}

function convert-monthToNumberString { 
<#
.SYNOPSIS
  Converts month as word to month in number string

.PARAMETER MonthAsWord
  Either the full month or the abbreviation

.EXAMPLE
  convert-MonthToNumberString

#>
  [CmdletBinding()]
  Param( [string][Alias ("m")]$MonthAsWord,
         $ILoveYouYouDummy  ) 

  write-startfunction 



  write-debug "`$MonthAsWord: $MonthAsWord"

  # tried to do this with switch -regex, but it didn't work
  [string]$MonthAsNumber = switch ($MonthAsWord)
  { 
        "Jan" {"01"} 
        "January" {"01"} 
        "Feb" {"02"} 
        "February" {"02"} 
        "Mar" {"03"} 
        "March" {"03"} 
        "Apr" {"04"} 
        "April" {"04"} 
        "May" {"05"} 
        "Jun" {"06"} 
        "June" {"06"} 
        "Jul" {"07"} 
        "July" {"07"} 
        "Aug" {"08"} 
        "August" {"08"} 
        "Sep" {"09"} 
        "September" {"09"} 
        "Oct" {"10"} 
        "October" {"10"} 
        "Nov" {"11"} 
        "November" {"11"} 
        "Dec" {"12"} 
        "December" {"12"} 
        default {"Couldnt match the month"}
  }
   

  write-endfunction 
  return $MonthAsNumber

}


function get-wpPostContentAsString { 
<#
.SYNOPSIS
  One-line description

.DESCRIPTION
  Longer description

.PARAMETER folder
  Folder 

.EXAMPLE
  Example of how to use this cmdlet

.EXAMPLE
  Another example of how to use this cmdlet
#>
  [CmdletBinding()]
  Param( [system.xml.xmlelement][Alias ("x")]$WordpressPostAsXml   ) 

  write-startfunction 

  $Encoded = $WordpressPostAsXml | select -expandproperty encoded       
  # write-debug "`$Encoded"

  [string]$PostBody = $Encoded | select -expandproperty `#cdata-section 
  # write-debug "`$PostBody"

  write-endfunction 
  return $PostBody

}





<#
vim: tabstop=2 softtabstop=2 shiftwidth=2 expandtab
#>



function convert-WordpressFootnotesToInternalLinks { 
<#
.SYNOPSIS
  One-line description

.DESCRIPTION
  Longer description

.PARAMETER folder
  Folder 

.EXAMPLE
  Example of how to use this cmdlet

.EXAMPLE
  Another example of how to use this cmdlet
#>
  [CmdletBinding()]
  Param( [string][Alias ("f")]$PostAsString = "$pwd"  ) 

  write-startfunction 



  write-endfunction 

}

set-alias temp get-template


<#
vim: tabstop=2 softtabstop=2 shiftwidth=2 expandtab
#>




function convert-WordpressWordpressTableToMarkdownTable  { 
<#
.SYNOPSIS
  One-line description

.DESCRIPTION
  Longer description

.PARAMETER folder
  Folder 

.EXAMPLE
  Example of how to use this cmdlet

.EXAMPLE
  Another example of how to use this cmdlet
#>
  [CmdletBinding()]
  Param( [string][Alias ("f")]$MarkdownPost = ""  ) 

  write-startfunction 



  write-endfunction 

}







function get-wpLinks { 
<#
.SYNOPSIS
  One-line description

.DESCRIPTION
  Longer description

.PARAMETER folder
  Folder 

.EXAMPLE
  Example of how to use this cmdlet

.EXAMPLE
  Another example of how to use this cmdlet
#>
  [CmdletBinding()]
  Param( [string][Alias ("h")]$PostBody = ""  ) 

  write-startfunction 




  write-endfunction 

}

<#
vim: tabstop=2 softtabstop=2 shiftwidth=2 expandtab ignorecase
#>



