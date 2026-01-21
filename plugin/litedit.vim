" TODO: Support range
command! -bang -nargs=* -complete=customlist,litedit#command#complete_normal
  \ Normal call litedit#command#normal(<bang>v:false, <q-args>)
command! -nargs=* -complete=customlist,litedit#command#complete_macro
  \ Macro call litedit#command#macro(<q-args>)
