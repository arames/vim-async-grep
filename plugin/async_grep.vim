" Asynchronous grep plugin based on neovim's job control.
" Last Change:	2015/06/17
" Maintainer:	Alexandre Rames <alexandre.rames@gmail.com>
" License:	This file is placed in the public domain.

if exists("g:loaded_async_grep") || !has('nvim')
  finish
endif
let g:loaded_async_grep = 1


let s:job_cid = 0
" A map from `job_id` to `job_cid`.
let s:jobs = {}


function s:GrepJobHandler(job_id, data, event)
  let job_cid = s:jobs[a:job_id]
  if a:event == 'exit'
    let temp_file = TempFile(job_cid)
    " Load the results in the location-list
    execute 'lgetfile ' .  temp_file
    " Delete the temporary file.
    execute 'silent !rm ' . temp_file
    lopen
  endif
endfunction


let s:callbacks = {
\   'on_stdout': function('s:GrepJobHandler'),
\   'on_stderr': function('s:GrepJobHandler'),
\   'on_exit': function('s:GrepJobHandler')
\ }


function! TempFile(job_cid)
  return '/tmp/neovim_async_grep.tmp.' . getpid() . '.' . a:job_cid
endfunction


function! StartGrepJob(...)
  let s:job_cid = s:job_cid + 1

  let base_command = &grepprg . ' ' . join(a:000, ' ')
  let redirection = ' &> ' . TempFile(s:job_cid)
  let command = base_command . redirection

  let grep_job = jobstart(command, s:callbacks)

  let s:jobs[grep_job] = s:job_cid
  echo 'Started: ' . base_command
endfunction


" You can map this to a shortcut. For example to grep for the word under the
" cursor:
"     nnoremap <F8> :Grep "<C-r><C-w> .<CR>
command! -nargs=* -complete=dir Grep call StartGrepJob(<f-args>)
