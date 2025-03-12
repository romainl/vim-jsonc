function! jsonc#NormalizeFileName(filename, from = '')
    " we expect a tsconfig.json or jsconfig.json file somewhere at or above
    " the current level, which will help us find the project root
    let root_config_file = findfile('tsconfig.json', '.;')

    if empty(root_config_file)
        let root_config_file = findfile('jsconfig.json', '.;')
    endif

    " if we can't find it, then we don't have a project root and we can't
    " really do much more than returning the provided filename as-is
    if empty(root_config_file)
        return a:filename
    endif

    " we have our project root
    let project_root = root_config_file->fnamemodify(':p:h')

    " bail out (is this necessary?)
    if empty(project_root)
        return a:filename
    endif

    let filename = a:filename

    " add .json if missing
    if filename !~ '.*\.json'
        let filename = a:filename .. '.json'
    endif

    " "/foo" use "/foo.json"
    " "/foo.json" use path as-is
    if filename =~ '^\/'
        return filename
    endif

    " "foo" use "node_modules/foo.json"
    " "foo.json" use "node_modules/foo.json"
    " "./foo"
    " "./foo.json"
    let found_full_filename = a:filename
                \ ->substitute('^\.\/', a:from .. '/', '')
                \ ->glob()

    if found_full_filename != ''
        return found_full_filename
    endif

    " TODO: other cases
    " "../foo"
    " "../foo.json"
    " "" empty string, abort
    " "sdhqgifurstyd" doesn't exist, abort

    let found_filename_in_path = globpath([
                \ project_root,
                \ project_root .. '/node_modules',
                \ ]->join(','), filename)

    return found_filename_in_path
endfunction

function! jsonc#Jsonc_decode(filename)
    " tsconfig.json is actually JSONC, not JSON
    " so we need to weed out commented lines and inline comments
    " to obtain valid (but not pretty) JSON
    let decoded_data = readfile(jsonc#NormalizeFileName(a:filename))
                \ ->filter({ _, val -> val !~ '\(^\s*\/\/\)\|\(^\s*\/\*\)\|\(^\s*\*\/\)' })
                \ ->filter({ _, val -> val !~ '\(^\s*\w\)\|\(^\s*\*\)' })
                \ ->map({ _, val -> substitute(val, '\s*\/\*.*\*\/$', '', '')})
                \ ->join()
                \ ->json_decode()

    " tsconfig.son can extend other config files
    " the extends key can be a string or a list of strings
    " if it exists and is a string:
    "   we make a list out of it and we loop over it recursively
    " if it exists and is a list:
    "   we loop over it recursively
    if decoded_data->has_key('extends')
        let extends_field = get(decoded_data, 'extends')

        let parents = extends_field->type() == v:t_string
                    \ ? [extends_field]
                    \ : extends_field

        call filter(parents, { idx, val -> !empty(val) })

        let parents_data = {}

        for parent in parents
            let parent_data = parent
                        \ ->jsonc#NormalizeFileName(fnamemodify(a:filename, ':p:h'))
                        \ ->jsonc#Jsonc_decode()

            call extend(parents_data, parent_data)
        endfor

        call remove(decoded_data, 'extends')

        return extendnew(parents_data, decoded_data)
    endif

    return decoded_data
endfunction

