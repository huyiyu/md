,

# ProxyConfig

## 思考

* 问题1？
* 问题2？

## 属性

### proxyTargetClass

设置是否强制代理目标类(使用 cglib 代理)默认值 false,此时使用cglib

### optimize
>设置代理是否应该执行积极的优化。 “积极优化”的确切含义因代理而异，但通常会有一些权衡。默认为“假”。 
例如，优化通常意味着在创建代理后通知更改不会生效。
因此，默认情况下禁用优化。如果其他设置排除优化，
### opaque
> 设置通过 configuration 配置的AOP是否可以转化为 adviser 默认为false  表示可以;
### exposeProxy
> 设置在同一个上下文中(threadLocal)的两个方法是否接收两次相同的代理,默认为false 
### frozen
设置是否应冻结次配置,避免将AOP转成Adviser时修改默认配置

## 方法 

### copyFrom
>将传入AOP配置复制给当前对象

