#!/bin/bash
# 用于构建manager系统
set -e 

cur_dir=$(cd $(dirname $0); pwd)
root_dir=$(cd ${cur_dir}/..; pwd)
cur_user="$(id -u):$(id -g)"
registry="lhn-docker.pkg.coding.net/manager-server/dev"
appName=$1
push=$2
sha1_version=$(git rev-parse --short HEAD)



function push(){
    if [ ${push}=='--push' ];then
    	echo $PASSWORD | docker login -u ${USERNAME} lhn-docker.pkg.coding.net --password-stdin
	    docker push ${registry}/${appName}:${sha1_version}
        docker push ${registry}/${appName}
    fi

}
function status() {
  echo -e "\033[35m >>>   $*\033[0;39m"
}

function import_db_data() {
    db_container=$(docker-compose ps | grep dco_mysql_1 | awk '{print $1}')
    for sql_file in "$@"; do
        status "importing ${sql_file}..."
        docker exec -i ${db_container} mysql --default-character-set=utf8 -uroot -p123456 manager_db < ${sql_file}
    done
}

function init_db(){
    core_schema="${cur_dir}/mysql/schema/schema.sql";
    db_container=$(docker-compose ps | grep dco_mysql_1 | awk '{print $1}')
    if [ ! -e db_container ];then
        docker-compose up -d mysql
        db_container=$(docker-compose ps | grep dco_mysql_1 | awk '{print $1}')
    fi


    status 'waiting for container up.'
    docker exec ${db_container} bash -c \
            "until \$(mysql -p123456 -e '\s' > /dev/null 2>&1); do \
                printf '.' && sleep 1; \
             done; echo"
    import_db_data ${core_schema}
    import_sql "${cur_dir}/mysql/init_data"
}

function import_sql() {
    for filename in $@;do
        if [ -d $filename ];then
            cd $filename
            declare -a dir_list=$(ls)
            import_sql ${dir_list[@]}
        elif [ -f $filename ];then
            import_db_data $filename
        fi
    done
}

function server(){
    cd ${root_dir}
    mvn package -Dmaven.test.skip=true
    docker build -t "${registry}/server:${sha1_version}" .
    docker tag "${registry}/server:${sha1_version}" "${registry}/server:latest"
    push
}

function frontend(){
   ${cur_dir}/dco_lin build
   docker tag "${registry}/frontend:latest" "${registry}/frontend:${sha1_version}"
   push
}

function install(){
    init_db
    server
    front
    docker-compose up -d;
}

cd ${cur_dir}
case "$1" in
    server)
        server
        ;;
    frontend)
        frontend
        ;;
    init_db)
        init_db
        ;;
    import_sql)
	params=$*
        declare -a arr=($params)
        import_sql ${arr[@]:1}
	;;
    install)
        install
        ;;
    *)
        echo "USAGE:${0} |server|front|init_db|install|import_sql file1 file2..."
    ;;
esac
