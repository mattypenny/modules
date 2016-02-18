function write-startfunction { 
<#
.SYNOPSIS
  Marks start of function in logfile or debug output

.DESCRIPTION
  Gets parameters back from Get-PSCallStack

.EXAMPLE
  write-startfunction $MyInvocation
#>
  [CmdletBinding()]
  Param(  ) 

  $CallDate = get-date -format 'hh:mm:ss.ffff' 
    
  $CallingFunction = Get-PSCallStack | Select-Object -first 2 | select-object -last 1

  [string]$Command = $CallingFunction.Command        
  [string]$Location = $CallingFunction.Location 
  [string]$Arguments = $CallingFunction.Arguments       
  # [string]$FunctionName = $CallingFunction.FunctionName
   
  write-debug "$CallDate Start: $Location $Command $Arguments"
  return
}

function write-endfunction { 
<#
.SYNOPSIS
  Marks end of function in logfile or debug output

.EXAMPLE
  write-endfunction
#>
  [CmdletBinding()]
  Param(  ) 

  $CallDate = get-date -format 'hh:mm:ss.ffff' 
  $CallingFunction = Get-PSCallStack | Select-Object -first 2 | select-object -last 1

  [string]$Command = $CallingFunction.Command        
  [string]$Location = $CallingFunction.Location 
   
  write-debug "$CallDate Finish: $Location $Command"
  return
}

function test-writestartfunction {
<#
.SYNOPSIS
  Test function for write-startfunction

.EXAMPLE
  test-writestartfunction -x "Goodness" -y "Gracious"
#>
  [CmdletBinding()]
  Param( $X, $Y )
 
write-startfunction 
Write-Debug "Done it all"
write-endfunction 
} 

# $DebugPreference = "Continue"
# Import-Module shlogging
# test-writestartfunction -x "Goodness" -y "Gracious"
