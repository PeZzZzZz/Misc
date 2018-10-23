
api="$1"
username="$2"
password="$3"
repo_name="$4"

if [[ "$1" == "c" ]]; then
  curl -u "$username:$password" https://api.github.com/user/repos -d '{"name":"'$repo_name'"}'
elif [[ "$1" == "d" ]]; then
  curl -u "$username:$password" -X DELETE https://api.github.com/repos/$username/$repo_name
else 
  echo "Paramètre incorrect"
fi
