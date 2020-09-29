(:~
 : Copyright (C) Evolved Binary 2020
 :
 : Calculates commit statistics per-year.
 :)
xquery version "3.1";

declare namespace xmldb = "http://exist-db.org/xquery/xmldb";

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
    			<user id="{$user}" commits="{count($user-total)}"/>
    	return
    		let $total-commits := sum($summed-data/xs:integer(@commits))
    		return
    			<year ordinal="{$year}" total-commits="{$total-commits}">
    			{
    			for $user in $summed-data
    			order by $user/@commits cast as xs:integer descending
    			return
    				<user>
    					<id>{string($user/@id)}</id>
    					<commits>{string($user/@commits)}</commits>
    					<percentage-of-total>{fn:format-number((xs:integer($user/@commits) div $total-commits) * 100.0, "##0.00")}</percentage-of-total>
    				</user>
    			}
    			</year>
}
</years>