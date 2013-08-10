" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


let s:Vital = vital#of('transbuffer.vim')
let s:List = s:Vital.import('Data.List')
let s:Process = s:Vital.import('Process')


function! transbuffer#cmd_get_buffer(srvname, file)
    if !s:check_servername(a:srvname)
        return
    endif

    " TODO: Use remote_read() to check successfully a file was opened.
    let sendcmd = printf('<C-\><C-g>:TransPutBuffer %s %s<CR>', v:servername, a:file)
    call remote_send(a:srvname, sendcmd)
endfunction

function! transbuffer#cmd_put_buffer(srvname, ...)
    if a:0 && !s:jump_to_tabpage_which_has_file(a:1)
        call s:error("This Vim instance does not have file '" . a:1 . "'.")
        return
    endif
    if &modified
        call s:error('buffer is modified!')
        return
    endif
    if bufname('%') ==# ''
        call s:error('buffer is empty!')
        return
    endif
    if !s:check_servername(a:srvname)
        return
    endif

    if a:srvname[0] ==# '+'
        " Spawn new Vim and let it open current file.
        let args = ['gvim', '--servername', a:srvname[1:]]
        if globpath(&rtp, 'autoload/singleton.vim') !=# ''
            let args += ['--cmd', 'let g:singleton#disable=1']
        endif
        let args += [expand('%:p')]
        call s:Process.spawn(args)
    else
        " Let it open current file.
        let current_buffer_is_empty = '!&modified && bufname("%") ==# "" && tabpagenr("$") ==# 1'
        let opencmd = remote_expr(a:srvname, current_buffer_is_empty) ? 'edit' : 'tabedit'
        let sendcmd = printf('<C-\><C-g>:%s %s<CR>:call foreground()<CR>',
        \                               opencmd, expand('%:p'))
        " TODO: Use remote_read() to check successfully a file was opened.
        call remote_send(a:srvname, sendcmd)
    endif

    " close
    quit
endfunction

function! transbuffer#complete_get_buffer(arglead, cmdline, cursorpos)
    " Complete serverlist.
    let srvlist = s:serverlist(0)
    let args = split(a:cmdline, '\s\+')[1:]
    let cursorarg = s:get_cursor_arg(a:cmdline, a:cursorpos)
    if len(args) ==# 0 && cursorarg ==# ''
        return srvlist
    elseif len(args) ==# 1 && cursorarg !=# ''
        return filter(srvlist, 'stridx(v:val, cursorarg) is 0')
    endif

    " Get remote buffer list.
    try
        let matching_buflist = 'map(tabpagebuflist(v:val+1), "fnamemodify(bufname(v:val), \":p\")")'
        let each_tabpage = 'map(range(tabpagenr("$")), ' . string(matching_buflist) . ')'
        let ret = remote_expr(args[0], 'string(' . each_tabpage . ')')
        let tabbuflist = s:List.flatten(eval(ret))
    catch
        " invalid servername, etc.
        call s:error(v:exception . ' @ ' . v:throwpoint)
        return
    endtry

    " Complete remote buffer list.
    if len(args) ==# 1 && cursorarg ==# ''
        return tabbuflist
    elseif len(args) ==# 2 && cursorarg !=# ''
        return filter(tabbuflist, 'v:val =~? cursorarg')
    endif

    return []
endfunction

function! s:check_servername(srvname)
    if a:srvname ==# ''
        call s:error("servername is empty.")
        return 0
    endif
    if a:srvname ==# v:servername
        call s:error("'" . a:srvname . "' is this Vim servername.")
        return 0
    endif
    if a:srvname[0] ==# '+'
        if s:exists_server(a:srvname[1:])
            call s:error(a:srvname[1:] . ': the server already exists.')
            return 0
        endif
    elseif !s:exists_server(a:srvname)
        call s:error(a:srvname . ': server not found.')
        return 0
    endif
    return 1
endfunction

function! s:exists_server(srvname)
    return index(s:serverlist(1), a:srvname) isnot -1
endfunction

function! transbuffer#complete_put_buffer(arglead, cmdline, cursorpos)
    let srvlist = s:serverlist(0)
    let cursorarg = s:get_cursor_arg(a:cmdline, a:cursorpos)
    if cursorarg !=# ''
        call filter(srvlist, 'stridx(v:val, cursorarg) is 0')
    endif
    return ['+'] + srvlist
endfunction

" FIXME: Process string containing also backslashed-whitespace
" as one successive string.
function! s:get_cursor_arg(cmdline, cursorpos)
    return matchstr(a:cmdline[: a:cursorpos], '\S\+$')
endfunction

function! s:serverlist(includeme)
    let srvlist = split(serverlist(), '\n')
    if !a:includeme
        call filter(srvlist, 'v:val !=# v:servername')
    endif
    return srvlist
endfunction

function! s:jump_to_tabpage_which_has_file(file)
    let bufnr = bufnr(a:file)
    if bufnr ==# -1
        return 0
    endif
    for tabnr in range(1, tabpagenr('$'))
        let buflist = tabpagebuflist(tabnr)
        let winidx = index(buflist, bufnr)
        if winidx >=# 0
            execute 'tabnext' tabnr
            execute (winidx + 1) . 'wincmd w'
            return 1
        endif
    endfor
    return 0
endfunction

function! s:echomsg(hl, msg)
    execute 'echohl' a:hl
    try
        echomsg a:msg
    finally
        echohl None
    endtry
endfunction

function! s:warn(msg)
    call s:echomsg('WarningMsg', a:msg)
endfunction

function! s:error(msg)
    call s:echomsg('ErrorMsg', a:msg)
endfunction


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}
