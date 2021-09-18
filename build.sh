#!/usr/bin/env bash
set -e
CUR_DIR=$(cd $(dirname $0);pwd)
function build(){
    GIT_URL="http://${GITLAB_USER:-user001}:${GITLAB_AT}@gitlab.yonghui.cn/my1233-s2b-trading/$1.git"
    if [ -d $1 ];then
        rm -rf ${CUR_DIR}/$1
    fi;
    git clone $GIT_URL
    cd ${CUR_DIR}/$1
    count=$(git branch -a|grep ${CI_COMMIT_REF_NAME}|wc -l)
    if [ $count != 0 ];then
      git checkout ${CI_COMMIT_REF_NAME}
      env_name=$(get_env)
      ls /root/.m2/repository-$env_name
      mvn clean install -Dmaven.test.failure.ignore=true -DskipTests=true -Dmaven.repo.local=/root/.m2/repository-$env_name -U
    fi
    cd ${CUR_DIR}
    rm -rf ${CUR_DIR}/$1
}

function build_dependency(){
    for PRO in $DEPENDENCY_LIST ;do
        build $PRO
    done
}

function get_env(){
    if [[ "${CI_COMMIT_REF_NAME}" =~ dev[0-9]* ]]; then
        echo "dev"
    elif [[ "${CI_COMMIT_REF_NAME}" =~ sit[0-9]* ]] || [[ "${CI_COMMIT_REF_NAME}" =~ sit[0-9]* ]]; then
        echo "sit"
    elif [[ "${CI_COMMIT_REF_NAME}" == "master" ]] || [[ "${CI_COMMIT_REF_NAME}" == "release-"* ]] || [[ "${CI_COMMIT_REF_NAME}" == "hotfix-"* ]];then
        echo "prod"
    else
        echo "dev"
    fi
}
function main(){	
    if [[ -n ${BUILD_ARCH} ]] &&  [[ ${BUILD_ARCH} == true ]];then
      build framework-all
    fi
    if [[ -n ${BUILD_SUPPORT} ]] && [[ ${BUILD_SUPPORT} == true ]];then
      build support
    fi
    if [[ -n ${DEPENDENCY_LIST} ]];then
      build_dependency
    fi
    env_name=$(get_env)
    mvn clean package -Dmaven.test.failure.ignore=true -DskipTests=true -Dmaven.repo.local=/root/.m2/repository-$env_name -U
}
main $*

