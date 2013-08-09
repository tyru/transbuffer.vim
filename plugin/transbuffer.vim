" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Load Once {{{
if get(g:, 'loaded_transbuffer', 0) || &cp
    finish
endif
let g:loaded_transbuffer = 1
" }}}
" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


command! -nargs=+ -complete=customlist,transbuffer#complete_get_buffer
\   TransGetBuffer call transbuffer#cmd_get_buffer(<f-args>)

command! -nargs=+ -complete=customlist,transbuffer#complete_put_buffer
\   TransPutBuffer call transbuffer#cmd_put_buffer(<f-args>)


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}
