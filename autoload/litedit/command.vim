const s:r = litedit#result#get_builders()

" Same as the built-in trim(), but only trim white-spaces from the head of
" string.
function s:trim_head(s) abort
  return trim(a:s, '', 1)
endfunction

" Parse argument for ':Macro' command and returns parsed result.
function s:parse_args_macro(args) abort
  let args = a:args
  let opts = {}
  while v:true
    let args = s:trim_head(args)
    if args !~# '^-'
      return s:r.ok([args, opts])
    endif

    let flag = matchstr(args, '^\S*')
    let args = args[strlen(flag) :]
    let flagname = v:null
    let flagvalue = v:null

    if flag =~# '^-[^-]'
      return s:r.err($'Invalid flag: {string(flag)}')
    elseif flag ==# '--'
      return s:r.ok([s:trim_head(args), opts])
    elseif flag =~# '^--no-'
      let flagname = flag[5 :]  " '5' represents strlen('--no-')
      let flagvalue = v:false
    else
      let flagname = flag[2 :]
      let flagvalue = v:true
    endif

    if flagname ==# 'reg'
      " Specify register
      let args = s:trim_head(args)
      let reg = matchstr(args, '^\S*')
      let args = args[strlen(reg) :]
      if reg =~# '^@\?\(\d\|\a\|"\)$'
        if reg[0] ==# '@'
          let reg = reg[1]
        endif
        let opts.reg = reg
      elseif reg ==# ''
        return s:r.err($'No register is specified after "{flag}"')
      else
        return s:r.err($'Invalid register name: {string(reg)}')
      endif
    elseif index(['rec', 'exec', 'confirm-continue'], flagname) != -1
      " Boolean flags
      let opts[tr(flagname, '-', '_')] = flagvalue
    else
      return s:r.err($'Unknown flag: {string(flag)}')
    endif
  endwhile
endfunction

function s:parse_args_normal(args) abort
  let args = a:args
  let opts = {}
  while v:true
    let args = s:trim_head(args)
    if args !~# '^-'
      return s:r.ok([args, opts])
    endif

    let flag = matchstr(args, '^\S*')
    let args = args[strlen(flag) :]
    let flagname = v:null
    let flagvalue = v:null

    if flag =~# '^-[^-]'
      return s:r.err($'Invalid flag: {string(flag)}')
    elseif flag ==# '--'
      return s:r.ok([s:trim_head(args), opts])
    elseif flag =~# '^--no-'
      let flagname = flag[5 :]  " '5' represents strlen('--no-')
      let flagvalue = v:false
    else
      let flagname = flag[2 :]
      let flagvalue = v:true
    endif

    if index(['dotrepeat'], flagname) != -1
      let opts[flagname] = flagvalue
    else
      return s:r.err($'Unknown flag: {string(flag)}')
    endif
  endwhile
endfunction

function litedit#command#macro(args) abort
  let r = s:parse_args_macro(a:args)
  if r.is_err()
    call litedit#print_error(r.get_value())
    return
  endif

  call call('litedit#macro', r.get_value())
endfunction

function litedit#command#normal(got_bang, args) abort
  let r = s:parse_args_normal(a:args)
  if r.is_err()
    call litedit#print_error(r.get_value())
    return
  endif

  let [query, opts] = r.get_value()
  let opts.remap = !a:got_bang

  call litedit#normal(query, opts)
endfunction

function litedit#command#complete_normal(...) abort
  " TODO: Implement
  return []
endfunction


function litedit#command#complete_macro(...) abort
  " TODO: Implement
  return []
endfunction
