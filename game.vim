" vim:set ts=8 sts=2 sw=2 tw=0 et:
"
" Author: MURAOKA Taro <koron.kaoriya@gmail.com>

scriptencoding utf-8

let s:WIDTH = 80
let s:SCREEN_RANGES = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20]
let s:BLOCKS = "!\"#$%&'()*+,/:;<=>?@[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~"
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
  " Initialize screen buffer
  let doc = {}
  let doc.screenBuffer = []
  let s = repeat(s:BLOCKS[0], s:WIDTH)
  for i in s:SCREEN_RANGES
    call add(doc.screenBuffer, s)
  endfor
  call s:ColorInit()
  call s:GDocInit(doc)
  return doc
endfunction

function! s:ColorInit()
  syntax clear
  let idx = 0
  while idx < len(s:BLOCKS)
    if idx < len(s:COLORS)
      let color = s:COLORS[idx]
    else
      let color = s:COLORS[0]
    endif
    call s:ColorSet(idx, color)
    let idx = idx + 1
  endwhile
endfunction

function! s:ColorSet(idx, color)
  let target = s:BLOCKS[a:idx]
  let name = 'gameBlock'.a:idx
  let target = escape(target, '/\\*^$.~[]')
  execute 'syntax match '.name.' /'.target.'/'
  execute 'highlight '.name." guifg='".a:color."'"
  execute 'highlight '.name." guibg='".a:color."'"
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
  " Setup game document.

  " Initialized wall color.
  let idx = 0
  while idx < s:DEPTH_RESOLUTION
    let value = (s:DEPTH_RESOLUTION - idx - 1) * 8
    if value > 255
      let value = 255
    end
    let color = printf('#0000%02x', value)
    call s:ColorSet(idx + 16, color)
    let idx = idx + 1
  endwhile

  let a:doc.mazeMap = [
        \ '###########',
        \ '#         #',
        \ '# # # # # #',
        \ '#         #',
        \ '# # # # # #',
        \ '#         #',
        \ '# # # # # #',
        \ '#         #',
        \ '# # # # # #',
        \ '#         #',
        \ '###########'
        \]

  let a:doc.mazeAvatar = {
        \ 'x' : 1.5,
        \ 'y' : 1.5,
        \ 'angle' : 0.0,
        \ 'speed' : 0.0,
        \ 'rotate' : 0.0,
        \}
endfunction

function! s:GDocFinal(doc)
  " Finalize game document (ex. save high score, etc).
endfunction

function! s:GDocUpdate(doc, ev)
  if a:ev == 27
    return 0
  elseif a:ev == 104 " h
    call s:MazeAvatarLeft(a:doc)
  elseif a:ev == 108 " l
    call s:MazeAvatarRight(a:doc)
  elseif a:ev == 107 " k
    call s:MazeAvatarForward(a:doc)
  else
    call s:MazeAvatarNeutral(a:doc)
  end
  call s:MazeRedraw(a:doc)
  return 1
endfunction

let s:PI = 3.14159265359
let s:DEPTH_RESOLUTION = 32
let s:VIEW_DEPTH = 8.0
let s:VIEW_ANGLE = 1.05
let s:ROTATE_MAX = 0.157
let s:ROTATE_DELTA = s:ROTATE_MAX / 5
let s:SPEED_MAX = 0.1
let s:SPEED_DELTA = s:SPEED_MAX / 5
let s:HEIGHT_LEVEL = [10,9,8,7,6,5,4,3,2,1,0,1,2,3,4,5,6,7,8,9,10]
let s:HEIGHT_PATTERN = [
      \ '[v]',
      \ '[tuv]',
      \ '[qrstuv]',
      \ '[nopqrstuv]',
      \ '[klmnopqrstuv]',
      \ '[hijklmnopqrstuv]',
      \ '[efghijklmnopqrstuv]',
      \ '[bcdefghijklmnopqrstuv]',
      \ '[_`abcdefghijklmnopqrstuv]',
      \ '[\\\]^_`abcdefghijklmnopqrstuv]',
      \ '[?@\[\\\]^_`abcdefghijklmnopqrstuv]',
      \]

function! s:MazeRedraw(doc)
  let avatar = a:doc.mazeAvatar
  " Update avatar position.
  let avatar.angle += avatar.rotate
  if avatar.angle > 3.14159265359
    let avatar.angle = avatar.angle - (s:PI * 2)
  elseif avatar.angle < -s:PI
    let avatar.angle = avatar.angle + (s:PI * 2)
  end
  let dx = cos(avatar.angle)
  let dy = sin(avatar.angle)
  let avatar.x = avatar.x + dx * avatar.speed
  let avatar.y = avatar.y + dy * avatar.speed
  " TODO: Check collision.
  " Update maze view.
  let angle_delta = s:VIEW_ANGLE / s:WIDTH
  let angle = avatar.angle - (s:VIEW_ANGLE / 2)
  let bufline = ''
  let idx = 0
  while idx < s:WIDTH
    let distance = s:MazeCollisionCheck(a:doc, avatar.x, avatar.y, angle, s:VIEW_DEPTH)
    let level = s:MazeDepth2Level(distance)
    let bufline = bufline.s:BLOCKS[16 + level]
    let angle = angle + angle_delta
    let idx = idx + 1
  endwhile
  let sbuf = a:doc.screenBuffer
  for i in s:SCREEN_RANGES
    " TODO: Consider wall height.
    let sbuf[i] = s:MazeHeightFilter(bufline, s:HEIGHT_LEVEL[i])
  endfor
endfunction

function! s:MazeHeightFilter(bufline, level)
  return substitute(a:bufline, s:HEIGHT_PATTERN[a:level], 'v', 'g')
endfunction

function! s:MazeCollisionCheck(doc, ax, ay, aa, max)
  let block = { 'x' : float2nr(a:ax), 'y' : float2nr(a:ay) }
  let point = { 'x' : a:ax, 'y' : a:ay }
  let vector = { 'dx' : cos(a:aa), 'dy' : sin(a:aa) }
  let distance = 0.0
  while distance < a:max
    if a:doc.mazeMap[block.y][block.x] == '#'
      break
    end
    let retval = s:MazeCollisionCheck2(a:doc, point, vector)
    let distance = distance + retval.distance
    let point = retval.point
    " This is fail safe (guard of infinity loop).
    if block.x == retval.block.x && block.y == retval.block.y
      break
    endif
    let block = retval.block
  endwhile
  if distance > a:max
    let distance = a:max
  endif
  return distance
endfunction

function! s:MazeCollisionCheck2(doc, point, vector)
  if a:vector.dx >=0
    if a:vector.dy >= 0
      " Check for (X+1, Y+1)
      let lx = float2nr(floor(a:point.x + 1.0))
      let ly = float2nr(floor(a:point.y + 1.0))
      let bxy = ly - 1
      let byx = lx - 1
    else
      " Check for (X+1, Y-1)
      let lx = float2nr(floor(a:point.x + 1.0))
      let ly = float2nr(ceil(a:point.y - 1.0))
      let bxy = ly + 1
      let byx = lx - 1
    endif
  else
    if a:vector.dy >= 0
      " Check for (X-1, Y+1)
      let lx = float2nr(ceil(a:point.x - 1.0))
      let ly = float2nr(floor(a:point.y + 1.0))
      let bxy = ly - 1
      let byx = lx + 1
    else
      " Check for (X-1, Y-1)
      let lx = float2nr(ceil(a:point.x - 1.0))
      let ly = float2nr(ceil(a:point.y - 1.0))
      let bxy = ly + 1
      let byx = lx + 1
    endif
  endif

  let fx = (lx - a:point.x) / a:vector.dx
  let fy = (ly - a:point.y) / a:vector.dy
  if fx < fy
    let distance = fx
    let ly = a:point.y + a:vector.dy * fx
    let block = { 'x' : lx, 'y' : bxy }
  else
    let distance = fy
    let lx = a:point.x + a:vector.dx * fy
    let block = { 'x' : byx, 'y' : ly }
  endif
  let point = { 'x' : lx, 'y' : ly }

  return { 'distance' : distance, 'point' : point, 'block' : block }
endfunction

function! s:MazeDepth2Level(depth)
  if a:depth > s:VIEW_DEPTH
    return 0
  else
    let level = float2nr(a:depth * s:DEPTH_RESOLUTION / s:VIEW_DEPTH)
    if level >= s:DEPTH_RESOLUTION
      let level = s:DEPTH_RESOLUTION - 1
    endif
    return level
  end
endfunction

function! s:MazeAvatarNeutral(doc)
  let avatar = a:doc.mazeAvatar
  " Damp speed.
  let avatar.speed = avatar.speed / 4.0
  if abs(avatar.speed) < 0.0001
    let avatar.speed = 0.0
  end
  " Damp rotate.
  let avatar.rotate = avatar.rotate / 2.0
  if abs(avatar.rotate) < 0.0001
    let avatar.rotate = 0.0
  end
endfunction

function! s:MazeMax(v1, v2)
  if a:v1 > a:v2
    return a:v1
  else
    return a:v2
  end
endfunction

function! s:MazeMin(v1, v2)
  if a:v1 < a:v2
    return a:v1
  else
    return a:v2
  end
endfunction

function! s:MazeAvatarForward(doc)
  let avatar = a:doc.mazeAvatar
  let avatar.speed = s:MazeMax(avatar.speed + s:SPEED_DELTA, s:SPEED_MAX)
endfunction

function! s:MazeAvatarLeft(doc)
  let avatar = a:doc.mazeAvatar
  let avatar.rotate = s:MazeMax(avatar.rotate - s:ROTATE_DELTA, -s:ROTATE_MAX)
endfunction

function! s:MazeAvatarRight(doc)
  let avatar = a:doc.mazeAvatar
  let avatar.rotate = s:MazeMin(avatar.rotate + s:ROTATE_DELTA, s:ROTATE_MAX)
endfunction

call s:Game()
