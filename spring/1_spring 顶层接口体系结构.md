# Spring 顶层接口体系结构

## BeanFactory 体系结构
![类图](../img/BeanFactory.png)
### SimpleAliasRegistry  
#### 属性
* aliasMap: 保存所有别名的Map,BeanName 是特殊的别名(只有key 没有value),别名可以指向另一个别名
#### 方法
* registerAlias: 注册别名
  * 别名和自身相同时,尝试移除这个别名
  * 别名已经存在
    * value 存在则跳过
    * 是否允许别名覆盖,不允许抛出异常,允许直接覆盖,默认是允许的
    * 检查是否有循环依赖问题(别名最终指向了自己成为循环依赖)
* allowAliasOverriding:
* canonicalName: 这个方法可以返回最终的名称 BeanName,逻辑是遍历aliasMap 直到找到最终没有value 的key
* checkForAliasCircle: 这个方法输入两个入参,用于判断是否循环别名依赖,逻辑是递归 hasAlias 判断是否 key 最终指向value 且value 最终指向key
* hasAlias: 同上文介绍
### DefaultSingletonBeanRegistry

### FactoryBeanRegistrySupport

### AbstractBeanFactory

### AbstractAutowireCapableBeanFactory

### DefaultListBeanFactory
## ApplicationContext 体系结构
![类图](../img/ApplicationContext.png)