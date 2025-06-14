# This script tries to gather all addons hosts on addons.mozilla.org. 
# The main entry point is the /addons/search endpoint which will return a paginated set of 30k addons at most. This is
# already quite good but as we can see in the response body the whole count is over 500k addons. So 30k that is by far 
# not enough. With the option --fast (-f) only the 30k most popular addons are gathered. That takes about 5 minutes with 
# roughly 120 requests per minute. Of course you can add a throttle with the --sleep-between-calls (-s) parameter.

# If we want to gather all addons available we need a different approach with which I haven't come up yet.

def main [ 
    addons_yaml: path 
    --sleep-between-calls (-s): duration = 0sec
    --api-base-url (-u): string = "https://addons.mozilla.org/api/v5"
    --fast (-f)
    --just-cleanup
] {
    if (not $just_cleanup) {
        if ($fast) {
            save-all-addons -p {sort: "users"}
        } else {
            error make {
                msg: "Gathering all addons existing addons is not yet implemented."
                help: "Use --fast (-f) to gather only the 30k most popular addons."
            }
        }
    }

    # after each operation clean up the file
    open $addons_yaml
        | each {from json}
        | reverse
        | uniq-by g
        | each {to json --raw}
        | to yaml
        | save $addons_yaml --force
    return


    # Functions

    def get-known-addons [] {
        if ($addons_yaml | path exists) {
            ^cat $addons_yaml | from yaml
        } else {
            "[]" | save $addons_yaml
            return []
        } 
    }

    # function to call the api
    def api [ route: string params = {}] {
        let query  = "?" + ($params | url build-query)
        sleep $sleep_between_calls
        let full_query = $api_base_url + $route + $query;
        
        if (($full_query | str length) > 256) {
            print ("GET " 
                + ($full_query | str substring ..128) 
                + "..." 
                + ($full_query | str substring (-128..))
                + $" \(($full_query | str length) characters long\)"
            )
        } else {
            print ("GET " + $full_query)
        }
        
        http get $full_query
    }

    def get-addon [id: int --prefetched-addon-detail (-d): table] {
        try {
            $prefetched_addon_detail 
                | if ($in == null) {
                    (api $"/addons/addon/($id)" {lang: "en-US"})
                } else $in
                | {
                    g: $in.guid,
                    s: $in.slug,
                    v: $in.current_version.version,
                    u: $in.current_version.file.url,
                    h: $in.current_version.file.hash,
                    p: ($in.current_version.file.permissions | default []),
                    l: ($in.current_version | default {slug: "all-rights-reserved"} license | get license.slug),
                }
        } catch {|err| print $"Addon with ID ($id) not found. Err: ($err.raw)"}
    }


    def save-all-addons [--additional-params (-p): record = {}] {
        def get-addons-page [page: int = 1] {
            api "/addons/search/" ({
                sort: "created" # newest first
                page_size: 50, # max page size
                page: $page, # current page
                lang: "en-US", # for performance
            } | merge $additional_params)
        }

        mut page = 1; 
        mut current_page = get-addons-page
        while ($current_page.count > 0) {
            # gather addons on one page
            mut $new_addons = []

            for $addon in ($current_page | get results) {
                let $addon_detail = get-addon $addon.id -d $addon
                
                # if no error occurred remember seen addon
                if ($addon_detail != null) {
                    $new_addons = $new_addons | append ($addon_detail | to json --raw)
                }
            }

            # merge new addons with known addons, save as yaml as there we can just append as we please
            touch $addons_yaml # ensure existance
            cp $addons_yaml ($addons_yaml + ".bak") # backup
            $new_addons 
                | to yaml
                | save $addons_yaml --append

            print $"page ($page) out of ($current_page.page_count), additional params: ($additional_params | url build-query)"
            
            $page += 1
            if ($page <= $current_page.page_count) {
                $current_page = get-addons-page $page
            } else break
        }
    }
}