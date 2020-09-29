(:~
 : Copyright (C) Evolved Binary 2020
 :
 : Converts the JSON output from `get-github-stats-json.xq`
 : into an XML representatuon and stores those
 : documents into the database.
 :)
xquery version "3.1";

declare namespace util = "http://exist-db.org/xquery/util";
declare namespace xmldb = "http://exist-db.org/xquery/xmldb";

(:~
 : Set the Git branches that you want commit data for
 :)
declare variable $local:git-branches := ("develop", "develop-4.x.x");

for $branch in $local:git-branches
let $branch-json-collection-uri := "/db/" || $branch || "_json"
let $branch-xml-collection-uri := if(xmldb:collection-available("/db/" || $branch || "_xml")) then "/db/" || $branch || "_xml" else xmldb:create-collection("/db", $branch || "_xml")
let $years := xmldb:get-child-collections($branch-json-collection-uri)
for $year in $years
let $branch-year-json-collection-uri := $branch-json-collection-uri || "/" || $year
let $branch-year-xml-collection-uri := if(xmldb:collection-available($branch-xml-collection-uri || "/" || $year)) then $branch-xml-collection-uri || "/" || $year else xmldb:create-collection($branch-xml-collection-uri, $year)
return
	for $json-doc-uri in xmldb:get-child-resources($branch-year-json-collection-uri)
	let $json := util:base64-decode(util:binary-doc($branch-year-json-collection-uri || "/" || $json-doc-uri) cast as xs:string)
	let $xml := fn:json-to-xml($json, map { "validate": true() })
	return 
		xmldb:store($branch-year-xml-collection-uri, replace($json-doc-uri, "\.json", ".xml"), $xml)
		