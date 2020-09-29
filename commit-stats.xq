(:~
 : Copyright (C) Evolved Binary 2020
 :
 : Generates a stats.xml file for each year,
 : which for each commit from that year includes
 : the files-changeed, deletions, and insertions.
 :)
xquery version "3.1";

declare namespace process = "http://exist-db.org/xquery/process";
declare namespace xmldb = "http://exist-db.org/xquery/xmldb";

(: change this to a local git clone of the exist-db repo :)
declare variable $local:exist-git-clone := "/Users/aretter/tmp-code/exist-for-release";


(:~
 : Gets the statisticts for a Git commit.
 :
 : @param $sha the git commit
 : @return a commit element containing statisticts of the files-changeed, deletions, and insertions.
 :)
declare function local:get-sha-stats($sha as xs:string) as element(commit) {
	let $result := process:execute(("git", "show", "--shortstat", $sha), <options><workingDir>{$local:exist-git-clone}</workingDir></options>)
	return 
		if (not($result/@exitCode eq "0"))
		then
			(	util:log("ERROR", ($sha, "exited with: " || $result/@exitCode)),
				<commit sha="{$sha}">
					<unknown exit-code="{$result/@exitCode}"/>
				</commit>
			)
		else
			let $std-out := $result/stdout/line/string(.)
			let $std-out-lines := string-join($std-out, '\n')
			return
				let $files-changed := fn:analyze-string($std-out-lines, "([0-9]+)\sfiles? changed")/fn:match/fn:group[@nr eq "1"]/xs:integer(.)
				let $deletions := (fn:analyze-string($std-out-lines, "([0-9]+)\sdeletions?\(-\)")/fn:match/fn:group[@nr eq "1"]/xs:integer(.), 0)[1]
				let $insertions := (fn:analyze-string($std-out-lines, "([0-9]+)\sinsertions?\(\+\)")/fn:match/fn:group[@nr eq "1"]/xs:integer(.), 0)[1]
				return
					<commit sha="{$sha}">
						<files-changed>{$files-changed}</files-changed>
						<deletions>{$deletions}</deletions>
						<insertions>{$insertions}</insertions>
					</commit>
};


let $branches := ("develop", "develop-4.x.x")
return
	for $branch in $branches
	for $year in xmldb:get-child-collections("/db/" || $branch || "_xml")
	let $collection-uri := "/db/" || $branch || "_xml/" || $year
	return
		let $stats := 
			<stats>
			{
				for $sha in collection($collection-uri)/fn:array/fn:map/fn:string[@key eq "sha"]/string(.)
				return
					local:get-sha-stats($sha)
	
			}
			</stats>
		return
			xmldb:store($collection-uri, "stats.xml", $stats)
