@echo off
chcp 65001 >nul
setlocal
REM ============================================================
REM  Trinecta - prepara o video do hero para o site
REM  1) Coloque os 4 clipes nesta pasta (junto do index.html):
REM       clip1.mp4  clip2.mp4  clip3.mp4  clip4.mp4
REM  2) De dois cliques neste arquivo.
REM  Ele cria na pasta "videos":
REM    ida-1080.mp4 / ida-720.mp4     = os 4 clipes emendados
REM    volta-1080.mp4 / volta-720.mp4 = o mesmo video de tras para frente
REM    tempos.js                      = onde cada servico termina
REM ============================================================

where ffmpeg >nul 2>nul
if errorlevel 1 (
  echo ffmpeg nao encontrado. Instale com:  winget install ffmpeg
  echo Depois feche e abra o terminal e rode este arquivo de novo.
  pause
  exit /b
)
for %%n in (1 2 3 4) do (
  if not exist "clip%%n.mp4" (
    echo Falta o clip%%n.mp4 nesta pasta.
    pause
    exit /b
  )
)

if not exist videos mkdir videos
if not exist videos\tmp mkdir videos\tmp

call :versao 1080 22
call :versao 720 25

REM tempos de cada clipe (para o site saber onde pausar)
for /f "delims=" %%d in ('ffprobe -v error -show_entries format^=duration -of default^=nw^=1:nk^=1 "videos\tmp\f1.mp4"') do set D1=%%d
for /f "delims=" %%d in ('ffprobe -v error -show_entries format^=duration -of default^=nw^=1:nk^=1 "videos\tmp\f2.mp4"') do set D2=%%d
for /f "delims=" %%d in ('ffprobe -v error -show_entries format^=duration -of default^=nw^=1:nk^=1 "videos\tmp\f3.mp4"') do set D3=%%d
for /f "delims=" %%d in ('ffprobe -v error -show_entries format^=duration -of default^=nw^=1:nk^=1 "videos\tmp\f4.mp4"') do set D4=%%d
> videos\tempos.js echo var TEMPOS = [%D1%, %D2%, %D3%, %D4%];

rmdir /s /q videos\tmp
echo.
echo Pronto! Tamanhos:
dir /-c videos\*.mp4
echo Agora abra o index.html (ou aperte F5 se ja estiver aberto).
pause
exit /b

REM ---------- monta uma resolucao (%1 = altura, %2 = qualidade) ----------
:versao
echo ===== %1p =====
for %%n in (1 2 3 4) do (
  echo  clip%%n: ida
  ffmpeg -y -loglevel error -i "clip%%n.mp4" -an -vf "scale=-2:%1" -c:v libx264 -preset medium -crf %2 -g 8 -pix_fmt yuv420p "videos\tmp\f%%n.mp4"
  echo  clip%%n: volta
  ffmpeg -y -loglevel error -i "clip%%n.mp4" -an -vf "scale=-2:%1,reverse" -c:v libx264 -preset medium -crf %2 -g 8 -pix_fmt yuv420p "videos\tmp\r%%n.mp4"
)
(
  echo file 'f1.mp4'
  echo file 'f2.mp4'
  echo file 'f3.mp4'
  echo file 'f4.mp4'
) > videos\tmp\ida.txt
(
  echo file 'r4.mp4'
  echo file 'r3.mp4'
  echo file 'r2.mp4'
  echo file 'r1.mp4'
) > videos\tmp\volta.txt
ffmpeg -y -loglevel error -f concat -safe 0 -i videos\tmp\ida.txt -c copy -movflags +faststart "videos\ida-%1.mp4"
ffmpeg -y -loglevel error -f concat -safe 0 -i videos\tmp\volta.txt -c copy -movflags +faststart "videos\volta-%1.mp4"
exit /b
