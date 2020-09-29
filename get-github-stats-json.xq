(:~
 : Copyright (C) Evolved Binary 2020
 :
 : Connects to the GitHub API
 : and downloads a series of JSON documents
 : describing all commits for a range of
 : years.
 : The documents are then stored into the database.
 :)
xquery version "3.1";

import module namespace http = "http://expath.org/ns/http-client";
declare namespace util = "http://exist-db.org/xquery/util";
declare namespace xmldb = "http://exist-db.org/xquery/xmldb";

(:~
 : Set your GitHub access token here!
 :)
declare variable $local:github-access-token := "HERE";

(:~
 : Set the Git branches that you want commit data for
 :)
declare variable $local:git-branches := ("develop", "develop-4.x.x");

(:~
 : Set the years for which you want commit data for
 :)
declare variable $local:years := (2014 to 2020);


declare function local:get-all-pages($uri as xs:string, $page as xs:integer?, $page-function as function(item()) as xs:string) {
if (not($page))
then
	(: exit recursion :)
	()
else
	let $full-uri :=
		if ($page eq 1)
		then
			$uri
		else
			$uri || "&amp;page=" || $page
	let $request := 
		<http:request href="{$full-uri}" method="get">
			<http:header name="accept" value="application/vnd.github.v3+json"/>
		</http:request>
	let $response := http:send-request($request)
	return
		if(not($response[1]/@status eq "200"))
		then
			fn:error("bad request")
		else
			let $link-header-value := $response[1]/http:header[@name eq "link"]/@value
			return
				let $result := $page-function($response[2])
				let $next-page := local:get-next-page-num($link-header-value)
				return
					(
						(: recursive call for next-page :)
						if ($next-page)
						then
							local:get-all-pages($uri, $next-page, $page-function)
						else(),
						$result
					)
};

declare function local:get-next-page-num($link-header-value as xs:string?) as xs:integer? {
	let $next-page-num := fn:analyze-string($link-header-value, '&lt;(?:[^&gt;]+)page=([0-9]+)&gt;;\srel="next"')/fn:match/fn:group[@nr eq "1"]
	return
		if ($next-page-num)
		then
			string($next-page-num) cast as xs:integer
		else()
};

declare function local:store-json-page($collection-uri, $page) as xs:string {
	let $filename := util:uuid() || ".json"
	return
		xmldb:store($collection-uri, $filename, $page, "application/json")
};



for $branch in $local:git-branches
let $branch-collection-uri := if(xmldb:collection-available("/db/" || $branch || "_json")) then "/db/" || $branch || "_json" else xmldb:create-collection("/db", $branch || "_json")
for $year in $local:years
let $branch-year-collection-uri := if(xmldb:collection-available($branch-collection-uri || "/" || $year)) then $branch-collection-uri || "/" || $year else xmldb:create-collection($branch-collection-uri, $year)
let $start := $year || "-01-01T00:00:00Z"
let $end := $year + 1 || "-01-01T00:00:00Z"
return
	let $uri := "https://api.github.com/repos/exist-db/exist/commits?access_token=" || $local:github-access-token || "&amp;sha=" || $branch || "&amp;since=" || $start || "&amp;until=" || $end
	return
		local:get-all-pages($uri, 1, local:store-json-page($branch-year-collection-uri, ?))
