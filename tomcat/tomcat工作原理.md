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
![tomcat的启动流程](tomcat1.png)
### 设置 CATALINA_BASE 和 CATALINA_HOME 
> [官网](https://tomcat.apache.org/tomcat-9.0-doc/introduction.html )对CATALINA_BASE 和CATALINA_HOME 的解释认为 CATALINA_HOME 是tomcat 的安装目录,而CATALINA_BASE是配置目录,设置该信息的代码存在于[Bootstrap]([https://github.](https://github.com/huyiyu/tomcat/blob/huyiyu/java/org/apache/catalina/startup/Bootstrap.java#L81))的 static 代码块中,具体可看代码注释
### 初始化 Bootstrap


## 附录
### 如何编译tomcat
>参照 huyiyu tomcat 分支[README](https://github.com/huyiyu/tomcat/)
### 