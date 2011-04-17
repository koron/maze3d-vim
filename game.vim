" vim:set ts=8 sts=2 sw=2 tw=0 et:
"
" Author: MURAOKA Taro <koron.kaoriya@gmail.com>

scriptencoding utf-8

let s:WIDTH = 80
let s:SCREEN_RANGES = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20]
let s:BLOCKS = "!\"#$%&'()*+,-./:;<=>?@[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~"
let s:COLORS = [
      \ '#000000',
      \ '#800000',
      \ '#008000',
      \ '#808000',
      \ '#000080',
      \ '#800080',
      \ '#008080',
      \ '#808080',
      \ '#ff0000',
      \ '#00ff00',
      \ '#ffff00',
      \ '#0000ff',
      \ '#ff00ff',
      \ '#00ffff',
      \ '#ffffff'
      \]

function! s:Game()
  let doc = s:GameOpen()
  call s:GameMain(doc)
  echo s:GameClose(doc)
endfunction

function! s:GameOpen()
  set lazyredraw
  setlocal buftype=nofile noswapfile
  call s:SetupColors()
  " Initialize screen buffer
  let doc = {}
  let doc.screenBuffer = []
  let s = repeat(s:BLOCKS[0], s:WIDTH)
  for i in s:SCREEN_RANGES
    call add(doc.screenBuffer, s)
  endfor
  call s:GDocInit(doc)
  return doc
endfunction

function! s:SetupColors()
  syntax clear
  let idx = 0
  while idx < len(s:BLOCKS)
    let target = s:BLOCKS[idx]
    let name = 'gameBlock'.idx
    if idx < len(s:COLORS)
      let color = s:COLORS[idx]
    else
      let color = s:COLORS[0]
    endif
    let target = escape(target, '/\\*^$.~[]')
    execute 'syntax match '.name.' /'.target.'/'
    execute 'highlight '.name." guifg='".color."'"
    execute 'highlight '.name." guibg='".color."'"
    let idx = idx + 1
  endwhile
endfunction

function! s:GameMain(doc)
  let running = 1
  while running
    call s:GameDraw(a:doc)
    " FIXME: Change "wait" for your GAME.
    sleep 20m
    let running = s:GDocUpdate(a:doc, getchar(0))
  endwhile
endfunction

function! s:GameClose(doc)
  call s:GDocFinal(a:doc)
  set nolazyredraw
  return "GAME END"
endfunction

function! s:GameDraw(doc)
  execute "%d"
  call append(0, a:doc.screenBuffer)
  redraw
endfunction

function! s:GDocInit(doc)
  " TODO: Setup game document.
endfunction

function! s:GDocFinal(doc)
  " TODO: Finalize game document (ex. save high score, etc).
endfunction

function! s:GDocUpdate(doc, ev)
  " TODO:
  if a:ev == 27
    return 0
  elseif a:ev >= 33
    let char = nr2char(a:ev)
    let s = repeat(char, s:WIDTH)
    for i in s:SCREEN_RANGES
      let a:doc.screenBuffer[i] = s
    endfor
  endif
  return 1
endfunction

call s:Game()
