# 基于 Servlet
>这一章节包含最小配置以及如何在spring boot 中使用 spring security

## 更新依赖
> 仅需使用maven 或 gradle 更新依赖
## spring boot 自动配置
* spring 自动配置了:
    * 启动 spring security 的默认配置,这个配置根据bean name 为 `springSecurityFilterChain` 创建了一个 servlet 过滤器(将注册到spring 的名称为SpringSecurityFilterChain 作为Servlet 的过滤器),这个Bean 为整个应用的安全(保护url,验证提交的用户名和密码,重定向到登陆表单等等)的具体实现
    * 根据用户名创建一个名称叫做 `userDetailService` 的 bean 和一个随机生成的密码并打印到控制台上
    * 为所有请求注册这个过滤器
* spring boot 没有体现配置很多,但是背后做了很多事情。功能总结如下:
    * 要求先通过认证才能和应用的任何交互
    * 生成一个默认的登陆表单
    * 使用BCrypt 保护密码存储
    * 提供用户登出
    * CSRF攻击
    * session 固定保护
    * 安全请求头集成
        * HSTS 提供安全的请求
        * X-Content-Type-Option 
        * 缓存控制
        * XSS保护
        * X-Frame-Options 防止点击劫持
    * 与以下servlet api 方法集成
        * HttpServletRequest#getRemoteUser()
        * HttpServletRequest.html#getUserPrincipal()
        * HttpServletRequest.html#isUserInRole(java.lang.String)
        * HttpServletRequest.html#login(java.lang.String, java.lang.String)
        * HttpServletRequest.html#logout()
        
