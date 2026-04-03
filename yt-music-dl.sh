#!/bin/bash

if [ "$#" != 2 ]; then
	echo "Usage: $0 [JSON_FILE] [DIRECTORY]"
	exit 1
fi

music_list_file=$1
output_dir=$2

echo "Downloading music from $music_list_file"
music_info_list=$(jq -c '.[]' "$music_list_file")

duplicate_urls=$(jq 'group_by(.url) | map(select(length > 1))' "$music_list_file")
if [[ $(echo "$duplicate_urls" | jq 'length') != 0 ]]; then
	echo "Duplicate URL(s) detected. Please check the following objects below for duplicate URLs"
	echo "$duplicate_urls"
	exit 1
fi

cd "$output_dir" || exit

echo "$music_info_list" | while read -r music_info; do
	url=$(echo "$music_info" | jq -r '.url')
	artist_first_name=$(echo "$music_info" | jq -r '.artist_first_name')
	artist_last_name=$(echo "$music_info" | jq -r '.artist_last_name')
	track_name=$(echo "$music_info" | jq -r '.track_name')
	performer_first_name=$(echo "$music_info" | jq -r '.performer_first_name')
	performer_last_name=$(echo "$music_info" | jq -r '.performer_last_name')
	year=$(echo "$music_info" | jq -r '.year')

	file_name="${artist_last_name} - ${track_name} (${performer_last_name})"
	file_name_ext="${file_name}.m4a"
	if [ -f "$file_name_ext" ]; then
		echo "File ${file_name_ext} already exists"
		continue
	fi

	echo "Downloading file ${file_name_ext}"
	yt-dlp --cookies-from-browser firefox -t aac "$url" -o "${file_name}.%(ext)s"
	echo "Downloaded file ${file_name_ext}"

	exiftool \
		-title="$track_name" \
		-artist="$artist_first_name $artist_last_name" \
		-performer="$performer_first_name $performer_last_name" \
		-year="$year" \
		"$file_name_ext"
	echo "Set metadata for ${file_name_ext}"
done

rm ./*.m4a_original
