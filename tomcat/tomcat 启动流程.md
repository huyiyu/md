# tomcat 启动流程

> 结合源码分析,tomcat 启动流程遵循以下流程:

## 附录

### tomcat 监听器和生命周期对象关系逻辑

#### StandardServer

* **NamingContextListener-CONFIGURE_START_EVENT**: 
* **VersionLogger-INITIALIZING**:  打印tomcat版本,命令行参数,系统参数等信息
* **AprLifecycle-INITIALIZING**:  检查apr扩展是否安装,默认不会安装,如果安装了 执行Library.init() 做APR启动工作,APR 是apache 对请求封装的处理
* **JreMemoryLeakPrevention-INITIALIZING**:tomcat 对于类加载器错误使用引起的内存泄漏的解决方案    执行GC.requestLatency
* **ThreadLocalLeakPrevention-STARTING_PREP**:为 Engine,Host,Context 注册当前Listener
* **GlobalResourcesLifecycle-STARTING**:创建全局的JNDI资源,默认配在 server.xml
* **ThreadLocalLeakPrevention-STOPPING_PREP**:修改当前serverStoping 值为true
* **GlobalResourcesLifecycle-STOPPING**:销毁全局JNDI资源
* **ThreadLocalLeakPrevention-STOPPED**: 关闭ProtocolHandler的线程池
* **AprLifecycle-DESTROYED**: 执行native 方法 Library.terminate() 做一些APR的清理工作

#### StandardService(空)

#### StandardEngine

* **HostConfig-START_EVENT**: 输出 engine 启动日志
* **HostConfig-STOP_EVENT**: 输出 engine 结束日志

#### mapperListener(空)

#### connector(空)

## 参考文献

1. [b.Jre Memory Leak Prevention Listener](https://www.cnblogs.com/yuantongaaaaaa/p/10313326.html)
2. [Tomcat DataSource JNDI Example in Java](https://www.journaldev.com/2513/tomcat-datasource-jndi-example-java)
