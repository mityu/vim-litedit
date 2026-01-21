const s:default_opts_normal = #{
  \ dotrepeat: v:false,
  \ }
const s:default_opts_macro = #{
  \ reg: 'q',
  \ rec: v:true,
  \ exec: v:true,
  \ }
const g:litedit#default_opts = #{
  \ normal: s:default_opts_normal,
  \ macro: s:default_opts_macro,
  \ }

function s:get_opts(cmdname) abort
  let opts = copy(g:litedit#default_opts[a:cmdname])
  for table in [g:, b:]
    call extend(opts, get(get(table, 'litedit_opts', {}), a:cmdname, {}), 'force')
  endfor
  return opts
endfunction

function s:replace_termcodes(keys) abort
  return substitute(a:keys, '<[^<>]\+>',
    \ '\=eval(printf(''"\%s"'', submatch(0)))', 'g')
endfunction

function litedit#print_error(msg) abort
  let msg = a:msg->split("\n")->map({_, v -> '[litedit] ' . v})
  echohl Error
  for m in msg
    echomsg m
  endfor
  echohl NONE
endfunction

function litedit#normal(query, opts) abort
  const query = s:replace_termcodes(a:query)
  const opts = extend(s:get_opts('normal'), a:opts, 'force')
  const cmd = $'normal{opts.remap ? '' : '!'} {query}'

  if opts.dotrepeat
    " This dot-repeat hack is from this article. Thank you @kawarimidoll!
    " https://zenn.dev/vim_jp/articles/2d14953753f044
    let &operatorfunc = {_ -> execute(cmd, '')}
    call feedkeys('g@l', 'ni')
  else
    execute cmd
  endif
endfunction

function litedit#macro(query, opts) abort
  const opts = extend(s:get_opts('macro'), a:opts, 'force')

  if opts.reg !~# '\d\|\a\|"'
    call litedit#print_error($'Invalid register name: {opts.reg}')
    return
  endif

  let query = s:replace_termcodes(a:query)
  if opts.rec
    let query = $'{query}@{opts.reg}'
  endif

  " TODO: Support 'confirm-continue' option
  call setreg(opts.reg, query)
  if opts.exec
    call feedkeys($'@{opts.reg}', 'in')
  endif
endfunction
