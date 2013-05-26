This is a plugin for vim that allows you to easily add imports within a groovy, grails or java project.

==============================================================================
CONTENTS                                      *grails-import* *grails-import-contents*

    Installation...........................: |grails-import-installation|
    Usage..................................: |grails-import-usage|
    Commands...............................: |grails-import-commands|
    Settings...............................: |grails-import-settings|
    Internals..............................: |grails-import-internals|
    Issues.................................: |grails-import-issues|


==============================================================================
INSTALLATION                                           *grails-import-installation*

Vundle (http://github.com/gmarik/vundle)
include the following line in your .vimrc
>
    Bundle 'sjurgemeyer/vim-grails-import'
<

Then, run 
>
    :BundleInstall
<

Pathogen (https://github.com/tpope/vim-pathogen) 
clone the plugin's git repository
>
    git clone git://github.com/sjurgemeyer/vim-grails-import.vim.git ~/.vim/bundle/vim-grails-import
<
If your vim configuration is under git version control, you could also set up
the repository as a submodule, which would allow you to update more easily.
The command is (provided you're in ~/.vim):
>
    git submodule add git://github.com/sjurgemeyer/grails-import.vim.git bundle/grails-import
<

You can also just copy the files the old fashioned way, but I don't condone that type of behavior

==============================================================================
USAGE                                                         *grails-import-usage*
The plugin provides several functions for creating and manipulating imports in groovy
files.  The biggest value add is the :InsertImport command which is by default mapped
to <leader>i

When in normal mode with your cursor over a class name, type <leader>i.  The plugin will
search the current working directory for file names that match the class name
and create an import statement using a derived package.  In addition, the
plugin comes with a list of common external classes that will be searched as
well.  
==============================================================================
COMMANDS                                                   *grails-import-commands*

                                              :InsertImport
:InsertImport     The main interface of the plugin.  By default it's mapped to
                  <leader>i. Searches for a file that matches the word under
                  the cursor and attempts to create an import based on that
                  file's location.

                                              *:OrganizeImports*
:OrganizeImports Sorts the imports.

                                              *:RemoveUnneededImports*
:RemoveUnneededImports Removes imports that do not have a class referenced
                  within the current file.  This does nothing to .* imports

==============================================================================
SETTINGS                                                *grails-import-settings*


------------------------------------------------------------------------------
g:grails_import_map_keys                                *grails_import_map_keys*

Allow grails-import to automatically map keys

Default: 1

------------------------------------------------------------------------------
g:grails_import_insert_shortcut                 *grails_import_insert_shortcut*

mapping for the InsertImport command

Default: '<leader>i'

------------------------------------------------------------------------------
g:grails_import_list_file                             *grails_import_list_file* 

The plugin ships with a file that contains some common classes with their
packages.  This is used to find classes that don't exist in the current
project.  If you wish to add more classes of your own, you can copy this file
and set the location of your custom file with this property.

Default {grails-import install location}/grailsImportList.txt
------------------------------------------------------------------------------
g:grails_import_seperators                           *grails_import_seperators*

The plugin currently determines the package of a class by its file path.  In
order to do this it needs to know the source directory locations that you have
in your project.  By default it uses common directoryies for grails and java.

Default ['domain', 'services', 'groovy', 'java', 'taglib', 'controllers', 'integration', 'unit']
------------------------------------------------------------------------------
g:grails_import_auto_organize                          *s_import_auto_organize*

When inserting imports the plugin automatically organizes the imports based on
alphabetical package listing with spaces between major package names.  If you
wish to remove this behavior, set this property to 0

Default: 1
------------------------------------------------------------------------------
g:grails_import_auto_remove                         *grails_import_auto_remove*

When inserting imports the plugin automatically removes imports that do not
have a reference in the current file.  If you wish to remove this behavior,
set this property to 0.

Default: 1
------------------------------------------------------------------------------
g:grails_import_file_extensions                 *grails_import_file_extensions*
The file extensions to use when searching for matching files.

Default ['groovy', 'java']
------------------------------------------------------------------------------
g:grails_import_search_path                         *grails_import_search_path*
By default, the plugin searches the working directory when trying to find
matching files.  If you wish to set this to something else by default you can
modify this property.

Default '.'

==============================================================================
INTERNALS                                                 *grails-import-internals*
TODO


==============================================================================
ISSUES                                                       *grails-import-issues*

To report any issues or offer suggestions, use the bugtracker of the github
project at http://github.com/sjurgemeyer/vim-grails-import/issues
