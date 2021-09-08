" Plugin: tmux.vim
" Author: Arthur Lui
" Date: 8 Sep, 2021

let s:opp_direction_dict = {"D": "U", "R": "L"}

function! s:Opposite(direction)
  return get(s:opp_direction_dict, a:direction, "")
endfunction

function s:GetCurrentLine()
  return shellescape(getline('.') . "")
endfunction

function s:GetVisualSelection()
  " keepjumps normal! "a`<v`>y']
  normal! gv"ay
  return shellescape(@a . "")
endfunction

function! s:Send(direction)
  call system("tmux select-pane -" . a:direction)
  call system("tmux send-keys " . s:GetCurrentLine())
  call system("tmux select-pane -" . s:Opposite(a:direction))
endfunction

function! s:SendVisual(direction)
  call system("tmux select-pane -" . a:direction)
  call system("tmux send-keys " . s:GetVisualSelection())
  call system("tmux select-pane -" . s:Opposite(a:direction))
endfunction

function! s:StartRepl()
  let ext = expand("%:e")
  if ext == "R"
    let cmd = "R"
  elseif ext == "jl"
    let cmd = "julia"
  elseif ext == "py"
    let cmd = "ipython"
  else
    let cmd = "bash"
  endif
  let cmd = input("Command to execute: ", cmd)
  if cmd != ""
    "call system("tmux set-option default-path " . shellescape(expand("%:p:h")))
    call system("tmux split-window -d -p 34 " . shellescape("exec " . cmd))
  endif
endfunction

" Sources a file into Console Below
function! s:SourceFile()
  let ext = expand("%:e")
  let filename = expand("%:p")
  let cmd = ""

  if ext == "R"
    let cmd = "source('" . filename . "')"
  elseif ext == "jl"
    let cmd = "include(\"" . filename . "\")"
  elseif ext == "scala"
    let cmd = ":load " . filename
  elseif ext == "py"
    let cmd = "exec(open('" . filename . "').read())"
  elseif ext == "sh"
    let cmd = "source " . filename
  elseif ext == "kt"
    let cmd = ":load  " . filename
  endif

  if cmd == ""
    " Recursively Send('D') for entire file.
    %call s:Send('D')
  else
    call system("tmux select-pane -D")
    call system("tmux send-keys " . shellescape(cmd . ""))
    call system("tmux select-pane -U")
  endif
endfunction

nnoremap <silent> <Plug>TmuxSendDown :<C-U> call <SID>Send("D")<CR>
nnoremap <silent> <Plug>TmuxSendRight :<C-U> call <SID>Send("R")<CR>
nnoremap <silent> <Plug>TmuxStartRepl :<C-U> call <SID>StartRepl()<CR>
nnoremap <silent> <Plug>TmuxSourceFile :<C-U> call <SID>SourceFile()<CR>
xnoremap <silent> <Plug>TmuxSendVisualDown :<C-U> call <SID>SendVisual("D")<CR>
xnoremap <silent> <Plug>TmuxSendVisualRight :<C-U> call <SID>SendVisual("R")<CR>

if !exists("g:tmux_default_bindings") || g:tmux_default_bindings
  nmap <C-j> <Plug>TmuxSendDown<CR>
  nmap <C-l> <Plug>TmuxSendRight<CR>
  nmap <C-k> <Plug>TmuxStartRepl<CR>
  nmap <C-h> <Plug>TmuxSourceFile<CR>
  xmap <C-j> <Plug>TmuxSendVisualDown<CR>
  xmap <C-l> <Plug>TmuxSendVisualRight<CR>
endif
