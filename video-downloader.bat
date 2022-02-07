:: Made by Philip Tønnessen
:: 26.01.2021 - 07.02.2022

@echo off

SET ffmpeg=bin\ffmpeg-n4.4-latest-win64-gpl-4.4\bin\ffmpeg.exe
SET HandBrakeCLI=bin\HandBrakeCLI-1.5.1-win-x86_64\HandBrakeCLI.exe
SET yt-dlp=bin\yt-dlp\yt-dlp.exe

IF NOT EXIST exports mkdir exports

:: Max width and height of output file (4K)
SET width=3840
SET height=2160

:URL_input
SET /P url="Input video/playlist URL(s)(separated by spaces): "

:script_mode
echo. 
echo Available script modes:
echo (1) Direct
echo (2) Auto (mp4)
echo (3) Custom
echo. 
SET /P mode="Select the preferred mode (1-3): "
IF "%mode%" == "1" (
SET output_folder=exports
SET dl_options=
SET output_format=1
goto download
) ELSE IF "%mode%" == "2" (
SET output_folder=exports
SET dl_options=
SET ffmpeg_enc=libx264
SET hbrake_enc=x264
SET enc_quality=
SET crop_input=n
SET crop_sel=--crop 0:0:0:0
goto download
) ELSE IF "%mode%" == "3" (
goto output_folder_q
) ELSE (
echo.
echo Error: Invalid input
goto script_mode)

:output_folder_q
echo. 
SET /P output_q="Would you like to save the file(s) in a separate folder? (y/n): "
IF /I "%output_q%" == "y" (
goto folder_sel
) ELSE IF /I "%output_q%" == "n" (
SET output_folder=exports
goto output_format
) ELSE (
echo. 
echo Error: Invalid input
goto output_folder_q)

:folder_sel
echo. 
SET /P folder="Specify folder name: "
SET output_folder=exports\%folder%
IF NOT EXIST "exports\%folder%" mkdir "exports\%folder%"

:output_format
echo. 
echo Supported formats:
echo (1) direct
echo (2) mp4
echo (3) mp3
echo. 
SET /P output_format="Select output format (1-3): "
IF "%output_format%" == "1" (
SET dl_options=
goto download
) ELSE IF "%output_format%" == "2" (
SET dl_options=
goto encoder_selection
) ELSE IF "%output_format%" == "3" (
SET dl_options=-f bestaudio
goto mp3_bitrate
) ELSE (
echo. 
echo Error: Invalid input
goto output_format)

:mp3_bitrate
echo. 
echo MP3 bitrate:
echo (1) 320 kbps
echo (2) 256 kbps
echo (3) 192 kbps
echo (4) 128 kbps
echo. 
SET /P br_input="Select output bitrate (1-4): "
IF "%br_input%" == "1" (
SET mp3_br=320k
goto download
) ELSE IF "%br_input%" == "2" (
SET mp3_br=256k
goto download
) ELSE IF "%br_input%" == "3" (
SET mp3_br=192k
goto download
) ELSE IF "%br_input%" == "4" (
SET mp3_br=128k
goto download
) ELSE (
echo. 
echo Error: Invalid input
goto mp3_bitrate)

:encoder_selection
echo. 
SET /P enc_input="Do you have a NVIDIA GPU? (y/n): "
IF /I "%enc_input%" == "y" (
SET ffmpeg_enc=h264_nvenc
SET hbrake_enc=nvenc_h264
SET enc_quality=-strict -2 -rc vbr -cq 22 -qmin 22 -qmax 22
) ELSE IF /I "%enc_input%" == "n" (
SET ffmpeg_enc=libx264
SET hbrake_enc=x264
SET enc_quality=
) ELSE (
echo. 
echo Error: Invalid input
goto encoder_selection)

:autocrop_selection
echo.
SET /P crop_input="Do you want to auto-crop the video (remove black bars etc.)? (y/n): "
IF /I "%crop_input%" == "y" (
SET crop_sel=--loose-crop
) ELSE IF /I "%crop_input%" == "n" (
SET crop_sel=--crop 0:0:0:0
) ELSE (
echo. 
echo Error: Invalid input
goto autocrop_selection)

:download
mkdir tmp
%yt-dlp% %url% %dl_options% --restrict-filenames -o tmp\%%(title)s.%%(ext)s

:add_spaces_in_filename
Setlocal enabledelayedexpansion

cd tmp 

Set "Pattern=_"
Set "Replace= "

For %%a in ("*.*") Do (
    Set "File=%%~a"
    Ren "%%a" "!File:%Pattern%=%Replace%!"
)

cd ..
FOR /F "tokens=*" %%a IN ('dir /b tmp\*.*') DO move "tmp\%%a" "%cd%"
rmdir /s /q "tmp"

:ext_list
Setlocal enabledelayedexpansion

:: source: https://superuser.com/questions/397943/how-to-extract-a-complete-list-of-extension-types-within-a-directory

set target=%~1
if "%target%"=="" set target=%cd%

set LF=^


rem Previous two lines deliberately left blank for LF to work.

for /f "tokens=*" %%i in ('dir /b /a:-d "%target%"') do (
    set ext=%%~xi
    if "!ext!"=="" set ext=FileWithNoExtension
    echo !extlist! | find "!ext!:" > nul
    if not !ERRORLEVEL! == 0 set extlist=!extlist!!ext!:
)

echo %extlist::=!LF!% > exts.txt

endlocal

:find_ext
>nul findstr /c:"webm" exts.txt && (
  SET ext=webm
) || (
  SET ext=na
)

IF "%ext%" == "na" (
goto find_ext2
) ELSE (
goto checker
)

:find_ext2
>nul findstr /c:"mp4" exts.txt && (
  SET ext=mp4
) || (
  SET ext=na
)

IF "%ext%" == "na" (
goto find_ext3
) ELSE (
goto checker
)

:find_ext3
>nul findstr /c:"mkv" exts.txt && (
  SET ext=mkv
)

IF "%ext%" == "na" (
goto find_ext4
) ELSE (
goto checker
)

:find_ext4
>nul findstr /c:"m4a" exts.txt && (
  SET ext=m4a
)

:checker
DEL /F exts.txt

IF "%ext%" == "webm" (
goto navigate
) ELSE IF "%ext%" == "mkv" (
goto navigate
) ELSE IF "%ext%" == "mp4" (
goto navigate
) ELSE IF "%ext%" == "m4a" (
goto navigate
) ELSE IF "%ext%" == "na" (
start "" "%cd%\%output_folder%"
exit
)

:navigate
IF "%output_format%" == "1" (
FOR /F "tokens=*" %%G IN ('dir /b *.%ext%') DO move "%%G" "%output_folder%"
goto ext_list
) ELSE IF "%output_format%" == "2" (
goto conv_audio
) ELSE IF "%output_format%" == "3" (
goto conv_to_mp3
)

:conv_to_mp3
FOR /F "tokens=*" %%G IN ('dir /b *.%ext%') DO %ffmpeg% -i "%%G" -vn -b:a %mp3_br% "%%~nG.mp3" && DEL /F "%%G" && move "%%~nG.mp3" "%output_folder%" && goto ext_list

:conv_audio
FOR /F "tokens=*" %%G IN ('dir /b *.%ext%') DO %ffmpeg% -i "%%G" -vn -aq 6 "%%~nG.m4a" && goto navigate_encoder

:navigate_encoder
IF "%crop_input%" == "y" (
goto conv_video_raw
) ELSE IF "%crop_input%" == "n" (
goto conv_video_encode
)

:conv_video_raw
FOR /F "tokens=*" %%G IN ('dir /b *.%ext%') DO %ffmpeg% -i "%%G" -i "%%~nG.m4a" -vcodec copy -acodec copy -map 0:0 -map 1:0 "tmp_%%~nG.mp4" && DEL /F "%%G" && DEL /F "%%~nG.m4a" && rename "tmp_%%~nG.mp4" "%%~nG.mp4" && goto hbrake_encode

:conv_video_no_audio
FOR /F "tokens=*" %%G IN ('dir /b *.%ext%') DO %ffmpeg% -i "%%G" -vcodec copy -map 0:0 -c:v %ffmpeg_enc% %enc_quality% "%output_folder%\%%~nG.mp4" && goto ext_list

:conv_video_encode
FOR /F "tokens=*" %%G IN ('dir /b *.%ext%') DO %ffmpeg% -i "%%G" -i "%%~nG.m4a" -c:v %ffmpeg_enc% %enc_quality% -acodec copy -map 0:0 -map 1:0 "%output_folder%\%%~nG.mp4" && DEL /F "%%G" && DEL /F "%%~nG.m4a" && goto ext_list

:hbrake_encode
FOR /F "tokens=*" %%G IN ('dir /b *.mp4') DO %HandBrakeCLI% --input "%%G" %crop_sel% --maxWidth %width% --maxHeight %height% --encoder %hbrake_enc% --quality 27 --aencoder copy --output "tmp_%%G" && DEL /F "%%G" && rename "tmp_%%G" "%%G" && move "%%G" "%output_folder%" && goto ext_list