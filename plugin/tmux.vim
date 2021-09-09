" Plugin: tmux.vim
" Author: Arthur Lui
" Date: 8 Sep, 2021

" A dictionary with the opposite directions to TMUX directions.
let s:opp_direction_dict = {"D": "U", "R": "L"}

" Return the opposite direction, given a TMUX direction.
function! s:Opposite(direction)
  return get(s:opp_direction_dict, a:direction, "")
endfunction

function s:GetCurrentLine()
  " Return the visual-selected with `\n` appropriately escaped. Then, append
  " `ENTER` at the very end.
  return shellescape(getline('.') . "\r")
endfunction

function s:GetVisualSelection()
  " Copy current visual selection to register "a.
  keepjumps normal! gv"ay']
  " NOTE: Moving the cursor up a line is a strange hack required to prevent the
  " cursor from skipping 2 lines. This even works if the cursor was on the
  " last line of the file...
  normal! k
  " Return the visual-selected with `\n` appropriately escaped. Then, append `ENTER`
  " at the very end.
  return shellescape(@a . "\r")
endfunction

" Send `message` to TMUX pane in `direction`.
function! s:Send(direction, message)
  call system("tmux select-pane -" . a:direction)
  call system("tmux send-keys " . a:message)
  call system("tmux select-pane -" . s:Opposite(a:direction))
endfunction

" Send text in current line to TMUX pane in `direction`.
function! s:SendLine(direction)
  call s:Send(a:direction, s:GetCurrentLine())
endfunction

" Send text in current visual selection to TMUX pane in `direction`.
function! s:SendVisual(direction)
  call s:Send(a:direction, s:GetVisualSelection())
endfunction

" Start a REPL (julia/ipython/R/bash) in TMUX pane below.
function! s:StartRepl()
  let ext = expand("%:e")
  if ext == "R"
    let cmd = "R"
  elseif ext == "jl"
    let cmd = "julia"
  elseif ext == "py"
    let cmd = "ipython --no-autoindent"
  else
    let cmd = "bash"
  endif
  let cmd = input("Command to execute: ", cmd)
  if cmd != ""
    "call system("tmux set-option default-path " . shellescape(expand("%:p:h")))
    call system("tmux split-window -d -p 34 " . shellescape("exec " . cmd))
  endif
endfunction

" Source a file into TMUX pane (REPL or BASH) below.
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
    %call s:SendLine('D')
  else
    call system("tmux select-pane -D")
    call system("tmux send-keys " . shellescape(cmd . "
    call system("tmux select-pane -U")
  endif
endfunction

" Plugin mappings.
nnoremap <silent> <Plug>TmuxStartRepl :<C-U> call <SID>StartRepl()<CR>
nnoremap <silent> <Plug>TmuxSourceFile :<C-U> call <SID>SourceFile()<CR>
nnoremap <silent> <Plug>TmuxSendLineDown :<C-U> call <SID>SendLine("D")<CR>
nnoremap <silent> <Plug>TmuxSendLineRight :<C-U> call <SID>SendLine("R")<CR>
xnoremap <silent> <Plug>TmuxSendVisualDown :<C-U> call <SID>SendVisual("D")<CR>
xnoremap <silent> <Plug>TmuxSendVisualRight :<C-U> call <SID>SendVisual("R")<CR>

" Default key bindings.
if !exists("g:tmux_default_bindings") || g:tmux_default_bindings
  nmap <C-k> <Plug>TmuxStartRepl<CR>
  nmap <C-h> <Plug>TmuxSourceFile<CR>
  nmap <C-j> <Plug>TmuxSendLineDown<CR>
  nmap <C-l> <Plug>TmuxSendLineRight<CR>
  xmap <C-j> <Plug>TmuxSendVisualDown<CR>
  xmap <C-l> <Plug>TmuxSendVisualRight<CR>
endif