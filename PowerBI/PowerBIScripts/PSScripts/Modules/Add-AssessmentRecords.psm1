<# 
.SYNOPSIS
Persist assessment results

.DESCRIPTION
The sample scripts are not supported under any Microsoft standard support program or service. 
The sample scripts are provided AS IS without warranty of any kind. 
Microsoft further disclaims all implied warranties including, without limitation, any implied warranties of merchantability or of 
fitness for a particular purpose. The entire risk arising out of the use or performance of the sample scripts and documentation 
remains with you. In no event shall Microsoft, its authors, or anyone else involved in the creation, production, or delivery of 
the scripts be liable for any damages whatsoever (including, without limitation, damages for loss of business profits, 
business interruption, loss of business information, or other pecuniary loss) arising out of the use of or inability to use the 
sample scripts or documentation, even if Microsoft has been advised of the possibility of such damages. 
#>

function Add-AssessmentRecords{
    param(
        [string]$SinkContainer,
        [hashtable]$Config,
        [string]$fileTag = "",
        [parameter(ValueFromPipeline)]$Records
    )

    begin { $allRecords = @() }
    process { $allRecords += $Records }
    end {
        if("SQL" -eq $Config.SinkType -and $allRecords.Count -gt 0){
            $con = New-Object System.Data.SqlClient.SqlConnection
            $con.ConnectionString = $Config.Sink
            $con.Open()
            $sinkSchema = $con.GetSchema("Columns")
            $sinkColumns = $sinkSchema.Rows | Where-Object { $SinkContainer -eq $_["TABLE_NAME"] -and "Tag" -ne $_["COLUMN_NAME"]} | Select-Object -Property COLUMN_NAME
            
            if($sinkColumns.Count -eq 0){
                Write-AssessmentLog "ERROR: Table not found: $($SinkContainer)" -Config $Config
                break
            }

            $columnsList = New-Object System.Text.StringBuilder
            $isFirstColumn = $True
            $sinkColumns | ForEach-Object {
                if($isFirstColumn){
                    $isFirstColumn = $false
                }else{
                    $void = $columnsList.Append(",")
                }
                
                $void = $columnsList.Append("[")
                $void = $columnsList.Append($_.COLUMN_NAME)
                $void = $columnsList.Append("]")
            }

            $cmd = New-Object System.Data.SqlClient.SqlCommand
            $cmd.Connection = $con

            $allRecords | ForEach-Object {
                $valuesList = New-Object System.Text.StringBuilder

                $isFirstColumn = $True
                foreach ($column in $sinkColumns) {
                    if($isFirstColumn){
                        $isFirstColumn = $false
                    }else{
                        $void = $valuesList.Append(",")
                    }
                    $columnName = $column.COLUMN_NAME
                    if($columnName.Contains(".")){
                        $columnName = $columnName.Replace(".", "[") + "]"
                    }
                    $value = ""
                    if($_.PSobject.Properties.name -contains $columnName){
                        $value = $_.$columnName
                    }elseif($_.PSobject.Properties.name  -contains "[$columnName]"){
                        $value = $_."[$columnName]"
                    }
                    if($null -ne $value -and $value.GetType().Name -eq "String"){
                        $value = $value.Replace("'", "''")
                    }
                    $void = $valuesList.Append("'")
                    $void = $valuesList.Append($value)
                    $void = $valuesList.Append("'")
                }
                $commandText = "INSERT INTO $($Config.SinkSchema).[$SinkContainer] ($columnsList, Tag) VALUES ($valuesList, '$($Config.OutputTag)')"
                $cmd.CommandText = $commandText

                if($Config.LogQueries){
                    Write-AssessmentLog $commandText -Config $Config -Silent
                }

                $void = $cmd.ExecuteNonQuery()
            }

            $con.Close()
        }

        if("CSV" -eq $Config.SinkType){
            $fileName = [System.IO.Path]::Combine($Config.Sink, $SinkContainer)

            IF (!(test-path $Config.Sink)) {
                New-Item -ItemType Directory -Force -Path $Config.Sink
            }

            $fileName = "$fileName$($fileTag)$($Config.OutputTag).csv"
            if (Test-Path $fileName) {
                Remove-Item $fileName
            }
            
            if($allRecords){
                Write-AssessmentLog "Saving assessment records to CSV: $fileName" -Config $Config
                $allRecords  | Export-Csv -Path $fileName -NoTypeInformation -Append -Force
            }else{
                Write-AssessmentLog "No assessment records to save, skipping: $fileName" -Config $Config
            }
        }
    }
}