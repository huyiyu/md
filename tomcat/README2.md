# tomcat 启动流程

## 准备知识
* java 安全 SecurityManager
    * [安全管理器](https://developer.aliyun.com/article/57223)
* 类加载机制
    * [类加载机制](https://zhuanlan.zhihu.com/p/72066969)
    * [线程上下文类加载器](https://www.cnblogs.com/549294286/p/3714692.html)
    * class.isAssignableFrom()
    * JMX 相关
* [socket 源码以及请求包的处理](https://chihminh.github.io/2016/07/28/java-socket-sc/)
    * [unix domain socket]()
* [为什么tomcat 要使用那么多的反射]()
* [CopyOnWriteArrayList ]()
* 设计模式
    * [命令模式]()
    * [观察者模式]()


## 配置文件说明

```bash
conf
├── Catalina
│   └── localhost
├── catalina.policy
├── catalina.properties 设置类加载器
├── context.xml
├── jaspic-providers.xml
├── logging.properties
├── server.xml tomcat 主配置文件
├── tomcat-users.xml
└── web.xml
```
## 官方文档说明


## listener 功能说明








## 脚本启动流程

* startup.sh
    * 使用 \$0 判断当前路径从而推导出 catelina.sh 执行路径 最终执行 ```bash catelina.sh start $@ ``` 
* catlina.sh
    * 判断当前项目路径
    * 设置环境变量 CATELINA_HOME
    * 设置环境变量 CATELINA_BASE
    * 如果 CATELINA_BASE 目录下存在脚本 setenv.sh 则执行它(tomcat 默认不提供这个脚本)
    * 如果存在 setclasspath.sh 那么执行(默认存在)
        * 匹配 JAVA_HOME
        * 匹配 JRE_HOME
        * 定义 endorsed.dir (jdk9之后不再支持)
        * 定义 _RUN_JAVA 变量方便调用 java
        * 定义 _RUN_JDB 变量方便 debug
    * 将 bootstrap.jar 添加到 classpath 路径下
    * 指定 CATELINA_OUT 变量指向当前路径下logs/catelina.out
    * 指定 CATALINA_TMPDIR 指向当前路径 temp 目录
    * 将 tomcat-juli.jar 添加到 classpath 路径下
    * 设置tomcat日志配置
    * 提供默认权限
    * 定义 JAVA_OPTS
    * 判断是否要开启nohup
    * 如果第一个参数等于jpda 则开启远程 debug 并去掉第一个参数
    * 如果第一个参数等于debug 则使用jdb调试tomcat 并去掉第一个参数 否则使用java
    * 如果第一个参数是security 那么启用安全管理器运行
    * ...(其他内容不那么重要)
## 项目启动流程 
* Bootstrap
    * 获取 系统参数 user.dir 
    * 获取 系统参数 catelina.base 
    * 设置 系统参数 catelina.home = catelina.base
    * 创建 BootStrap 对象
    * 调用 bootstrap.init()
        * 初始化类加载器
            * 初始化成员变量 commonclassloader
                * 获取 commonLoader 系统变量 一般为 `"${catalina.base}/lib","${catalina.base}/lib/*.jar","${catalina.home}/lib","${catalina.home}/lib/*.jar"`
                * 使用 之前定义的系统变量替换占位符
                * 处理好路径关系后使用urlclassloader 路径为以上四个
            * 初始化成员变量 catalinaLoader: 由于默认没有设置系统变量 server.loader 所以使用common.loader
            * 初始化成员变量 sharedLoader: 由于默认没有设置系统变量 shared.loader 所以使用common.loader
        * 设置线程上下文classloader 为 catalinaLoader
        *  使用类加载器加载类 ***为了执行静态代码块中的内容*** 
           * loadCorePackage(loader);
           * loadCoyotePackage(loader);
           * loadLoaderPackage(loader);
           * loadRealmPackage(loader);
           * loadServletsPackage(loader);
           * loadSessionPackage(loader);
           * loadUtilPackage(loader);
           * loadJavaxPackage(loader);
           * loadConnectorPackage(loader);
           * loadTomcatPackage(loader);
           * 加载 org.apache.catalina.startup.Catalina 类
            * 反射调用无参构造
                * 创建securityConfig 对象 该对象有两个属性通过loadclass 加载catelina.properties 加载
                * 调用方法 ExceptionUtils.preload() 扩展点
            * 反射调用 setClassLoader(sharedLoader)
            * 将反射对象保存到成员变量 catelinadaemon
    * 将初始化完成的bootstrap 赋给成员变量daemon
    * 为主线程设置线程上下文类加载器
    * 判断main 方法参数 $1
        * startd/start
           * boostrap.setAwait(true)
                * 反射调用 catelina.setAwait(true) 表示开放远程关闭端口 方便停机
           * boostrap.load(args)
                * 反射调用 catelina.load(args)
                    * 设置isGenerateCode=false
                    * initNaming()
                        * 设置系统属性 catalina.useNaming=true
                        * 尝试获取 java.naming.factory.url.pkgs 如果没有,设置为 org.apache.naming
                        * 尝试获取属性 java.naming.factory.object 如果没有设置为 org.apache.naming.java.javaURLContextFactory
                    * ***解析 server.xml*** digest分析
                    * 包装输出流和错误流 (可以改变系统输出)
                    * server.init()
                        * 将状态设置为INITIALIZING,并广播给监听器
                            * AprLifecycleListener 监听到初始化状态
                                *  尝试从 "tcnative-1", "libtcnative-1" 下加载文件
                            * JreMemoryLeakPreventionListener 监听到初始化  
                                * 执行GC.requestLatency(Long.MAX_VALUE - 1)
                        * 初始化内部容器
                            * 创建JMXMBeanServer
                            * 注册 standardServer
                            * 初始化一个2容量的线程池
                            * 注册连接池
                            * 注册 stringcache
                            * 注册 MBeanFactory
                            * 初始化 globalNamingResources
                                * 初始化内部容器
                                    * 注册 globalNamingResources
                                    * 注册所有 contextResource 默认有一个userdatabase
                                    * 注册所有 contextEnvironment 默认没有
                                    * 注册所有 contextResourceLink 默认没有
                            * 将lib目录下的包统一加入系统资源
                            * 初始化所有service 默认只有一个
                                * 初始化内部容器
                                    * 注册 standardService
                                    * 初始化 engine
                                        * 将状态设置为INITIALIZING,并广播给监听器 默认 EngineConfig 一个监听器
                                        * 初始化内部容器
                                            * 调用 getRealm 方法保证创建出来一个realm
                                            * 创建线程池默认值为1
                                            * 注册 engine
                                        * 将状态设置为INITIALIZED,并广播给监听器 默认 EngineConfig 一个监听器
                                    * 初始化所有线程池 默认没配置
                                    * 初始化 mapperListener
                                        * 注册 mapperListener
                                    * 初始化 connector
                                        * 注册 connector
                                            * 填充默认 coyote
                                            * 是指utility线程池
                                            * 设置 设置解析请求体方法，默认为post
                                            * protocolHandler 初始化
                                                * 注册 ProtocolHandler 默认 Http11NioProtocol
                                                * 注册全局请求处理器
                                                * endpoint 初始化
                                                    * 绑定默认8080端口 使用阻塞模式
                                                    * 设置SSL 默认不开启
                                                    * 修改绑定状态
                                                    * 注册 endpoint
                                                    * 注册 socketproperties 
                        * 将状态设置为INITIALIZED,并广播给监听器     
           * bootstrap.start()
                * 设置状态为 STARTING_PREP 并广播给监听器
                    * ThreadLocalLeakPreventionListener 监听到启动检测状态
                        * 为所在engine 设置 ThreadLocalLeakPreventionListener 生命周期监听
                * 初始化内部
                    * 设置状态为 CONFIGURE_START_EVENT 并广播给监听器
                        * ***NamingContextListener 监听到状态变更***
                    * 设置状态为 STARTING 并广播给监听器        
                        * ***GlobalResourcesLifecycleListener 监听到状态变更***
                    * globalNamingResources.start()
                    *  service.start() 
                        *  engine.start()
                            * realm.start()
                            * pipeline.start()
                                * standardHost.init()
                                    * 设置host属性 
                    * 设置状态为 PERIODIC_EVENT 并广播

## 停机流程




## 请求流程




## 部署流程