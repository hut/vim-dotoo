if exists('g:autoloaded_dotoo')
  finish
endif
let g:autoloaded_dotoo = 1

" Helper Functions
function! dotoo#get_headline(...)
  return call('dotoo#parser#headline#get', a:000)
endfunction

function! dotoo#move_headline(headline, parent_headline)
  let splitted = a:headline.open()
  call a:headline.delete()
  silent write
  call a:headline.close(splitted)
  if type(a:parent_headline) == type({})
    call a:parent_headline.add_headline(a:headline)
    call a:parent_headline.save()
  else
    silent exe 'noauto split' bufname(a:parent_headline)
    call append('$', a:headline.serialize())
    quit
  endif
endfunction

function! dotoo#change_todo(...)
  let headline = a:0 ? a:1 : dotoo#get_headline()
  let selection = dotoo#utils#change_todo_menu()
  if !empty(selection)
    call headline.change_todo(selection)
    call headline.save()
  endif
endfunction

function! s:get_date()
  let old_reg_val = @@
  let @@ = '' " clear register
  normal! di[
  let dt = @@
  if empty(dt)
    return ''
  else
    return dotoo#time#new(dt)
  endif
  let @@ = old_reg_val
endfunction

function! s:set_date(date)
  let old_reg_val = @@
  let @@ = a:date.to_string()
  normal! P
  let @@ = old_reg_val
endfunction

function! s:adjust_date(amount)
  let dt = s:get_date()
  if !empty(dt)
    call s:set_date(dt.adjust(a:amount))
    return 1
  else
    return 0
  endif
endfunction

function! dotoo#increment_date()
  if !s:adjust_date('+'.v:count1.'d') | exe "normal! \<C-A>" | endif
endfunction

function! dotoo#decrement_date()
  if !s:adjust_date('-'.v:count1.'d') | exe "normal! \<C-X>" | endif
endfunction

let s:syntax = dotoo#parser#lexer#syntax()
function! dotoo#normalize()
  let dt = s:get_date()
  if !empty(dt)
    call s:set_date(dt)
  elseif s:syntax.logbook_clock.matches(getline('.'))
    let old_view = winsaveview()
    call search('^\*\+', 'b')
    let headline = dotoo#get_headline()
    call headline.save()
    call winrestview(old_view)
  else
    exe "normal! \<C-C>\<C-C>"
  endif
endfunction
