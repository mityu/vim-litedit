function litedit#result#get_builders() abort
  return #{
    \ ok: function('s:ok'),
    \ err: function('s:err'),
    \ }
endfunction

let s:resultobj = #{ _status: v:null, _value: v:null }

" Returns TRUE if the object represents OK result.
function s:resultobj.is_ok() abort
  return self._status ==# 'ok'
endfunction

" Returns TRUE if the object represents erroneous result.
function s:resultobj.is_err() abort
  return self._status ==# 'err'
endfunction

" Returns the value that the object holds.
function s:resultobj.get_value() abort
  return self._value
endfunction

" Build a value that represents OK result.
function s:ok(v) abort
  return extend(#{ _status: 'ok', _value: a:v }, s:resultobj, 'keep')
endfunction

" Build a value that represents erroneous result.
function s:err(v) abort
  return extend(#{ _status: 'err', _value: a:v }, s:resultobj, 'keep')
endfunction
