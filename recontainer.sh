#!/bin/bash
# recontainer

function help {
cat <<EOF
$(basename "$0"): go through the current directory and transfer any h264/aac videos to MP4, preserving subtitles if possible

 -c doesn't prompt to convert
 -d doesn't prompt to delete
 -i [file] converts a single file"
EOF
}

mp4ify ()
{
    ffmpeg -i "$1" -c:v copy -c:a copy -c:s mov_text "${1%.*}.mp4"
}
convert=''
delete=''

while getopts ":cdi:fh" opt; do
  case $opt in
    c)
      echo "autoconverting"
      convert=true
      ;;
    d)
      delete=true
      ;;
	i)
	  echo "single file mode, converting $OPTARG"
	  mp4ify "$OPTARG"
	  exit 0
	  ;;
	h)
	  help
	  exit 0
	  ;;
	*)
	  echo "Unknown switch, exiting"
	  exit 1
	  ;;
  esac
done

for i in *.mkv; do 
	ffmpeg -i "$i" 2>&1 | grep -q 'Audio: aac'
	if [ $? -eq 0 ]; then 
		ffmpeg -i "$i" 2>&1 | grep -q "Video: h264"
		if [ $? -eq 0 ]; then
			if [ "$convert" != true ]; then
				echo "convert $i?"
				read p
			fi
			if [[ ${p,,} == y* ]] || [ "$convert" = true ]; then 
				mp4ify "$i"
				exit=$?
			fi
			unset p
			if [ "$delete" != true ]; then
				echo "delete $i?"
				read p
			fi
			if [[ ${p,,} == y* ]] || [ "$delete" = true ]; then 
				if [[ $exit == 0 ]]; then
					rm "$i"
				else
					"Exit status of the conversion was $exit, not blindly deleting $i"
				fi
			fi
		fi
	fi
done
