$DebugPreference = "Continue"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
remove-module PowerHugo 
import-module PowerHugo 
$TestData = join-path -path $here -childpath "pesterdata"
$TMPNAME = 'tmp'
$TEMP = join-path -path "$ENV:HOME" -childPath $TMPNAME

# . "$here\$sut"


$HugoContentFolder = join-path "." "PesterData"

Describe "get-HugoNameAndFirstLineValue" {
    It "returns name and value for a valid line" {
        $Hugo = get-HugoNameAndFirstLineValue -FrontMatterLine "Weight: 103"
        $value = $Hugo.PropertyValue
        $value | Should Be '103'
        # "103" | Should Be '103'
        # $Hugo.value | Should Be '103'
    }

}

<#
title: "10th June 1668 - Samuel Pepys visits Salisbury"
description: ""
lastmod: "2016-06-07"
date: "2013-11-29"
tags: [  ]
categories: 
 - "on-this-day"
aliases: ["/on-this-day/june/10th-june-1668-samuel-pepys-visits-salisbury"]
draft: No
publishdate: "2013-11-29"
weight: 610
markup: "md"
url: /on-this-day/june/10th-june-1668-samuel-pepys-visits-salisbury
#>

Describe "get-HugoContent for a single file" {
    
    $HugoContent = get-HugoContent -f $TestData\10th-june-1668-samuel-pepys-visits-salisbury.md

    It "returns title" {
        $title = $HugoContent.title
        $title | Should Be '10th June 1668 - Samuel Pepys visits Salisbury'
    }

    It "returns description" {
        $description = $HugoContent.description
        $description | Should Be ''
    }


    It "returns lastmod" {
        $lastmod = $HugoContent.lastmod
        $lastmod | Should Be '2016-06-07'
    }

    It "returns date" {
        $date = $HugoContent.date
        $date | Should Be '2013-11-29'
    }

    It "returns tags" {
        $tags = $HugoContent.tags
        $tags[0] | Should be "pepys"

        $tags[1] | Should be "literary"
        $tags[2] | Should be "visitors"
        $tags[3] | Should be "old george mall"
        $tags[4] | Should be "high street"

        
    }

    It "returns categories" {
        $categories = $HugoContent.categories
        $ExpectedCategories = @("on-this-day", "june", "diaries and things", "dummy")
        $Comparison = Compare-Object $categories $ExpectedCategories
        $Comparison.InputObject | Should Be "dummy"
        $Comparison.SideIndicator | Should Be "=>"
    }

    It "returns aliases" {
        $Content = $HugoContent.aliases
        $ExpectedContent = @("/on-this-day/june/10th-june-1668-samuel-pepys-visits-salisbury", "/about-Pepys-and-Salisbury", "dummy")
        $Comparison = Compare-Object $Content $ExpectedContent
        $Comparison.InputObject | Should Be "dummy"
        $Comparison.SideIndicator | Should Be "=>" 
    }

    It "returns draft" {
        $draft = $HugoContent.draft
        $draft | Should Be 'No'
    }

    It "returns publishdate" {
        $publishdate = $HugoContent.publishdate
        $publishdate | Should Be '2013-11-29'
    }

    It "returns weighting" {
        $Weight = $HugoContent.Weight
        $Weight | Should Be '610'
    }

    It "returns markup" {
        $markup = $HugoContent.markup
        $markup | Should Be 'Md'
    }

    It "returns url" {
        $url = $HugoContent.url
        $url | Should Be '/on-this-day/june/10th-june-1668-samuel-pepys-visits-salisbury'
    }
<#
    It "returns body" {
        [string]$ExpectedBody = get-content $TestData\Pepys-Body.txt
        [string]$body = $HugoContent.body
        $BodyFirst = $Body.Substring(1,10)
        $ExpectedBodyFirst = $ExpectedBody.Substring(1,10)

        $bodyFirst | Should Be $ExpectedBodyFirst
    }

    It "returns links" {
        $links = $HugoContent.links
        $links | Should Be ''
    }

    It "returns images" {
         
        $images | Should Be '610'
    }
    <#
    #>
}

Describe "get-HugoContent for multiple file" {
    
    $HugoContent = get-HugoContent -f $TestData\10th-june-1668-samuel-pepys-visits-salisbury.md

    It "returns title" {
        $title = $HugoContent.title
        $title | Should Be '10th June 1668 - Samuel Pepys visits Salisbury'
    }
}

Describe "get-HugoValueArrayFromString" {
    It "returns an array of values from a comma seperated list of tags when there are many values" {
        $HugoValueArray = get-HugoValueArrayFromString -MultipleValueString '[ "pepys", "literary", "visitors"," old george mall", "high street" ]'
        $HugoValueArray.count | Should be 5
        $HugoValueArray[0] | Should be "pepys"
        $HugoValueArray[1] | Should be "literary"
        $HugoValueArray[2] | Should be "visitors"
        $HugoValueArray[3] | Should be "old george mall"
        $HugoValueArray[4] | Should be "high street"
        
    }
    It "returns an array of values from a dash seperated list of tags when there are many values" {
        $HugoValueArray = get-HugoValueArrayFromString -DElimiter '-' -MultipleValueString '- "roadname" - "onthisday" - "stonehengeseverywhere" -"unknown"'
        $HugoValueArray.count | Should be 4
        $HugoValueArray[0] | Should be "roadname"
        $HugoValueArray[1] | Should be "onthisday"
        $HugoValueArray[2] | Should be "stonehengeseverywhere"
        $HugoValueArray[3] | Should be "unknown"
        
    }
        It "returns one value from a comma seperated list of tags when there is only one value" {
        $HugoValueArray = get-HugoValueArrayFromString -MultipleValueString '[ "pepys", ]'
        $HugoValueArray | Should be "pepys"
        
    }
        It "returns one value when the string is just one word, with no comma seperation" {
        $HugoValueArray = get-HugoValueArrayFromString -MultipleValueString '[ "pepys" ]'
        $HugoValueArray | Should be "pepys"
        
    }
        It "returns one value when the string is just one word, with no comma seperation and no brackets" {
        $HugoValueArray = get-HugoValueArrayFromString -MultipleValueString ' "pepys" '
       $HugoValueArray | Should be "pepys"
        
    }
        It "should not throw an error when the string is blank" {
        {get-HugoValueArrayFromString -MultipleValueString '  '} | Should Not Throw
       
        
    }

        It "returns nothing when the string is blank" {
        $HugoValueArray = get-HugoValueArrayFromString -MultipleValueString '  '
        $HugoValueArray.count | Should be 0
        $HugoValueArray | Should benullOrEmpty
        
    }

}

Describe "get-HugoContent for multiple files" {
    
    
    
        

    It "returns title" {
        $HugoTitles = get-HugoContent -f $TestData\*.md | select title
        
        $ExpectedTitles = @("10th August 1901 - Miss Moberly meets Marie Antoinette",               
                            "10th June 1668 - Samuel Pepys visits Salisbury",                      
                            "15th June 1786 - Matcham meets 'the Dead Drummer', possibly",          
                            "1st May 472 - the 'Night of the Long Knives' at Amesbury",             
                            "3rd June 1977 - the Ramones visit Stonehenge. Johnny stays on the bus"
                             )
        $ExpectedTitles
        $Comparison = Compare-Object $HugoTitles.title $ExpectedTitles
    
        $Comparison.InputObject | Should Be "Elvis Presley visits Salisbury (this is a test)"
        $Comparison.SideIndicator | Should Be "<=" 
    
    }
}

Describe "get-HugoContent for a single file - body processing" {
    
    $HugoContent = get-HugoContent -f $TestData\10th-june-1668-samuel-pepys-visits-salisbury.md
    [string]$ExpectedBody = get-content -encoding default $TestData\Pepys-Body.txt
    [string]$body = $HugoContent.body

    It "returns the first 10 characters" {
        
        $BodyFirst = $Body.Substring(0,10)
        
        $ExpectedBodyFirst = $ExpectedBody.Substring(0,10)
        write-host "`$BodyFirst <$BodyFirst> `$ExpectedBodyFirst <$ExpectedBodyFirst>"
        $bodyFirst | Should Be $ExpectedBodyFirst
    }
    It "returns the first character" {
        
        [byte][char]$Body[0] | Should Be $([byte][char]$ExpectedBody[0])
    }
    It "returns about the same length" {
        
        $BodyLength = $Body.length
        $ExpectedBodyLength = $ExpectedBody.length
        $bodyLength | Should BeGreaterThan $($ExpectedBodyLength -30)
        $bodyLength | Should BeLessThan $($ExpectedBodyLength +30)

    }

}

Describe "set-HugoContent backs up an existing file" {
    It "creates a backup copy of the existing file" {
 
        $Now = get-date -uformat "%Y%m%d%H%M"
        
        $HugoParameters = @{
            HugoMarkdownFile = "/tmp/markdown_file.md"
            aliases = 'xx'
            body = 'xx'
            categories = 'xx'
            date = 'xx'
            description = 'xx'
            draft = 'xx'
            lastmod = 'xx'
            markup = 'xx'
            publishdate = 'xx'
            tags = "hippy","wiltshire","stonehenge"
            title = 'xx'
            unknownproperty = 'xx'
            url = 'xx'
            weight = 'xx'
            nobackup = $False
        }
        set-HugoContent @HugoParameters

        $(test-path "/tmp/old/markdown_file.md_$Now") | Should Be $true
    }
}

Describe "set-HugoContent" {
 
    $HugoFile = join-path "pesterdata" "elvis-visits-Salisbury.md"

    $HugoParameters = @{
        HugoMarkdownFile = "$HugoFile"
        aliases = '["/on-this-day/theking"]'
        body = 'This is a test post - sadly Elvis never got to visit Salisbury'
        categories = 'on-this-day'
        date = '2016-08-25'
        description = ''
        draft = 'No'
        lastmod = '2016-08-25'
        markup = 'md'
        publishdate = '2016-08-25'
        tags = "elvis","wiltshire","salisbury"
        title = 'Elvis Presley visits Salisbury (this is a test)'
        unknownproperty = 'xx'
        url = '/on-this-day/june/elvis-visits-salisbury'
        weight = '1'
        nobackup = $False
        }
        set-HugoContent @HugoParameters

    It  "creates a backup copy of the existing file"  {
        
        $Now = get-date -uformat "%Y%m%d%H%M"
        $BackupFile = join-path -path ./pesterdata -ChildPath old -AdditionalChildPath "elvis-visits-Salisbury.md_${Now}"
        write-host "$BackupFile"
        test-path $BackupFile | Should Be $true
    }
    It "creates a markdown file" {
        $(test-path "$HugoFile") | Should Be $true
    }


    It "creates a markdown file whtat works with Hugo (if Hugo is running!)" {
    <#
        $WebPage = invoke-webrequest http://localhost:1313/on-this-day/june/elvis-visits-salisbury/ 
        
        $WebPage.RawContentLength | Should Be 2229
    #>
    }

    It "populates the Hugo fields" -testcases @{Key = "title"; ExpectedValue = "Elvis Presley visits Salisbury (this is a test)" },
                                              @{Key = "title"; ExpectedValue = "Elvis Presley visits Salisbury (this is a test)" } -test {
        param ([string]$Key,
               [string]$ExpectedValue)
 
        # write-host "`$Key: <$Key>"
        # write-host "`$ExpectedValue: <$ExpectedValue>"
        $ReturnedString = select-string  -pattern "$key  *:" $HugoFile

        $($ReturnedString | measure-object).count | Should Be 1

        [string]$Line = $ReturnedString.line
        # write-host "`$Line: <$Line>"
        $value = $Line.split(":")[1]
        $Value = $Value.trim()
       
        $Value | Should Be $ExpectedValue

    }
<#
title           : Elvis Presley visits Salisbury (this is a test)
description     : 
lastmod         : 2016-08-25
date            : 2016-08-25
tags            : 
 - "elvis" 
 - "wiltshire" 
 - "salisbury"
categories      : 
 - "on-this-day"
aliases         : 
 - "on-this-day"
draft           : No
publishdate     : 2016-08-25
weight          : 1
markup          : md
url             : /on-this-day/june/elvis-visits-salisbury
---
This is a test post - sadly Elvis never got to visit Salisbury
#>
}


describe -Tag Twitter  Get-TwitterCardMetaData {
    
    $MdString = @"
---
title: "3rd June 1977 - the Ramones visit Stonehenge. Johnny stays on the bus"
description: ""
lastmod: "2016-06-07"
date: "2014-11-04"
tags: [  ]
categories:
 - "on-this-day"
aliases: ["/on-this-day/june/3rd-june-1977-the-ramones-visit-stonehenge-johnny-stays-on-the-bus"]
draft: No
publishdate: "2014-11-04"
weight: 603
markup: "md"
url: /on-this-day/june/3rd-june-1977-the-ramones-visit-stonehenge-johnny-stays-on-the-bus
---

<a href="/images/Joey-Ramone-visited-Stonehenge.jpg"><img src="/images/Joey-Ramone-visited-Stonehenge.jpg" alt="Joey Ramone - &#039;visited&#039; Stonehenge" width="320" height="455" class="alignright size-full wp-image-9702" /></a>On either the 3rd<a name="Source1" href="#Note1">[1]</a> or possibly the 4th June 1977, the Ramones visited Stonehenge.

> Pic: By en:User:Dawkeye [<a href="http://www.gnu.org/copyleft/fdl.html">GFDL</a>, <a href="http://creativecommons.org/licenses/by-sa/3.0/">CC-BY-SA-3.0</a> or <a href="http://creativecommons.org/licenses/by-sa/2.5">CC-BY-SA-2.5</a>], <a href="http://commons.wikimedia.org/wiki/File%3AJoeyramone.jpg">via Wikimedia Commons</a>

### Footnotes

<a  href="#Source1" name="Note1">[1]</a> In 'On the Road with the Ramones', Monte A. Melnick says that the visit occurred

> 'On the '77 tour we had a day off and noticed Stonehenge was on the way'[URL <a href="http://books.google.co.uk/books?id=N7m8AwAAQBAJ&lpg=RA1-PR24&dq=ramones%20stonehenge&pg=RA1-PR25#v=onepage&q=ramones%20stonehenge&f=false">'On the Road with the Ramones', by By Monte A. Melnick, Frank Meyer</a>].

> This would have been when the Ramones were travelling back from Penzance to Canterbury - the free day being June 3rd [<a href="http://en.wikipedia.org/wiki/List_of_Ramones_concerts#1977">Wikipedia List Of Ramones Concerts</a>]
"@
    $RamonesFile = join-path "TestDrive:" -ChildPath "Ramones.md"
    set-content -path $RamonesFile -value $MdString

    $Splat =@{
        HugoMarkdownFile = $RamonesFile
        Card = "summary_large_image"
        Site = "http://salisburyandstonehenge.net"
        Creator = "monkey"
        DescriptionMaxLength = 240
        ImageUrlRoot = "http://salisburyandstonehenge.net/images"
        DefaultImage = "http://salisburyandstonehenge.net/images/Salisbury%20Cathedral%20across%20a%20flooded%20water%20meadow.jpeg"
        UrlRoot = "http://salisburyandstonehenge.net"
    }
    $TwitterCardMetaData = Get-TwitterCardMetaData @Splat
    [string]$Title = $TwitterCardMetaData.title
    [string]$Description = $TwitterCardMetaData.description
    [string]$Image = $TwitterCardMetaData.image
    [string]$URL = $TwitterCardMetaData.URL
        

    It "returns an error message if the file doesn't exist" {

        {Get-TwitterCardMetaData -HugoMarkDownFile $TestData/this_does_not_exist.md} | Should Throw
    }

    It "returns the correct value for title" {

        $Title | Should Be "3rd June 1977 - the Ramones visit Stonehenge. Johnny stays on the bus"
        
    }

    It "returns the correct value for description" {

    }

    It "returns the correct value for the image" {
        $Image | Should Be "http://salisburyandstonehenge.net/images/Joey-Ramone-visited-Stonehenge.jpg"
    }

    
    It "returns the first image if there is more than one" {
        
    }

    It "returns the default image if there is no image" {

    }

    It "returns the correct value for URL" {

    }
    
    It "returns correct values for description" {

    }
}



describe -Tag Twitter Get-DescriptionFromBodyText {

    $TestCases = @(
        @{
            TestTitle = "simple test"
            
            BodyText = @"
On the 23rd March 1943 HMS Stonehenge was launched from the shipyard at Birkenhead. HMS Stonehenge was an S-class submarine. She completed two war patrols but was lost with all hands in February 1944.

Pic: By Stewart Bale Ltd, Liverpool
"@
            Description = @"
On the 23rd March 1943 HMS Stonehenge was launched from the shipyard at Birkenhead. HMS Stonehenge was an S-class submarine. She completed two war patrols but was lost with all hands in February 1944. Pic: By Stewart Bale Ltd, Liverpool
"@
        }

    )


    It "returns whole sentences where it can" -testcases $TestCases {

    
    }

}

Describe -Tag Image -Name 'get-ImageDetails' {

    $SingleImage = get-ImageDetails -PostPath ./pesterdata/10th-august-1901-miss-moberly-meets-marie-antoinette.md -ImagePath ./pesterdata

    It 'returns a single image if there is only one' {
        $($SingleImage | Measure-Object).count | Should Be 1
    }

    It 'returns False for ImageExists if it doesnt exist' {

    }

    It 'returns true for ImageExists if it does exist' {
        $ImageExists = $SingleImage.ImageExists
        $ImageExists | Should Be $True
    }

    It 'returns the name' {

    }

    It 'returns the fullname' {
        
    }

    It 'returns an array of image records if there is more than one' {

    }

    It 'returns nothing if the post has no image' {

    }
}