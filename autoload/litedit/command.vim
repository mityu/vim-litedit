const s:r = litedit#result#get_builders()

" Same as the built-in trim(), but only trim white-spaces from the head of
" string.
function s:trim_head(s) abort
  return trim(a:s, '', 1)
endfunction

function s:range_char(start, end) abort
  return range(char2nr(a:start), char2nr(a:end))->map('nr2char(v:val)')
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

function litedit#command#complete_normal(arglead, cmdline, curpos) abort
  " TODO: Implement
  return []
endfunction


function litedit#command#complete_macro(arglead, cmdline, curpos) abort
  let cmdline = a:cmdline->strpart(0, a:curpos)->matchstr('^\s*\a\+\zs.*$')
  let arglead = v:null
  let argkind = 'flag'

  while v:true
    let cmdline = s:trim_head(cmdline)
    let token = matchstr(cmdline, '^\S*')
    let cmdline = cmdline[strlen(token) :]

    if cmdline ==# ''
      let arglead = token
      break
    endif

    if argkind ==# 'flag'
      if token ==# '--' || token !~# '^--'
        return []
      elseif token ==# '--reg'
        let argkind = 'arg-of-reg'
      endif
    elseif argkind ==# 'arg-of-reg'
      let argkind = 'flag'
    else
      throw $'Internal error: unknown argkind: {argkind}'
    endif
  endwhile

  if argkind ==# 'flag'
    let flags = ['--', '--exec', '--rec', '--reg', '--no-exec', '--no-rec']
    return filter(flags, { _, v -> strpart(v, 0, strlen(arglead)) ==# arglead })
  elseif argkind ==# 'arg-of-reg'
    let regs = ['"'] + s:range_char('0', '9') + s:range_char('a', 'z') + s:range_char('A', 'Z')
    if arglead =~# '^@'
      call map(regs, '"@" .. v:val')
    endif
    return filter(regs, { _, v -> strpart(v, 0, strlen(arglead)) ==# arglead })
  else
    throw $'Internal error: unknown argkind: {argkind}'
  endif
endfunction
