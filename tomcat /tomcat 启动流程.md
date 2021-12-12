# tomcat 启动流程

> 结合源码分析,tomcat 启动流程遵循以下流程:

## 附录

### tomcat 监听器和生命周期对象关系逻辑

#### StandardServer

| 对象\监听器                      | NamingContext | VersionLogger | AprLifecycle | JreMemoryLeakPrevention | GlobalResourcesLifecycle | ThreadLocalLeakPrevention |
| :------------------------------- | :-----------: | :-----------: | :----------: | :---------------------: | :----------------------: | :-----------------------: |
| ***BEFORE_INIT_EVNET***  |               |      ✅      |      ✅      |           ✅           |                         |                           |
| ***AFTER_INIT_EVENT***   |               |               |             |                         |                         |                           |
| ***BEFORE_START_EVENT*** |               |               |             |                         |                         |            ✅            |
| ***START***              |               |               |             |                         |            ✅            |                           |
| ***AFTER_START***        |               |               |             |                         |                         |                           |
| ***BEFORE_STOP***        |               |               |             |                         |                         |            ✅            |
| ***STOP***               |               |               |             |                         |            ✅            |                           |
| ***AFTER_STOP***         |               |               |             |                         |                         |            ✅            |
| ***BEFORE_DESTROY***     |               |               |             |                         |                         |                           |
| ***AFTER_DESTROY***      |               |               |      ✅      |                         |                         |                           |

* **VersionLogger** (***BEFORE_INIT_EVNET***):  打印tomcat版本,命令行参数,系统参数等信息
* **AprLifecycle** (***BEFORE_INIT_EVNET***):  检查apr扩展是否安装,默认不会安装,如果安装了 执行Library.init() 做APR启动工作,APR 是apache 对请求封装的处理
* **JreMemoryLeakPrevention** (***BEFORE_INIT_EVNET***):tomcat 对于类加载器错误使用引起的内存泄漏的解决方案    执行GC.requestLatency
* **ThreadLocalLeakPrevention** (***BEFORE_START_EVENT***):为 Engine,Host,Context 注册当前Listener
* **GlobalResourcesLifecycle** (***START***):创建全局的JNDI资源,默认配在 server.xml
* **ThreadLocalLeakPrevention** (***BEFORE_STOP***):修改当前serverStoping 值为true
* **GlobalResourcesLifecycle** (***STOP***):销毁全局JNDI资源
* **ThreadLocalLeakPrevention** (***AFTER_STOP***): 关闭ProtocolHandler的线程池
* **AprLifecycle** (***AFTER_DESTROY***): 执行native 方法 Library.terminate() 做一些APR的清理工作

## 参考文献

1. [b.Jre Memory Leak Prevention Listener](https://www.cnblogs.com/yuantongaaaaaa/p/10313326.html)
2. [Tomcat DataSource JNDI Example in Java](https://www.journaldev.com/2513/tomcat-datasource-jndi-example-java)
