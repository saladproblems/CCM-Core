function Test-CCMQueryExpression {
    [cmdletbinding()]
    param(        
        [Parameter(Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]        
        $QueryExpression
    )
    begin{
        $cimHash = $Global:CCMConnection.PSObject.Copy()
    }
    process{
        Invoke-CimMethod @cimHash -ClassName SMS_CollectionRuleQuery -MethodName ValidateQuery -Arguments @{ wqlquery = $QueryExpression } |
            Select-Object -ExpandProperty ReturnValue
    }
}