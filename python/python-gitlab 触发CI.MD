# python-gitlab 批量触发CI
## 1 项目地址
> https://github.com/huyiyu/scripts/tree/main/python/gitlab
## 2 背景

> 本人是 JAVA 开发工程师,公司微服务项目仓库较多,每次打包要么去页面触发CI,要么提交代码触发,并需要找到docker tag 的版本号用于部署,每次大版本升级发版到半夜,为了应对这个费时费力的流程。决定解决这一痛点

## 3 技术选型
1. 官方提供了足够强大的 [python-gitlab](https://python-gitlab.readthedocs.io/en/stable/) 客户端
2. java 开发没有原生模块化支持 Maven 或 gradle 体系注定了不适用于简单脚本编写
3. gitlab-cli 的使用参数多,复杂限制了使用人群 
4. python-gitlab 未提供健康检查等机制使得应用只能触发而不能获得结果,可使用 python 协程调度机制实现
5. 解释型语言具有即用即改的优点,便于使用者发现bug之后直接通过修改代码的方式解决bug


## 4 实现

首先需要安装python-gitlab (可使用项目中的requirements.txt)
```bash
pip install python-gitlab ==  1.15.0 
pip install requests == 2.25.1
```
### 4.1 编写一个花里胡哨的界面
> 一个简洁美观的使用界面可以让使用者赏心悦目
```python
        _  _    _         _     
  __ _ (_)| |_ | |  __ _ | |__  
 / _` || || __|| | / _` || '_ \ 
| (_| || || |_ | || (_| || |_) |
 \__, ||_| \__||_| \__,_||_.__/ 
 |___/    
Usage:
    s2bctl.py [command] [branch] [option]
Available Commands:
    protect               set protect branch for project
    run-ci                trigger ci for project
    unset-protect         unset protect branch for project
Available Option:
    web   web project
    src   src project
    all   all project
    ...
```
### 4.2 抽取配置信息
* 新建文件 env.py 用于存放环境变量
```python
# gitlab 主机网址(一般是内网地址)
URL = ******
# 选择对应的namespace 公司的不同namespace一般提供给不同的团队使用
NAMESPACE = 'namespace'
# gitlab access token
TOKEN = token
# 填所有平时开发涉及的项目
PROJECTS = ['p1-web','p1-src','p2-web','p2-src']
# 笔者公司的分组 可自定义这个分组 如 API WEB CORE FRAMEWORK 等
SRC_PROJECTS = ['p1-src','p2-src']
WEB_PROJECTS = ['p1-web','p2-web']
# CI 环境变量
CI_VARIABLE = [{'key': 'BUILD_ARCH', 'value': 'false'}, {'key': 'BUILD_SUPPORT', 'value': 'false'}]
# banner 图 需要转义反斜杠
VIEW = '''
Usage:
    s2bctl.py [command] [option]
Available Commands:
    protect               set protect branch for project 
    run-ci                trigger ci for project
    unset-protect         unset protect branch for project 
Available Option:
    --branch    branch name
    --env       environment name
    --project   project list split with ","
    --file      deploy yaml file
    ...
'''
```
### 4.3 编写参数处理
* python 脚本参数可从 sys.args获取,第一个参数是脚本名称,其余是自定义参数(类似bash)
* 使用python 脚本时在第一行指定使用的python 解释器路径
```python
if __name__ == '__main__':
    # 小于三个参数 看帮助界面
    if len(sys.argv) < 3: 
        help_msg()
    # 获取传入参数切片 从索引为2(第三个参数)开始,0为脚本 1为子命令
    arg_dicts=parse_arg(sys.argv[2:])
    if sys.argv[1] == 'protect':
        protect_branch(arg_dicts)
    elif sys.argv[1] == 'run-ci':
        run_ci(arg_dicts)
    elif sys.argv[1] == 'unset-protect':
        unset_protect(arg_dicts)
    else:
        # 其他命令 乖乖帮助界面
        help_msg()


def parse_project(value):
    # 解析项目参数 如 用web代替env定义的列表等
    if value == 'web':
        return env.WEB_PROJECTS
    elif value == 'src':
        return env.SRC_PROJECTS
    elif value == 'all':
        return env.PROJECTS
    else:
        project_list=[]
        for pro in value.split(','):
            if pro not in env.PROJECTS:
                print(f"项目 {pro} 不是业务中台项目")
                sys.exit(127)
            project_list.append(pro)
        return project_list

def parse_arg(cliArgs):
    arg_dicts = {}
    # 从分号切开 若参数是project 特殊处理,否则获取key value 放入dict中
    for arg in cliArgs:
        param=arg.split('=')
        if param[0] == "--project":
            project_list=parse_project(param[1])
            if len(param) > 0:
                arg_dicts['project'] = project_list
        else:
            arg_dicts[param[0][2:]] = param[1]
    return arg_dicts
```
### 4.4 编写触发CI逻辑
* 触发 CI 比较简单 直接调用 gitlab API 即可
* 触发 CI 后要监听CI状态,获取CI日志,当CI成功时 打印出`docker image` 版本 这一部分使用python asyncio 去做(类似于java 线程池)
* 抓取日志采用的策略是等待pipeline 的最后一个 job 完成后 获取
```python
async def getVersionFromLog(project, pipeline):
    build_job = None
    for job in pipeline.jobs.list():
        # 监测 docker build 的job状态
        if job.name == 'docker-build':
            build_job = job
    if build_job is None:
        return project.name,None
    # 当job 成功后退出线程
    while build_job.status != 'success':
        # 由于协程不像线程会自动挂起 需要手动设置等待挂起
        await asyncio.sleep(random.uniform(1, 3))
        # 当任务还没结束时打印 . flush=True 是必须的 否则.不能打印
        print(".", end='', flush=True)
        # 获取最新的 build_job 状态
        build_job = project.jobs.get(build_job.id)

    result = requests.get(url=build_job.web_url + '/raw', headers={"PRIVATE-TOKEN": env.TOKEN})
    if result.ok:
        # 按行读取日志 这里用'\n' 是因为 gitlab 执行时默认换行符为 \n 不能替换成 os.linesep
        for line in result.text.split('\n'):
            if line.startswith("Successfully tagged"):
                version = line.split(":")[1]
                print(f"\n版本号:{version} {project.name}项目CI已完成", flush=True)
                return project.name, version
    return project.name,None

async def fork_join_pipeline(jobs):
    # await 等待所有结果完成获得results
    results = await asyncio.gather(*jobs)
    print("所有CI任务结束:")
    deploy_yaml = dict(service={project_name: version for project_name, version in results})
    print(yaml.dump(deploy_yaml))
    with open('deploy.yaml', 'w+') as stream:
        yaml.dump(deploy_yaml, stream=stream, explicit_start=True)


def run_ci(branch, cliArgs):
    gl = gitlabInstance()
    jobs = []
    for project_name in parse_arg(cliArgs):
        project = gl.projects.get(env.NAMESPACE + "/" + project_name)
        try:
            # 这里调用接口完成CI pipeline创建
            pipeline = project.pipelines.create({'ref': branch, 'variables': env.CI_VARIABLE})
            print(f"OK:触发CI成功,分支: {branch} url: {pipeline.web_url} 项目: {project_name} ")
            if project_name in env.WEB_PROJECTS:
                # 这里设置监听任务列表
                jobs.append(getVersionFromLog(project, pipeline))
        except Exception as ex:
            print(f"ERROR:项目 {project_name} CI 失败,原因为:{ex}")
    asyncio.run(fork_join_pipeline(jobs))
```
## 5 演示效果
```bash
./python/src/s2bctl.py run-ci --project=ouser-web,oms-task,oms-dataex  --branch=sit
OK:触发CI成功,分支: sit url: http://gitlab.***.cn/pipelines/593364 项目: ouser-web 
OK:触发CI成功,分支: sit url: http://gitlab.***.cn/pipelines/593365 项目: oms-task 
OK:触发CI成功,分支: sit url: http://gitlab.***.cn/pipelines/593366 项目: oms-dataex 
.............................................................................................................................................................................
版本号:593364-2021.8.7-135841-sit ouser-web项目CI已完成
.
版本号:593365-2021.8.7-135846-sit oms-task项目CI已完成
..................
版本号:593366-2021.8.7-135926-sit oms-dataex项目CI已完成
所有CI任务结束:
service:
  oms-dataex: 593366-2021.8.7-135926-sit
  oms-task: 593365-2021.8.7-135846-sit
  ouser-web: 593364-2021.8.7-135841-sit
```
