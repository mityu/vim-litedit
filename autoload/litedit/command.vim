const s:r = litedit#result#get_builders()

function! s:get_non_escape_char_pattern(char, do_escape = v:true) abort
  const char = a:do_escape ? escape(a:char, '\.^$?*+~()[]{@|=&') : a:char
  return $'\v%(%(\_^|[^\\])%(\\\\)*)@<={char}'
endfunction

function! s:get_range_matcher() abort
  const matcher_slash = s:get_non_escape_char_pattern('/')
  const matcher_question = s:get_non_escape_char_pattern('?')
  const matcher_search = $'%(/.*{matcher_slash}|\?.*{matcher_question})'
  const matcher_position_elements =
    \ ['\d+', '[.$%]', "'.", $'{matcher_search}%({matcher_search})?','\\[/?&]']
    \ ->join('|')
  const matcher_position = $'%({matcher_position_elements})%(\s*[+-]\d+)?'
  return $'\v{matcher_position}%(\s*[,;]\s*{matcher_position})?'
endfunction

" Same as the built-in trim(), but only trim white-spaces from the head of
" string.
function s:trim_head(s) abort
  return trim(a:s, '', 1)
endfunction

function s:trim_command_range(s) abort
  return a:s[strlen(matchstr(a:s, $'^\s*{s:get_range_matcher()}')) :]
endfunction

" Return a list of characters between `start` and `end`.
function s:range_char(start, end) abort
  return range(char2nr(a:start), char2nr(a:end))->map('nr2char(v:val)')
endfunction

" Get next token consist of non-whitespace characters.
function s:get_next_chunk(text) abort
  const chunk = matchstr(a:text, '^\S*')
  const text = a:text[strlen(chunk) :]
  return [chunk, text]
endfunction

function s:get_next_n_chunks(text, count) abort
  let text = a:text
  let chunks = []
  for _ in range(a:count)
    let [chunk, text] = s:get_next_chunk(s:trim_head(text))
    call add(chunks, chunk)
  endfor
  return [chunks, text]
endfunction

function s:parse_args(config, text) abort
  let text = a:text
  let opts = {}

  while v:true
    let text = s:trim_head(text)
    if text !~# '^-'
      return s:r.ok([text, opts])
    endif

    let [flag, text] = s:get_next_chunk(text)
    let flagname = v:null
    let flagvalue = v:null

    if flag =~# '^-[^-]'
      return s:r.err($'Invalid flag: {string(flag)}')
    elseif flag ==# '--'
      return s:r.ok([s:trim_head(text), opts])
    elseif flag =~# '^--no-'
      let flagname = flag[5 :]  " '5' represents strlen('--no-')
      let flagvalue = v:false
    else
      let flagname = flag[2 :]
      let flagvalue = v:true
    endif

    if !has_key(a:config, flagname)
      return s:r.err($'Unknown flag: {string(flag)}')
    endif

    let optkey = tr(flagname, '-', '_')
    let flagconfig = a:config[flagname]
    if flagconfig.nargs == 0
      let opts[optkey] = flagvalue
    else
      if flagvalue == v:false
        " Only boolean flag can be negated by prefixing '--no-'.
        return s:r.err($'This flag is not a boolean flag: {string(flag)}')
      endif

      let text = s:trim_head(text)
      let r = call(flagconfig.parse_args, [flag, text])
      if r.is_err()
        return r
      else
        let [flagvalue, text] = r.get_value()
        let opts[optkey] = flagvalue
      endif
    endif
  endwhile
endfunction

function s:complete_args(config, cmdline) abort
  let cmdline = a:cmdline
  let parsing_arg_of = v:null

  while v:true
    let [token, cmdline] = s:get_next_chunk(s:trim_head(cmdline))

    if cmdline ==# ''
      break
    elseif token ==# '--' || token !~# '^--'
      return []
    endif

    let flagname = token[2 :]
    let flagconfig = get(a:config, flagname, #{ nargs: 0 })

    if flagconfig.nargs == 0
      continue
    endif

    let [chunks, rest] = s:get_next_n_chunks(s:trim_head(cmdline), flagconfig.nargs)
    call filter(chunks, '!empty(v:val)')

    if len(chunks) != flagconfig.nargs || rest ==# ''
      let parsing_arg_of = flagname
      break
    else
      let cmdline = rest
      continue
    endif
  endwhile

  if parsing_arg_of is v:null
    let flags = ['--']
      \ + a:config->keys()->sort()->map({ _, v -> '--' .. v})
      \ + a:config->copy()->filter({ _, v -> v.nargs == 0 })->keys()->sort()->map({ _, v -> '--no-' .. v })
    return filter(flags, { _, v -> strpart(v, 0, strlen(token)) ==# token })
  else
    return call(a:config[parsing_arg_of].gen_completion, [cmdline])
  endif
endfunction

let s:args_config = {}
let s:args_config.macro = {
  \ 'reg': #{ nargs: 1 },
  \ 'rec': #{ nargs: 0 },
  \ 'exec': #{ nargs: 0 },
  \ 'check-continue': #{ nargs: 0 },
  \ }
let s:args_config.normal = {
  \ 'dotrepeat': #{ nargs: 0 },
  \ }

" Parse an argument given for the '--reg' flag of ':Macro' command.
function s:args_config.macro.reg.parse_args(flag, args) abort
  let [reg, args] = s:get_next_chunk(a:args)

  if reg =~# '^@\?\(\d\|\a\|"\)$'
    if reg[0] ==# '@'
      let reg = reg[1]
    endif
    return s:r.ok([reg, args])
  elseif reg ==# ''
    return s:r.err($'No register is specified after "{a:flag}"')
  else
    return s:r.err($'Invalid register name: {string(reg)}')
  endif
endfunction

" Complete arguments of '--reg' flag of ':Macro' comand.
function s:args_config.macro.reg.gen_completion(cmdline) abort
  const [arglead, _] = s:get_next_chunk(s:trim_head(a:cmdline))

  let regs = ['"'] + s:range_char('0', '9') + s:range_char('a', 'z') + s:range_char('A', 'Z')
  if arglead =~# '^@'
    call map(regs, '"@" .. v:val')
  endif
  return filter(regs, { _, v -> strpart(v, 0, strlen(arglead)) ==# arglead })
endfunction

" Parse argument for ':Macro' command and returns parsed result.
function s:parse_args_macro(args) abort
  return s:parse_args(s:args_config.macro, a:args)
endfunction

function s:parse_args_normal(args) abort
  return s:parse_args(s:args_config.normal, a:args)
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
  let cmdline = a:cmdline->strpart(0, a:curpos)->s:trim_command_range()->matchstr('^\s*\a\+!\?\zs.*$')
  return s:complete_args(s:args_config.normal, cmdline)
endfunction


function litedit#command#complete_macro(arglead, cmdline, curpos) abort
  let cmdline = a:cmdline->strpart(0, a:curpos)->matchstr('^\s*\a\+\zs.*$')
  return s:complete_args(s:args_config.macro, cmdline)
endfunction
