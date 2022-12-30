#!bin/bash
set -e !pipefail
cur_dir=$(cd $(dirname $0);pwd)


function change(){
    defualt_value=`sed -nr "s#[[:blank:]]*<meta name=\"$1\"[[:blank:]]+content=\"(.*)\".*>#\1#p" ${cur_dir}/index.html`
    if [[ -z ${defualt_value} ]];then
        echo "NEW: <meta name=\"$1\" content=\"$2\" />"
        headLine=$(grep -n '<head>' ${cur_dir}/index.html |awk -F ":" '{print $1}')
        sed -i "${headLine}a<meta name=\"$1\" content=\"$2\" />" ${cur_dir}/index.html
    else
        echo "REPLACE: $1, default=${defualt_value}, real=$2"
        sed -ri "s#([[:blank:]]*<meta name=\"$1\"[[:blank:]]+content=\").*(\".*>)#\1${2}\2#g" ${cur_dir}/index.html
    fi
}
envs=$(printenv|grep -E "(env|script)_")
for environment in ${envs[@]};do
    name=$(echo ${environment}|awk -F '=' '{print $1}')
    value=$(echo ${environment}|awk -F '=' '{print $2}')
    change ${name} ${value}
done
exec $*
