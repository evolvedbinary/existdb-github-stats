(:~
 : Copyright (C) Evolved Binary 2020
 :
 : Calculates commit statistics per-year.
 :)
xquery version "3.1";

declare namespace xmldb = "http://exist-db.org/xquery/xmldb";

(:~
 : Create an integer from anyAtomicType.
 :
 : The key thing is that we safely handle empty-strings
 : by returning 0.
 :
 : @param value the value to create an integer from
 : @return the integer
 :)
declare function local:safe-int($value as xs:anyAtomicType?) as xs:integer {
	if (empty($value) or $value eq "")
	then
		0
	else
		xs:integer($value)
};

<years>
{
    for $year in xmldb:get-child-collections("/db/develop_xml")
    order by xs:integer($year) descending
    return
    	let $summed-data :=
    		let $year-stats := doc("/db/develop_xml/" || $year || "/stats.xml")/stats
    		for $commit in collection("/db/develop_xml/" || $year)/fn:array/fn:map/fn:map[@key eq "commit"]
    		let $commit-changes := $year-stats/commit[@sha eq $commit/parent::fn:map/fn:string[@key eq 'sha']]
    		
    		(: You can change `author` to `committer` here if you want to see who committed rather than authored :)
    		let $user := $commit/fn:map[@key eq "author"]/fn:string[@key eq "email"]/string(.)
    		
    		let $user-total := count($commit)
    		group by $user
    		return
                <user id="{$user}" commits="{count($user-total)}">
                {
                    $commit-changes
                }
                </user>
	return
		let $total-commits := sum($summed-data/xs:integer(@commits))
		let $total-files-changed := sum($summed-data/commit/files-changed ! local:safe-int(.))
		let $total-deletions := sum($summed-data/commit/deletions ! local:safe-int(.))
		let $total-insertions := sum($summed-data/commit/insertions ! local:safe-int(.))
		let $total-loc-change := $total-insertions - $total-deletions
		return
			<year ordinal="{$year}" total-commits="{$total-commits}" total-files-changed="{$total-files-changed}" total-detetions="{$total-deletions}" total-insertions="{$total-insertions}" total-loc-change="{$total-loc-change}">
			{
			for $user in $summed-data
			let $user-files-changed := sum($user/commit/files-changed ! local:safe-int(.))
			let $user-deletions := sum($user/commit/deletions ! local:safe-int(.))
			let $user-insertions := sum($user/commit/insertions ! local:safe-int(.))
			let $user-loc-change := $user-insertions - $user-deletions
			order by $user/@commits cast as xs:integer descending
			return
				<user>
					<id>{string($user/@id)}</id>
					<commits percentage-of-total="{fn:format-number((xs:integer($user/@commits) div $total-commits) * 100.0, "##0.00")}">{string($user/@commits)}</commits>
					<files-changed percentage-of-total="{fn:format-number((xs:integer($user-files-changed) div $total-files-changed) * 100.0, "##0.00")}">{$user-files-changed}</files-changed>
					<deletions percentage-of-total="{fn:format-number((xs:integer($user-deletions) div $total-deletions) * 100.0, "##0.00")}">{$user-deletions}</deletions>
					<insertions percentage-of-total="{fn:format-number((xs:integer($user-insertions) div $total-insertions) * 100.0, "##0.00")}">{$user-insertions}</insertions>
					<loc-change percentage-of-total="{fn:format-number((xs:integer($user-loc-change) div $total-loc-change) * 100.0, "##0.00")}">{$user-loc-change}</loc-change>
				</user>
			}
			</year>
}</years>