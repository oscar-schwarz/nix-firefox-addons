# This script tries to gather all addons hosts on addons.mozilla.org. 
# The main entry point is the /addons/search endpoint which will return a paginated set of 30k addons at most. This is
# already quite good but as we can see in the response body the whole count is over 500k addons. So 30k that is by far 
# not enough. With the option --fast (-f) only the 30k most popular addons are gathered. That takes about 5 minutes with 
# roughly 120 requests per minute. Of course you can add a throttle with the --sleep-between-calls (-s) parameter.

# If we want to gather all addons available we need a different approach with which I haven't come up yet.

const TYPES = ["extension", "statictheme" "dictionary"]
const APPLICATIONS = ["android", "firefox"]
const RELEVANT_FIELDS = [
    id
    guid
    slug
    current_version.version

    current_version.file.url
    current_version.file.hash

    # summary.en-US
    # homepage.url.en-US
    current_version.file.permissions
    current_version.license.slug
]

def main [ 
    addons_yaml: path 
    --sleep-between-calls (-s): duration = 0sec
    --api-base-url (-u): string = "https://addons.mozilla.org/api/v5"
    --fast (-f)
    --just-cleanup
] {
    if ($just_cleanup) {
        ^cat $addons_yaml
            | from yaml
            | reverse
            | uniq-by id
            | save $addons_yaml --force
        return
    }

    if ($fast) {
        save-all-addons -p {sort: "users"}
    } else {
        error make {
            msg: "Gathering all addons existing addons is not yet implemented."
            help: "Use --fast (-f) to gather only the 30k most popular addons."
        }
    }

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
                | do {
                    if ($in == null) {
                        return (api $"/addons/addon/($id)" {lang: "en-US"})
                    } else return $in
                }
                | select-deep ...$RELEVANT_FIELDS
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
                    $new_addons = $new_addons | append $addon_detail
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

def select-deep [...fields: string] {
    let $obj  = $in
    mut $result = {}

    for field in $fields {
        if ($field | str contains ".") {
            let root = $field | split row "." | first
            let rest = $field | str replace $"($root)." "";
            let new_obj = ($obj | default {} $root | get $root)
            $result = $result | merge deep {$root: ($new_obj | select-deep $rest)}
        } else {
            $result = $result | merge {$field: ($obj | default null $field | get $field)}
        }
    }
    return $result
}