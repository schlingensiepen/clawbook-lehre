@{
  # Interactive scripts for students: console output via Write-Host is
  # intended, and the helper functions are internal (no cmdlet contract).
  ExcludeRules = @(
    'PSAvoidUsingWriteHost',
    'PSUseApprovedVerbs',
    'PSUseShouldProcessForStateChangingFunctions',
    'PSUseSingularNouns'
  )
}
