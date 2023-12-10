$startUrl = ""
$r = Invoke-WebRequest -Uri $startUrl
$r
$response = ConvertFrom-Json $r.Content
$response

$s = Invoke-WebRequest -Uri $response.statusQueryGetUri
$s
$status = ConvertFrom-Json $s.Content
$status
$status.output
