" vim:set ts=8 sts=2 sw=2 tw=0 et:
"
" Author: MURAOKA Taro <koron.kaoriya@gmail.com>

scriptencoding utf-8

let s:SCREEN_RANGES = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20]
let s:BLOCK = "!\"#$%&'()*+,-./:;<=>?@[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~"

function! s:Game()
  let doc = s:GameOpen()
  call s:GameMain(doc)
  echo s:GameClose(doc)
endfunction

function! s:GameOpen()
  set lazyredraw
  " Initialize screen buffer
  let doc = {}
  let doc.screenBuffer = []
  for i in s:SCREEN_RANGES
    call add(doc.screenBuffer, '')
  endfor
  call s:GDocInit(doc)
  return doc
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
    let s = repeat(char, 80)
    for i in s:SCREEN_RANGES
      let a:doc.screenBuffer[i] = s
    endfor
  endif
  return 1
endfunction

call s:Game()
