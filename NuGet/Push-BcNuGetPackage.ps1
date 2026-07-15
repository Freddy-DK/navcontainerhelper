<# 
 .Synopsis
  PROOF OF CONCEPT PREVIEW: Push Business Central NuGet Package to NuGet Server
 .Description
  Push Business Central NuGet Package to NuGet Server
 .PARAMETER nuGetServerUrl
  NuGet Server URL
 .PARAMETER nuGetToken
  NuGet Token for authenticated access to the NuGet Server
 .PARAMETER bcNuGetPackage
  Path to BcNuGetPackage to push. This is the value returned by New-BcNuGetPackage.
 .EXAMPLE
  $package = New-BcNuGetPackage -appfile $appFileName
  Push-BcNuGetPackage -nuGetServerUrl $nuGetServerUrl -nuGetToken $nuGetToken -bcNuGetPackage $package
#>
Function Push-BcNuGetPackage {
    Param(
        [Parameter(Mandatory=$true)]
        [string] $nuGetServerUrl,
        [Parameter(Mandatory=$true)]
        [string] $nuGetToken,
        [Parameter(Mandatory=$true)]
        [string] $bcNuGetPackage
    )

    # Publish the package using the official 'dotnet nuget push' client.
    # Credentials are written to an isolated temporary NuGet config file (removed afterwards) so that
    # the token is never passed on the command line - otherwise it could leak into error/CI logs.
    $sourceName = 'BcContainerHelperPushSource'
    $tmpConfigFile = Join-Path ([System.IO.Path]::GetTempPath()) "$([GUID]::NewGuid().ToString()).config"
    $escapedUrl = [System.Security.SecurityElement]::Escape($nuGetServerUrl)
    $escapedToken = [System.Security.SecurityElement]::Escape($nuGetToken)
    @"
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <packageSources>
    <add key="$sourceName" value="$escapedUrl" />
  </packageSources>
  <packageSourceCredentials>
    <$sourceName>
      <add key="Username" value="BcContainerHelper" />
      <add key="ClearTextPassword" value="$escapedToken" />
    </$sourceName>
  </packageSourceCredentials>
</configuration>
"@ | Set-Content -Path $tmpConfigFile -Encoding UTF8

    try {
        $arguments = "nuget push ""$bcNuGetPackage"" --source ""$sourceName"" --configfile ""$tmpConfigFile"" --skip-duplicate"
        cmddo -command 'dotnet' -arguments $arguments -messageIfCmdNotFound "dotnet not found. Please install it from https://dotnet.microsoft.com/download"
    }
    finally {
        Remove-Item -Path $tmpConfigFile -Force -ErrorAction SilentlyContinue
    }
}
Export-ModuleMember -Function Push-BcNuGetPackage
