call pathogen#infect() " turning on pathogin
set term=xterm-color
set smartcase " match 'word' case-insensitive and 'Word' case-sensitive
set showmatch " shows matching parenthesis, bracket, or brace
set showcmd " show commands while they're being typed
set incsearch " searches as you type
syntax on " syntax highlighing
set background=dark " adapt colors for background
:colorscheme desert
set vb t_vb=
set nowrap
setlocal spell spelllang=en_us
filetype plugin on " plugins are enabled
set noswapfile
set ruler
set wildmode=longest,list,full
set wildmenu
:filetype indent on
set expandtab
set tabstop=2
set shiftwidth=2
set autoindent
set smartindent
set isk-=_ "adds underscores as a word break
" search for visualized text
vnoremap // y/<C-R>"<CR>

"snipmate remaping to work with youCompleteMe
" Trigger configuration. Do not use <tab> if you use https://github.com/Valloric/YouCompleteMe.
let g:UltiSnipsExpandTrigger="<c-tab>"
let g:UltiSnipsJumpForwardTrigger="<c-j>"
let g:UltiSnipsJumpBackwardTrigger="<c-k>"
"save file as root
cmap w!! %!sudo tee > /dev/null %

au BufRead,BufNewFile jquery.*.js set ft=javascript syntax=jquery
if has("autocmd")
" Drupal *.module and *.install files.
  augroup module
    autocmd BufRead,BufNewFile *.module set filetype=php
    autocmd BufRead,BufNewFile *.install set filetype=php
   augroup END
endif

"text php syntax
map <C-B> :!php -l %<CR>

:let g:proj_flags="imstvcg"

,v :execute "!drush vget ".shellescape(expand("<cword>"), 1)<CR>

nnoremap ,m :w <BAR> !lessc % > %:t:r.css<CR><space>
    let g:syntastic_phpcs_conf=" --standard=DrupalCodingStandard --extensions=php,module,inc,install,test,profile,theme"
    let g:syntastic_auto_loc_list=1

nmap <F8> :TagbarToggle<CR>
nmap <F7> :set filetype=ruby.eruby.chef<CR>

"Powerline
" set rtp+=/home/josh/.local/lib/python2.7/site-packages/powerline/bindings/vim
