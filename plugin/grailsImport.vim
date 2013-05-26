"Configuration options
if !exists('g:grails_import_map_keys')
    let g:grails_import_map_keys = 1
endif

if !exists('g:grails_import_insert_shortcut')
    let g:grails_import_insert_shortcut='<leader>i'
endif

if !exists('g:grails_import_list_file')
    let s:current_file=expand("<sfile>:h")
    let g:grails_import_list_file = s:current_file . '/grailsImportList.txt'
endif

if !exists('g:grails_import_seperators')
    let g:grails_import_seperators = ['domain', 'services', 'groovy', 'java', 'taglib', 'controllers', 'integration', 'unit']
endif

if !exists('g:grails_import_auto_organize') 
    let g:grails_import_auto_organize = 1
endif

if !exists('g:grails_import_auto_remove')
    let g:grails_import_auto_remove = 1
endif

if !exists('g:grails_import_file_extensions')
    let g:grails_import_file_extensions = ['groovy', 'java']
endif

if !exists('g:grails_import_search_path')
    let g:grails_import_search_path = '.'
endif

"Functions
function! InsertImport()
    :let original_pos = getpos('.')
    let classToFind = expand("<cword>")

    let filePathList = []
    for extension in g:grails_import_file_extensions
        let searchString = '**/' . classToFind . '.' . extension
        let paths = globpath(g:grails_import_search_path, searchString)
        let multiplePaths = split(paths, '\n')
        for p in multiplePaths
            :call add(filePathList, split(p, '/'))
        endfor
    endfor

    let idx = 0
    
    let pathList = []
    let currentpackage = GetCurrentPackage()

    "Looking up class in text file
    if filePathList == []
       for line in s:loaded_data
           let tempClassList = split(line, '\.')
           if len(tempClassList) && tempClassList[-1] == classToFind
               :call add(pathList, line)
           endif
       endfor
    "Found file in current path, so determine package by path
    else 
        for f in filePathList
            let trimmedPath = ConvertPathToPackage(f)
            let importPackage = RemoveFileFromPackage(trimmedPath)
            if importPackage != '' 
                if  importPackage != currentpackage
                    :let starredImport = search(importPackage . "\\.\\*", 'nw')
                    if starredImport > 0
                        echom importPackage . '.* exists'
                        return
                    else
                        :let existingImport = search(trimmedPath, 'nw')
                        if existingImport > 0
                            echom 'import already exists'
                            return
                        else
                            :call add(pathList, trimmedPath)
                        endif
                    endif
                else 
                    echom "File is in the same package"
                    return
                endif
            endif
        endfor
    endif
    if pathList == []
        echoerr "no file found"
    else
        for pa in pathList
            :let pos = getpos('.')
            let import = 'import ' . pa
            let extension = expand("%:e")
            if (extension == 'java')
               let formattedImport = import . ';' 
            else
               let formattedImport = import
            endif
            :execute "normal ggo"
            :execute "normal I" . formattedImport . "\<Esc>"
            :execute "normal " . (pos[1] + 1) . "G"
        endfor
        if (g:grails_import_auto_remove)
            :call RemoveUnneededImports()
        endif
        if (g:grails_import_auto_organize)
            :call OrganizeImports() 
        endif
        if len(pathList) > 1
            echom "Warning: Multiple imports created!"
        endif
    endif

    call setpos('.', original_pos)
endfunction

function! GetCurrentPackage()
    return ConvertPathToPackage(split(expand("%:r"),'/'))
endfunction

function! RemoveFileFromPackage(fullpath)
    return join(split(a:fullpath,'\.')[0:-2],'.')
endfunction

function! ConvertPathToPackage(filePath)

    let f = a:filePath
    let idx = len(f)
    for sep in g:grails_import_seperators
        let tempIdx = index(f, sep) 
        if tempIdx > 0
            if tempIdx < idx
                let idx = tempIdx + 1
            endif
        endif
    endfor
    let trimmedPath = f[idx :-1]

    return join(split(join(trimmedPath, '.'),'\.')[0:-2], '.')
endfunction

command! InsertImport :call InsertImport() 
map <D-i> :InsertImport <CR>

function! OrganizeImports()
    :let pos = getpos('.')

    :let start = search("^import")
    :let end = search("^import", 'b')
    :let lines = getline(start, end)

    :execute "normal " . start . "G"
    if end == start
        :execute 'normal "_dd'
    else
        :execute 'normal "_d' . (end-start) . "j"
    endif
     
    :let currentprefix = ''
    :let currentline = ''

    for line in lines
        let pathList = split(line, '\.')
        
        if len(pathList) > 1
            let newprefix = pathList[0]
            if currentline == line
            else
                :let currentline = line
                if currentprefix == newprefix
                else
                    let currentprefix = newprefix
                    :execute "normal I \<CR>"
                endif
                :execute "normal I" . line . "\<CR>" 
            endif
        endif
    endfor
    call setpos('.', pos)
endfunction
command! OrganizeImports :call OrganizeImports()

function! CountOccurances(searchstring)
    let co = [] 
    :execute "normal gg"
	while search(a:searchstring, "W") > 0
        :call add(co, 'a') 
    endwhile
    return len(co)
endfunction

function! RemoveUnneededImports()
    :let start = search("^import")
    :let end = search("^import", 'b')
    :let lines = sort(getline(start, end))
    :let updatedLines = []

    :execute "normal " . start . "G"
    if end == start
        :execute 'normal "_dd'
    else
        :execute 'normal "_d' . (end-start) . "j"
    endif
        
    for line in lines
        let trimmedLine = substitute(line, '^\s*\(.\{-}\)\s*$', '\1', '')  
        if len(trimmedLine) > 0
            let classname = substitute(split(line, '\.')[-1], ';', '', '')
            " echoerr classname . " " . CountOccurances(classname)
            if classname == "*" || CountOccurances(classname) > 0
                :call add(updatedLines, substitute(line, '^\(\s\*\)','',''))
            endif
        endif
    endfor
    :execute "normal " . start . "G0"
    for line in updatedLines 
        :execute "normal I" . line . "\<CR>" 
    endfor
endfunction

"Loading of imports from a file
let s:loaded_data = []
function! LoadImports()
    if filereadable(g:grails_import_list_file)
      for line in readfile(g:grails_import_list_file)
        if len(line) > 0
          if line[0] != '"'
              :call add(s:loaded_data, line) 
          endif
        endif
      endfor
    endif
    if !len(s:loaded_data)
      echo 'vim-grails-import Error: Could not read import data from '.g:grails_import_list_file
    endif
endfunction
command! LoadImports :call LoadImports()
:call LoadImports()

"Key mappings
if g:grails_import_map_keys
    execute "nnoremap"  g:grails_import_insert_shortcut ":call InsertImport()<CR>"
endif
