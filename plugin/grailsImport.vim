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

    let filePathList = GetFilePathListFromFiles(classToFind)

    "Looking up class in text file
    if filePathList == []
       for line in s:loaded_data
           let tempClassList = split(line, '\.')
           if len(tempClassList) && tempClassList[-1] == classToFind
                :call add(filePathList, line)
           endif
       endfor
    endif

    let pathList = []
    for f in filePathList
        let shouldCreateImport = ShouldCreateImport(f)
        if (shouldCreateImport)
            :call add(pathList, f)
        else
            return
        endif
    endfor
    let x = CreateImports(pathList)

    call setpos('.', original_pos)
endfunction

function! GetFilePathListFromFiles(classToFind)
    let filePathList = []
    for extension in g:grails_import_file_extensions
        let searchString = '**/' . a:classToFind . '.' . extension
        let paths = globpath(g:grails_import_search_path, searchString, 1)
        let multiplePaths = split(paths, '\n')
        for p in multiplePaths
            let package = GetPackageFromFile(p)
            let fullPath =  package . '.' . a:classToFind
            if (index(filePathList, fullPath) == -1)
                :call add(filePathList,fullPath)
            endif
        endfor
    endfor
    return filePathList
endfunction

function! CreateImports(pathList)
    if a:pathList == []
        echoerr "no file found"
    else
        let packageLine = GetPackageLineNumber(expand("%:p"))
        for pa in a:pathList
            :let pos = getpos('.')
            let import = 'import ' . pa
            let extension = expand("%:e")
            if (extension == 'java')
               let formattedImport = import . ';'
            else
               let formattedImport = import
            endif

            :execute "normal " . (packageLine + 1) . "Go"
            :execute "normal I" . formattedImport . "\<Esc>"
            :execute "normal " . (pos[1] + 1) . "G"
        endfor
        if (g:grails_import_auto_remove)
            :call RemoveUnneededImports()
        endif
        if (g:grails_import_auto_organize)
            :call OrganizeImports()
            :call SpaceAfterPackage()
        endif
        if len(a:pathList) > 1
            echom "Warning: Multiple imports created!"
            for pa in a:pathList
                echom pa
            endfor
        endif
    endif
endfunction

function! ShouldCreateImport(path)
    let currentpackage = GetCurrentPackage()
    let importPackage = RemoveFileFromPackage(a:path)
    if importPackage != ''
        if importPackage != currentpackage
            :let starredImport = search(importPackage . "\\.\\*", 'nw')
            if starredImport > 0
                echom importPackage . '.* exists'
                return 0
            else
                :let existingImport = search(a:path . '\s*$', 'nw')
                if existingImport > 0
                    echom 'import already exists'
                    return 0
                else
                endif
            endif
        else
            echom "File is in the same package"
            return 0
        endif
    endif
    return 1
endfunction

function! GetCurrentPackage()
    return GetPackageFromFile(expand("%:p"))
endfunction

function! GetCurrentPackageFromPath()
    return ConvertPathToPackage(expand("%:r"))
endfunction

function! RemoveFileFromPackage(fullpath)
    return join(split(a:fullpath,'\.')[0:-2],'.')
endfunction

function! ConvertPathToPackage(filePath)
    let splitPath = split(a:filePath, '/')

    let idx = len(splitPath)
    for sep in g:grails_import_seperators
        let tempIdx = index(splitPath, sep)
        if tempIdx > 0
            if tempIdx < idx
                let idx = tempIdx + 1
            endif
        endif
    endfor
    let trimmedPath = splitPath[idx :-1]

    return join(split(join(trimmedPath, '.'),'\.')[0:-2], '.')
endfunction

function! GetPackageFromFile(filePath)
    let packageDeclaration = GetPackageLine(a:filePath)
    let package = split(packageDeclaration, '\s')[-1]
    let package = substitute(package, ';', '', '')
    return package

endfunction

function! GetPackageLine(filePath)
    let fileLines = readfile(a:filePath, '', 20) " arbitrary limit on number of lines to read
    let line = match(fileLines, "^package")
    return fileLines[line]
endfunction

function! GetPackageLineNumber(filePath)
    let fileLines = readfile(a:filePath, '', 20) " arbitrary limit on number of lines to read
    let line = match(fileLines, "^package")
    return line
endfunction

command! InsertImport :call InsertImport()
map <D-i> :InsertImport <CR>

function! SpaceAfterPackage()
    :let pos = getpos('.')

    :execute "normal gg"
    :let packageStart = search("^package")
    if packageStart == 0
        return
    endif

    :let importStart = search("^import")
    if importStart == 0
        return
    endif

    :let expectedImportStart = (packageStart + 2)
    if importStart != expectedImportStart
        :execute "normal O"
    endif

    call setpos('.', pos)
endfunction
command! SpaceAfterPackage :call SpaceAfterPackage()

function! OrganizeImports()
    :let pos = getpos('.')

    :execute "normal gg"
    :let start = search("^import")
    if start == 0
        return
    endif
    :let end = search("^import", 'b')
    :let lines = sort(getline(start, end))

    :execute "normal " . start . "G"
    if end == start
        :execute 'normal "_dd'
    else
        :execute 'normal "_d' . (end-start) . "j"
    endif

    :let currentprefix = ''
    :let currentline = ''
    :let firstline = ''

    for line in lines
        let pathList = split(line, '\.')

        if len(pathList) > 1
            let newprefix = pathList[0]
            if currentline == line
            else
                :let currentline = line
                if currentline == ''
                else
                    if currentprefix == newprefix
                    else
                        let currentprefix = newprefix
                        if firstline == ''
                            let firstline = line
                        else
                            :execute "normal I\<CR>"
                        endif
                    endif
                    :execute "normal I" . line . "\<CR>"
                endif
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

    :let pos = getpos('.')

    :execute "normal gg"

    :let start = search("^import")
    :let end = search("^import", 'b')
    :let lines = getline(start, end)
    :let updatedLines = []

    :execute "normal " . start . "G"
    if end == start
        :execute 'normal "_dd'
    else
        :execute 'normal "_d' . (end-start) . "j"
    endif

    for line in lines
        let trimmedLine = TrimString(line)
        if len(trimmedLine) > 0
            " Also split on spaces for things like
            " import com.MyClass as MyAwesomeClass
            let tempString = substitute(line, '\s', '\.', 'g')
            let classname = substitute(split(tempString, '\.')[-1], ';', '', '')
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
    call setpos('.', pos)
endfunction

command! RemoveUnneededImports :call RemoveUnneededImports()

function! TrimString(str)
    return substitute(a:str, '^\s*\(.\{-}\)\s*$', '\1', '')
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

