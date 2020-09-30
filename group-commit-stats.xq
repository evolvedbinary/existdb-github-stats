(:~
 : Copyright (C) Evolved Binary 2020
 :
 : Groups output from calculate-stats.xq into
 : three groups.
 :)
xquery version "3.1";

declare namespace map = "http://www.w3.org/2005/xpath-functions/map";

(: Evolved Binary Authors :)
let $eb-authors := (
    "adam.retter@googlemail.com",
    "rahul.delhi12@gmail.com"
)

(: eXist Solutions Authors :)
let $es-authors := (
    "wolfgangmm@gmail.com",
    "wolfgang@exist-db.org",
    "wolfgang@existsolutions.com",
    "tobias.krebs@betterform.de",
    "zwobit@users.noreply.github.com",
    "tobi.krebs@betterform.de",
    "lars.windauer@betterform.de",
    "lars@existsolutions.com",
    "joern.turner@betterform.de",
    "olaf@existsolutions.com",
    "tasmo@tasmo.de",
    "tuurma@gmail.com",
    "github@line-o.de"
)

(: Groups of authors :)
let $groups := map {
    "Evolved Binary": function($id as xs:string) { $id = $eb-authors },
    "eXist Solutions": function($id as xs:string) { $id = $es-authors },
    
    (: Anyone not in Evolved Binary or eXist Solutions :)
    "Others": function($id as xs:string) { not($id = ($eb-authors, $es-authors)) }    
}

for $year in /years/year
return
    element year {
        $year/@*,
        attribute total-changes { xs:integer($year/@total-detetions) + xs:integer($year/@total-insertions)},
        
        for $group-key in map:keys($groups)
        let $group-fn := $groups($group-key)
        let $group-users := $year/user[$group-fn(id)]
        let $group-total-commits := sum($group-users/commits)
        let $group-total-files-changed := sum($group-users/files-changed)
        let $group-total-deletions := sum($group-users/deletions)
        let $group-total-insertions := sum($group-users/insertions)
        let $group-total-loc-change := sum($group-users/loc-change)
        let $group-total-changes := $group-total-deletions + $group-total-insertions
        return
            <group id="{$group-key}" total-commits="{$group-total-commits}" total-files-changed="{$group-total-files-changed}" total-detetions="{$group-total-deletions}" total-insertions="{$group-total-insertions}" total-loc-change="{$group-total-loc-change}" total-change="{$group-total-changes}">
            {
                $group-users ! <user id="{id}" commits="{commits}"/>
            }
            </group>
    }
    
