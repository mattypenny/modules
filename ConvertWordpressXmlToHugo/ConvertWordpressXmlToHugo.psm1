# import-module Logging
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
  $wpxml = get-content D:\repair_websites\salisburywiltshireandstonehenge.wordpress.2015-10-03.xml
  convert-wpToHugo -WordpressXML $wpxml -PostString Road

.EXAMPLE

  $wpxml = get-content D:\repair_websites\salisburywiltshireandstonehenge.wordpress.2015-10-03.xml
  convert-wpToHugo -WordpressXML $wpxml -PostString finger -PostType Page
#>
  [CmdletBinding()]
  Param( [xml][Alias ("xml")]$WordpressXML = $wpxml,
         [string][Alias ("string")]$PostString = "MizMaze" ,
         [string][Alias ("f")]$ContentFolder = "D:\hugo\sites\example.com\content",
         [string][Alias ("type")]$PostType = "post",
         [string][Alias ("file")]$WordPressXMLFile,
         [switch]$ConvertFootnotes,
         [switch]$ConvertBlockquotes,
         [switch]$ConvertTables
) 

  
  write-startfunction 

  # todo error if both xml and file name passed in
  # todo call 

  $MatchingWordPressPosts = get-wpMatchingWordpressPosts -WordPressXml $WordPressXML -PostString $Poststring -type $PostType
  $MatchingWordPressPosts | measure-object

  foreach ($WordPressPost in $MatchingWordPressPosts)
  { 

    [String]$HugoFileName = get-wpHugoFileName -WordPressPostAsXML $WordPressPost -ContentFolder $contentFolder
    write-debug "`$HugoFileName: $HugoFileName"
    [string]$WordPressLink = $WordPressPost.link
    write-verbose "Creating $HugoFilename from $WordPressLink "

    
    [String]$HugoFrontMatter = get-wpHugoFrontMatterAsString -WordPressPostAsXML $WordPressPost
    write-debug "`$HugoFrontMatter: $HugoFrontMatter"

    [String]$PostBody = get-wpPostContentAsString -WordPressPostAsXML $WordPressPost

    # Convert self-referential URLs to relative URLs - take this out after testing
    $PostBody = $PostBody.replace("http://salisburyandstonehenge.net","")

    if ($ConvertBlockquotes)
    {
      $PostBody = convert-WordpressBlockquotesToMarkdown -PostBody $PostBody
    }

    if ($ConvertFootnotes)
    {
      $PostBody = convert-WordpressFootnotesToInternalLinks -HugoPageAsString $PostBody
    }

    if ($ConvertTables)
    {
      $PostBody = convert-WordpressWordpressTableToMarkdownTable -Content $PostBody
    }

    # todo: generate table of contents?
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
.Synopsis
   gets contents of xml file into an XML variable
.DESCRIPTION
   Very simple function - just does 'get-content' into an xml variable. Only a function because it's handy to run in isolation
.EXAMPLE
   Example of how to use this cmdlet
#>
function get-WordPressXMLFromWordPressXMLFile
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   Position=0)]
        $WordPressXMLFile = "D:\repair_websites\salisburywiltshireandstonehenge.wordpress.2015-10-03.xml" 

    )

    Process
    {
        [xml]$WordPressXML = get-content $WordPressXMLFile
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
  $Nodes = select-xml -xml $WordpressXML -xpath "//channel/item" | select -expandproperty node | where-object link -like "*$PostString*" | where-object post_type -eq $PostType

  
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
  write-debug "`$link: $link"
  [string]$category = $($link.split('/'))[3]
  write-debug "`$Category: $Category"
  <#
     Changing 'streetnames' to 'roadnames'. There are more roads than streets
     in Salisbury
  #>
  if ($category -eq 'streetnames')
  {
    $category = 'roadnames'
  }

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

  The xmlelement being passed in looks like this:

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
    Extract the elements of the XMLElemnt into variables
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

  

  <#
    Build the list of comma seperated tags, then knock off the last ", "
  #>
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
  if ($TagString.length)
  {
    $TagString = $TagString.substring(0, $TagString.length -2)
  }

  <#
    Extract the category from the URL
    my blog had the category as the second element of the URL i.e.
    http://salisburyandstonehenge/on-this-day/Beatles-play-the-City-Hall
  #>
  [string]$category = $($link.split('/'))[3]

  <#
    get the relative address for the Alias (Hugo redirection instruction)
  #>
  $DomainName = get-DomainNameFromURL $Link
  $RelativeAddress = $Link.replace($DomainName, '')

  if ($DomainName -eq 'http://salisburyandstonehenge.net')
  {
    <#
      This function is pretty specific to http://salisburyandstonehenge.net!
      The ordering of the on-this-day posts needs to be by the order of the 
      event in the calendar year. The year of the event and the date the
      post was published don't matter
    #>
    $weight = 0
    if ($category -eq 'on-this-day')
    {
      $weight = get-wpHugoWeightFromWpURL ($link)
    }

    <#
      Changing 'streetnames' to 'roadnames'. There are more roads than streets
      in Salisbury
    #>
    if ($category -eq 'streetnames')
    {
      $category = 'roadnames'
    }
  }
  
  <#
    format for date is YYYY-MM-DD. Hugo dpesn't like the time being there too
    setting lastmod to the date that this script was run
  #>
  [string]$lastmod = $(get-date -format "yyyy\-MM\-dd")
  [string]$date = "$($postdate.Substring(0,10))"
  [string]$draft = "No"
  [string]$publishdate = "$($postdate.substring(0, 10))"
  [string]$markup = "md"

  write-verbose "`$title: $title"
  write-debug "`$description: $description"
  write-debug "`$lastmod: $lastmod"
  write-debug "`$date: $date"
  write-debug "`$tagstring: $tagstring" 
  write-debug "`$category: $category"
  write-debug "`$RelativeAddress: $RelativeAddress"
  write-debug "`$draft: $draft"
  write-debug "`$publishdate: $publishdate"
  write-debug "`$weight: $weight"
  write-debug "`$markup: $markup"
  write-debug "`$Link: $Link"
  write-debug "`$TagString: $Tagstring"
  write-debug "`$RelativeAddress: $RelativeAddress"



  $YamlString = @"
title: "$title"
description: "$description"
lastmod: "$(get-date -format "yyyy\-MM\-dd")"
date: "$date"
tags: [ $tagstring ]
categories: 
 - "$category"
aliases: ["$RelativeAddress"]
draft: No
publishdate: "$publishdate"
weight: $weight
markup: "md"
url: $RelativeAddress
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

  $DebugPreference = "Continue"
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
  $DebugPreference = "SilentlyContinue"

  return $Weight

}

function get-DomainNameFromURL {
<#
.SYNOPSIS
  Converts month as word to month in number string

.PARAMETER FullAddress
  

.EXAMPLE
  

#>
  [CmdletBinding()]
  Param( [string][Alias ("url")]$FullAddress)

  write-startfunction 

  $FullAddressAsArray = $FullAddress.split('/')
  $Http = $FullAddressAsArray[0]
  $Domain = $FullAddressAsArray[2]
  $FullDomain = "$Http`/`/$Domain"
  write-debug "`$FullDomain: $FullDomain"
  
  write-endfunction 
  return $FullDomain

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
        "Jan" {"1"} 
        "January" {"1"} 
        "Feb" {"2"} 
        "February" {"2"} 
        "Mar" {"3"} 
        "March" {"3"} 
        "Apr" {"4"} 
        "April" {"4"} 
        "May" {"5"} 
        "Jun" {"6"} 
        "June" {"6"} 
        "Jul" {"7"} 
        "July" {"7"} 
        "Aug" {"8"} 
        "August" {"8"} 
        "Sep" {"9"} 
        "September" {"9"} 
        "Oct" {"10"} 
        "October" {"10"} 
        "Nov" {"11"} 
        "November" {"11"} 
        "Dec" {"12"} 
        "December" {"12"} 
        default {"Couldntmatchthemonth"}
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

.PARAMETER WordPressPostAsXml
  Contents of xml file read into an xml variable, then cut down I think???

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
  # write-debug "`$PostBody: $PostBody"

  write-endfunction 
  return $PostBody

}





function convert-WordpressBlockquotesToMarkdown {
<#
.SYNOPSIS
  Convert the <blockquote> syntax to the '>' syntax

.DESCRIPTION
  Longer description

.PARAMETER PostBody
  PostBody as a string

.EXAMPLE
  [string]$PostBody = gc D:\hugo\sites\example.com\content\on-this-day\1st-august-lammas-day-or-petersfinger-day.md
  convert-WordpressBlockquotesToMarkdown $PostBody

#>
  [CmdletBinding()]
  Param( [string]$PostBody,
         [string]$StartBlockQuoteTag = "<blockquote>",
         [string]$EndBlockQuoteTag = "</blockquote>")

  write-startfunction 

  write-debug "Length of `$postbody: $($PostBody.Length)"
  $ReturnString = ""
  
  $HugoPageAsArrayOfParagraphs = $PostBody -split "^|$StartBlockQuoteTag", 0, "multiline"

  write-debug "Number of items in `$HugoPageAsArrayofParagraphs: $($HugoPageAsArrayofParagraphs.length)"
  Foreach ($Line in $HugoPageAsArrayOfParagraphs) 
  {
    write-debug "Length of `$Line: $($Line.Length)"
    if ($Line -like "*$StartBlockQuoteTag*")
    {
      $BlockquoteOrNullString = "> "
    }
    elseif ($Line -like "*$EndBlockQuoteTag*")
    {
      $BlockquoteOrNullString = ""
    }

    $ReturnString = @"
$ReturnString
$BlockQuoteOrNullString$Line

"@

    write-debug "Length of `$ReturnString: $($ReturnString.Length)"
  }                 
  
  $ReturnString = $ReturnString.Replace($StartBlockQuoteTag, '')
  $ReturnString = $ReturnString.Replace($EndBlockQuoteTag, '')
 
  write-debug "Length of `$ReturnString: $($ReturnString.Length)"

  write-endfunction 
  return $ReturnString

}







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

#>
  [CmdletBinding()]
  Param( [string][Alias ("file")]$HugoMarkdownFile,
         [string][Alias ("HugoString")]$HugoPageAsString,
         [string][Alias ("Start")]$StartFootnoteTag = "<ref>",
         [string][Alias ("End")]$EndFootnoteTag = "</ref>")

  write-startfunction
  
  if ($HugoMarkDownFile -ne "")
  {
      $HugoPageAsString = get-content $HugoMarkdownFile -raw
  }
  
  $hugoPageAsString= $HugoPageAsString.replace($EndFootnoteTag, $StartFootnoteTag) 

  [array]$HugoPageAsArray = $HugoPageAsString -split "$StartFootNoteTag"

  write-debug "Number of bits of text is $($HugoPageAsArray.length)"
  $BodyString = ""
  $FootNoteString = "### Footnotes"

  for ($i = 0; $i -lt $HugoPageAsArray.length ; $i++)
  {
      [string]$ConcatenateString = $HugoPageAsArray[$i]
      if ( $i % 2 -eq 0 )
      {
          write-debug "Thats even $i"
          $BodyString = "$BodyString$ConcatenateString"
      }
      else
      {
          write-debug "Thats odd $i"
          $FootNoteNumber = 1 + (($i - 1 ) / 2) 
          write-debug "`$FootnoteNumber: $FootNoteNumber"

          $BodyString = @"
$BodyString<a name="Source$FootnoteNumber" href="#Note$FootnoteNumber">[$FootNoteNumber]</a>
"@

          $FootnoteString = @"
$FootNoteString

<a  href="#Source$FootnoteNumber" name=`"Note$FootnoteNumber`">`[$FootNoteNumber`]</a> $ConcatenateString
"@
      }
  }

  $ReconstitutedString = "$BodyString"
  if ($FootnoteString -ne "### Footnotes")
  {
      $ReconstitutedString = "$BodyString`n$FootNoteString"
  }

  if ($HugoMarkDownFile -ne "")
  {
      remove-item D:\hugo\sites\example.com\content\on-this-day\$HugoMarkdownFile
      set-content -LiteralPath $HugoMarkDownFile -value $ReconstitutedString
  }


  
  # set-content -value $HugoPageAsString -literalpath $HugoMarkdownFile
  write-endfunction
  return $ReconstitutedString
}

