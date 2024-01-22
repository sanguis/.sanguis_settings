get_links() {
	local csv_file=$1
	local column1_name=$2
	local column2_name=$3

	[[ ! -f $csv_file ]] && echo "links file not found." && return
	[[ $DEBUG ]] && echo "inputs:
	csv_file=$csv_file
	column1_name=$column1_name
	column2_name=$column2_name
	"

	declare -A assoc_array
	local header_line=1
	while IFS=, read -r "${column1_name}" "${column2_name}"; do
		if [[ "$header_line" == "1"  ]]; then
			header_line=0
			continue
		fi
		[[ $DEBUG ]] &&  echo ${column1_name?}
		$assoc_array["${column1_name}"]="${column2_name}"
	done < $csv_file

	if [[ $DEBUG  ]]; then
		echo "CSV file '$csv_file' has been converted to an ssociative array"
		for k in "${assoc_array[@]}"; do
			echo "Key: $k, Value: ${assoc_array_name[$key]}"
		done
	fi
	return $assoc_array

}
get_links $1 $2 $3


