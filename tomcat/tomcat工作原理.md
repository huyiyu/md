# tomcat 工作原理

## 1.Lifecycle 接口

> Lifecycle是组件标准生命周期方法的顶层接口,组件会实现部分或全部方法来提供一定的机制启动和停止组件,拥有init,start,stop,destroy,状态如下所示。

```
 -----------------------------
|                            |
|  init()                    |
NEW -»-- INITIALIZING        |
| |           |              |     ------------------«-----------------------
| |           |auto          |     |                                        |
| |          \|/    start() \|/   \|/     auto          auto         stop() |
| |      INITIALIZED --»-- STARTING_PREP --»- STARTING --»- STARTED --»---  |
| |         |                                                            |  |
| |destroy()|                                                            |  |
| --»-----«--    ------------------------«--------------------------------  ^
|     |          |                                                          |
|     |         \|/          auto                 auto              start() |
|     |     STOPPING_PREP ----»---- STOPPING ------»----- STOPPED -----»-----
|    \|/                               ^                     |  ^
|     |               stop()           |                     |  |
|     |       --------------------------                     |  |
|     |       |                                              |  |
|     |       |    destroy()                       destroy() |  |
|     |    FAILED ----»------ DESTROYING ---«-----------------  |
|     |                        ^     |                          |
|     |     destroy()          |     |auto                      |
|     --------»-----------------    \|/                         |
|                                 DESTROYED                     |
|                                                               |
|                            stop()                             |
----»-----------------------------»------------------------------
```

而所有 lifecycleBase 的子类都会继承LifeCycleBase 通用模板,所以子类均遵循以下规定

* 新建对象时 **state**  为 **NEW**
* 执行 **init** 方法会先将状态设置成 **INITIALIZING** ,并触发监听器的 **lifecycleEvent** 各个监听器去实现 **lifecycleEvent** 并通过判断事件的方式执行不同的逻辑,子类自行实现  **initInternal** 执行初始化逻辑 初始化完成后发布  **INITIALIZED** 事件
* 执行  **start**  方法先判断是否执行过  **init**,  没有先执行  **init** 方法,使 **state** 流转到  **INITIALIZED**  。后续 start方法执行逻辑和init 相似，发布  **STARTING_PREP**  事件,执行各个子类实现的不同的  **startInternal** 如果成功内部需要把 state 改为  **STARTING** ,失败改为 **FAILED** ；**start** 对 **startInternal** 所修改的状态做判断来决定是否执行**stop** 或 **destroy**
* 当容器优雅停止时通过方法  **setStateInternal** 发布停止事件,启动失败时通过 **fireLifecycleEvent**  发布停止事件,两方法逻辑没有差别启动失败时,应立即停止相关事物所以调用
  **fireLifecycleEvent** 。然后执行 **stopInternal** 真正停止。停止后将状态改为 **STOPPED** 最终在finally块中调用 **destroy** 做清理工作释放资源
* 调用 **destroy** 方法时,如果状态为 **FAILED**  先尝试执行 **stop** 停止,发布 **DESTROYING** 事件,调用 **destroyInternal** 方法,最终发布 **DESTROYED** 事件

## 3.tomcat 启动流程

> tomcat 启动流程可用下图表示,本质上就是各个LifeCycle子类对象的 init 和 start 过程
> ![tomcat的启动流程](tomcat1.png)

### 设置 CATALINA_BASE 和 CATALINA_HOME

> [官网](https://tomcat.apache.org/tomcat-9.0-doc/introduction.html)对CATALINA_BASE 和CATALINA_HOME 的解释认为 CATALINA_HOME 是tomcat 的安装目录,而CATALINA_BASE是配置目录,设置该信息的代码存在于 [Bootstrap]([https://github.](https://github.com/huyiyu/tomcat/blob/huyiyu/java/org/apache/catalina/startup/Bootstrap.java#L81))的 static 代码块中,具体可看代码注释

### 初始化 Bootstrap

1. 通过 配置的catalina.properties 的 common.loader catalina.loader shared.loader 创建三个 URLClassLoader并配置类加载目录,
2. 默认情况下commonLoader加载的目录为 CATALINA_BASE/lib 下面的内容,该内容将会在 server.init 过程中加载这些 class 和 jar 包。而catalina.loader 和shared.loader默认为空,不加载任何内容 但仍会新建urlClassLoader
3. 使用Catalina.loader 初始化类,反射调用Catalina 对象的setParentClassLoader 设置进去

### 加载 Catalina

> bootstrap load 内部通过反射调用catalina.load 首先会执行 initNaming 设置JNDI所需的系统属性 `catalina.useNaming=true` 以及 ` java.naming.factory.initial=org.apache.naming.java.javaURLContextFactory` 其次进入 digest 解析并创建xml 从parseServerXml 找到 createStartDigester,此处介绍下 Digester 的逻辑,当 Digester 调用Parse 时会开始解析并匹配 XML标签 并在匹配过程中调用 Rule 的 begin(标签开始时)，body(标签体内部),end(标签结束时)的逻辑, 通过自定义实现 Rule 来达到解析的目的,同事Tomcat 提供了几个常见的实现

| 规则类            | 描述                                                                                                                     |
| ----------------- | ------------------------------------------------------------------------------------------------------------------------ |
| ObjectCreateRule  | begin 调用时通过 xml 对应属性 ClassName 记录的类创建对象,如果 className 为空,使用参数传入的 ClassName , end() 调用时取出 |
| SetPropertiesRule | begin调用时通过解析set方法将属性值装配给栈顶的对象                                                                       |
| SetNextRule       | end 方法调用时将当前对象通过某个方法敷给栈上的下一个对象   
                                                              |
原始的server.xml
```xml
<?xml version="1.0" encoding="UTF-8"?>
<Server port="8005" shutdown="SHUTDOWN">
  <Listener className="org.apache.catalina.startup.VersionLoggerListener" />
  <Listener className="org.apache.catalina.core.AprLifecycleListener" SSLEngine="on" />
  <Listener className="org.apache.catalina.core.JreMemoryLeakPreventionListener" />
  <Listener className="org.apache.catalina.mbeans.GlobalResourcesLifecycleListener" />
  <Listener className="org.apache.catalina.core.ThreadLocalLeakPreventionListener" />
  <GlobalNamingResources>
    <Resource name="UserDatabase" auth="Container" type="org.apache.catalina.UserDatabase" description="User database that can be updated and saved" factory="org.apache.catalina.users.MemoryUserDatabaseFactory" pathname="conf/tomcat-users.xml" />
  </GlobalNamingResources>
  <Service name="Catalina">
    <Connector port="8080" protocol="HTTP/1.1" connectionTimeout="20000" redirectPort="8443" />
    <Engine name="Catalina" defaultHost="localhost">
      <Realm className="org.apache.catalina.realm.LockOutRealm">
        <Realm className="org.apache.catalina.realm.UserDatabaseRealm" resourceName="UserDatabase"/>
      </Realm>
      <Host name="localhost"  appBase="webapps" unpackWARs="true" autoDeploy="true">
        <Valve className="org.apache.catalina.valves.AccessLogValve" directory="logs" prefix="localhost_access_log" suffix=".txt" pattern="%h %l %u %t &quot;%r&quot; %s %b" />
      </Host>
    </Engine>
  </Service>
</Server>
```
```java
// 创建server 对象
        digester.addObjectCreate("Server",
                                 "org.apache.catalina.core.StandardServer",
                                 "className");
        //为server 对象设置XML标签中的属性 port="8005" shutdown="SHUTDOWN"
        digester.addSetProperties("Server");
        //catalina 调用setServer,设置Server对象这行代码在server节点结束执行(最后)
        digester.addSetNext("Server",
                            "setServer",
                            "org.apache.catalina.Server");
        // 调用创建GlobalNamingResources
        digester.addObjectCreate("Server/GlobalNamingResources","org.apache.catalina.deploy.NamingResourcesImpl");
        //为GlobalNamingResources 设置属性值
        //              name="UserDatabase" auth="Container"
        //              type="org.apache.catalina.UserDatabase"
        //              description="User database that can be updated and saved"
        //              factory="org.apache.catalina.users.MemoryUserDatabaseFactory"
        //              pathname="conf/tomcat-users.xml"
        digester.addSetProperties("Server/GlobalNamingResources");
        // 将GlobalNamingResource 配给Server
        digester.addSetNext("Server/GlobalNamingResources","setGlobalNamingResources","org.apache.catalina.deploy.NamingResourcesImpl");
        //创建Listener 对象 listener 对象可以使用optional=true 认为是可选的Listener
        digester.addRule("Server/Listener",
                new ListenerCreateRule(null, "className"));
        digester.addSetProperties("Server/Listener");
        digester.addSetNext("Server/Listener",
                            "addLifecycleListener",
                            "org.apache.catalina.LifecycleListener");
        // 创建service 对象
        digester.addObjectCreate("Server/Service",
                                 "org.apache.catalina.core.StandardService",
                                 "className");
        // 装配service 属性 name="Catalina"
        digester.addSetProperties("Server/Service");
        // 结束时将servicer装配给server
        digester.addSetNext("Server/Service","addService","org.apache.catalina.Service");
        // 创建Listener对象 此处className 为空 因为xml中已经指定
        digester.addObjectCreate("Server/Service/Listener",null,"className");
        // 装配属性 SSLEngine="on"
        digester.addSetProperties("Server/Service/Listener");
        // 设置回Listener
        digester.addSetNext("Server/Service/Listener","addLifecycleListener","org.apache.catalina.LifecycleListener");
        //创建 Executor 对象
        digester.addObjectCreate("Server/Service/Executor","org.apache.catalina.core.StandardThreadExecutor","className";
        // 装配 Executor 属性
        digester.addSetProperties("Server/Service/Executor");
        // 将配置的Executor 装配给Service
        digester.addSetNext("Server/Service/Executor","addExecutor","org.apache.catalina.Executor");
        // 创建Connector 对象
        digester.addRule("Server/Service/Connector",new ConnectorCreateRule());
        // 设置Connector 的属性值 port="8080" protocol="HTTP/1.1" connectionTimeout="20000" redirectPort="8443"                  
        digester.addSetProperties("Server/Service/Connector",new String[]{"executor", "sslImplementationName","protocol"});
        // 将Connector 设置回 Service 
        digester.addSetNext("Server/Service/Connector","addConnector","org.apache.catalina.connector.Connector");
        // 设置端口的偏移量 默认为 0 所以 8005
        digester.addRule("Server/Service/Connector", new AddPortOffsetRule());
        // 创建 SSLHostConfig 对象 默认没有
        digester.addObjectCreate("Server/Service/Connector/SSLHostConfig","org.apache.tomcat.util.net.SSLHostConfig");
        digester.addSetProperties("Server/Service/Connector/SSLHostConfig");
        digester.addSetNext("Server/Service/Connector/SSLHostConfig","addSslHostConfig","org.apache.tomcat.util.net.SSLHostConfig");
        // 设置 Certificate 的创建 默认没有
        digester.addRule("Server/Service/Connector/SSLHostConfig/Certificate",new CertificateCreateRule());
        digester.addSetProperties("Server/Service/Connector/SSLHostConfig/Certificate", new String[]{"type"});
        digester.addSetNext("Server/Service/Connector/SSLHostConfig/Certificate","addCertificate","org.apache.tomcat.util.net.SSLHostConfigCertificate");
        // 设置 OpenSSLConf 的创建 默认没有
        digester.addObjectCreate("Server/Service/Connector/SSLHostConfig/OpenSSLConf","org.apache.tomcat.util.net.openssl.OpenSSLConf");
        digester.addSetProperties("Server/Service/Connector/SSLHostConfig/OpenSSLConf");
        digester.addSetNext("Server/Service/Connector/SSLHostConfig/OpenSSLConf","setOpenSslConf","org.apache.tomcat.util.net.openssl.OpenSSLConf");
        // 设置 OpenSSLConfCmd 的创建 默认没有
        digester.addObjectCreate("Server/Service/Connector/SSLHostConfig/OpenSSLConf/OpenSSLConfCmd","org.apache.tomcat.util.net.openssl.OpenSSLConfCmd");
        digester.addSetProperties("Server/Service/Connector/SSLHostConfig/OpenSSLConf/OpenSSLConfCmd");
        digester.addSetNext("Server/Service/Connector/SSLHostConfig/OpenSSLConf/OpenSSLConfCmd","addCmd","org.apache.tomcat.util.net.openssl.OpenSSLConfCmd");
        // 设置 connector的Listener 的创建 默认没有
        digester.addObjectCreate("Server/Service/Connector/Listener",null,"className");
        digester.addSetProperties("Server/Service/Connector/Listener");
        digester.addSetNext("Server/Service/Connector/Listener","addLifecycleListener","org.apache.catalina.LifecycleListener");
        // 设置 UpgradeProtocol 的创建 默认没有
        digester.addObjectCreate("Server/Service/Connector/UpgradeProtocol",null,"className");
        digester.addSetProperties("Server/Service/Connector/UpgradeProtocol");
        digester.addSetNext("Server/Service/Connector/UpgradeProtocol","addUpgradeProtocol","org.apache.coyote.UpgradeProtocol");
        // RuleSet内部本质上封装了Xml解析
        digester.addRuleSet(new NamingRuleSet("Server/GlobalNamingResources/"));
        digester.addRuleSet(new EngineRuleSet("Server/Service/"));
        digester.addRuleSet(new HostRuleSet("Server/Service/Engine/"));
        digester.addRuleSet(new ContextRuleSet("Server/Service/Engine/Host/"));
        addClusterRuleSet(digester, "Server/Service/Engine/Host/Cluster/");
        digester.addRuleSet(new NamingRuleSet("Server/Service/Engine/Host/Context/"));
        // When the 'engine' is found, set the parentClassLoader.
        digester.addRule("Server/Service/Engine",new SetParentClassLoaderRule(parentClassLoader));
        addClusterRuleSet(digester, "Server/Service/Engine/Cluster/");
```

## 附录

### 如何编译tomcat

> 参照 huyiyu tomcat 分支 [README](https://github.com/huyiyu/tomcat/)
