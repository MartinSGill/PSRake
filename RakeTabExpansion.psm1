#requires -Version 1

$rakeLongOptions = @(
    '--backtrace', 
    '--comments', 
    '--job-stats', 
    '--rules', 
    '--suppress-backtrace', 
    '--all', 
    '--build-all', 
    '--describe', 
    '--execute', 
    '--execute-continue', 
    '--rakefile', 
    '--nosystem', 
    '--system', 
    '--libdir', 
    '--jobs', 
    '--multitask', 
    '--dry-run', 
    '--no-search', 
    '--prereqs', 
    '--execute-print', 
    '--quiet', 
    '--require', 
    '--rakelibdir', 
    '--rakelib', 
    '--silent', 
    '--trace', 
    '--tasks', 
    '--verbose', 
    '--version', 
    '--where', 
    '--no-deprecation-warnings', 
    '--help'
)

if (test-path Function:\TabExpansion)
{
    Copy-Item Function:\TabExpansion RakeExpansionBackup
}

function Get-AliasPattern($exe) {
   $aliases = @($exe) + @(Get-Alias | where { $_.Definition -eq $exe } | select -Exp Name)
   "($($aliases -join '|'))"
}

function Get-RakeTasks
{
    $output = (rake -T 2>&1)
    if ($?)
    { 
        return $output  | ForEach-Object { $_ -replace '^rake (.*?)\s+.*', '$1' }
    }
}

function RakeTabExpansion($line, $lastWord)
{
     $lastBlock = [regex]::Split($line, '[|;]')[-1].TrimStart()

    # Rakefile option wants a file
    if ($lastBlock -match 'rake .*--rakefile $')
    {
        # Usual file matching
        if (Test-Path Function:\RakeExpansionBackup) 
        { 
            return RakeExpansionBackup $line $lastWord 
        } 
        return
    }

    if ($lastBlock -match '(--[\w-]*)$')
    {
        $match = $Matches[1]
        return ($rakeLongOptions | Where-Object { $_ -match "^$match" })
    }

    if ($lastBlock -match "rake.*\s([\w:_]*)$")
    {
        return (Get-RakeTasks) | Where-Object { $_ -match "^$Matches[1]" }
    }
}

function TabExpansion($line, $lastWord) 
{
    $lastBlock = [regex]::Split($line, '[|;]')[-1].TrimStart()

    switch -regex ($lastBlock) 
    {
        "^$(Get-AliasPattern rake) (.*)" { RakeTabExpansion $line $lastWord }
        # Fall back on existing tab expansion
        default { if (Test-Path Function:\RakeExpansionBackup) { RakeExpansionBackup $line $lastWord } }
    }
}

Export-ModuleMember -Function TabExpansion