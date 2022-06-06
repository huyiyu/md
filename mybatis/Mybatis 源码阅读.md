# mybatis 源码阅读
> mybatis 的核心是如何创建出来一个 `SqlSessionFactory` 对象,SqlSessionFactory 一般由 `SqlSessionFactoryBuilder.build` 方法创建;其次是如何获取Mapper对象,在读取XML配置后,Mybatis将Mapper信息缓存到了Configuration的MapperRegistry里面,在主动调用 `getMapper(Class<T> class,Sqlsession session)` 方法中获取到MapperProxyFactory 然后通过jdk动态代理创建对象;最后是代理方法如何执行,MappperProxy 对象实现了jdk动态代理的Invoktion
## 1. SqlSessionFactory 创建

![SqlSessionFactory](./sqlSessionFactory%20%E5%88%9B%E5%BB%BA.png)

```java
// sqlsessionFactory创建
public SqlSessionFactory build(Reader reader, String environment, Properties properties) {
    try {
        // xmlConfigBuilder 是Mybatis 主配置文件的解析对象,所以这里获得一个reader,作为入参,environment 和properties 不是必传的,
        XMLConfigBuilder parser = new XMLConfigBuilder(reader, environment, properties);
        // parse 方法是核心,会解析形成一个configuration 对象,对应mybatis 的主配置文件。
        return build(parser.parse());
    } catch (Exception e) {
        throw ExceptionFactory.wrapException("Error building SqlSession.", e);
    } finally {
        // errorConext 作用是记录初始化过程中的错误消息在异常抛出的时候能打印最具体的内容方便定位
        // 内部是ThreadLocal对象,在启动过程中mybatis 肯定是单线程活动的,所以我们能很好定位错误
        ErrorContext.instance().reset();
        try {
            reader.close();
        } catch (IOException e) {
        // Intentionally ignore. Prefer previous error.
        }
    }
}
// 解析configuration.xml
private void parseConfiguration(XNode root) {
    try {
        // 解析 properties 内容,该内容作为变量存在 Configuration 的 variablies 属性中
        propertiesElement(root.evalNode("properties"));
        // 解析settings 属性变成properties 得到一个properties对象,从内部可知settings的每一个子属性都是配置configuration 的
        Properties settings = settingsAsProperties(root.evalNode("settings"));
        // 设置vfs实现,vfs 用于读取文件如xml可能存在jar中,这个时候需要设置读取的方式,
        // mybatis 提供了默认的实现defaultVFS 和JBoss 的实现,如果在spring boot中也有一个针对spring boot的实现
        // 所以如果需要有默认的vfs实现,那么可以配置 vfsImpl 属性 然后提供class 自己实现一个,比如你可以把xml放在统一管理的git仓库
        loadCustomVfs(settings);
        // 提供log 的具体实现,兼容市面上大部分的日志框架,配置 logImpl 属性
        loadCustomLogImpl(settings);
        // 解析typeAliases 属性 typeAliases 是为全类名的对象取别名用的,可能有两种标签
        // package: 为当前包下的所有类取别名,别名是simpleName 或者@Alias注解的name
        // typeAlias: 为当前类型的对象取别名,key是alias属性值 value 是type类型
        typeAliasesElement(root.evalNode("typeAliases"));
        // 配置扩展插件,著名的PageHelper就是在这里做的增强
        pluginElement(root.evalNode("plugins"));
        // 提供ObjectFactory扩展,这个对象是返回值构造的内容
        objectFactoryElement(root.evalNode("objectFactory"));
        // 当返回值是一个包装对象时,需要使用到这个工厂,如果对返回值是List 做某些操作,可以扩展这个对象
        objectWrapperFactoryElement(root.evalNode("objectWrapperFactory"));
        // 对象相关属性等的解析
        reflectorFactoryElement(root.evalNode("reflectorFactory"));
        // 给剩余的Setting 属性赋值
        settingsElement(settings);
        // 解析environment 的内容:
        // 先读取environments 的default 属性是指向某个 environment 的如果有会赋值,
        // default 值会被sqlSessionBuilder传入的environment 覆盖
        // 意义是配置多套的事务管理器和数据源,在不同的环境里切换
        environmentsElement(root.evalNode("environments"));
        // 提供自定义的databaseId 解析器,用于判断当前数据库是什么数据库,
        // 默认是 VendorDatabaseIdProvider,从元数据中获取
        databaseIdProviderElement(root.evalNode("databaseIdProvider"));
        // 能提供一些特殊的基本类型的映射,比如数字或字符串和枚举类型自动转化
        // 优点是 代码结构清晰所见即所得,
        // 缺点就是编写框架和编写代码的人需要有一定基本功
        // 并且这一切需要从头做起,一开始就要定好相关的规定,最好还要有专门的代码生成器,能保证
        // controller 参数解析是枚举,dao 是枚举
        typeHandlerElement(root.evalNode("typeHandlers"));
        // 最核心的mappers 的解析,用于解析主文件有多少mapper关联
        mapperElement(root.evalNode("mappers"));
    } catch (Exception e) {
        throw new BuilderException("Error parsing SQL Mapper Configuration. Cause: " + e, e);
    }
}
// 解析Mapper
/**
* 对于configuration 里面的Mapper标签的解析,在spring 环境中被mapper扫描所代替
* package 标签指定表示,对其所在的目录做添加。
* 否则 要解析以下任意一个 并且不可以多加
* resource: 表示XML所在路径
* url: 表示以url 的方式访问xml文件[各种协议支持]
* class: 直接执行addMapper
* @param parent 表示mappers 节点
* @throws Exception 当出现参数异常时
*/
private void mapperElement(XNode parent) throws Exception {
    if (parent != null) {
        for (XNode child : parent.getChildren()) {
            if ("package".equals(child.getName())) {
                String mapperPackage = child.getStringAttribute("name");
                // 必须知道mybatis 解析mapper 接口添加和解析xml 是两步操作 这里是将package 部分的 mapper 添加进 MapperRegistry
                // 和VFS相关因为可能需要从jar 包中解析interface
                configuration.addMappers(mapperPackage);
            } else {
                String resource = child.getStringAttribute("resource");
                String url = child.getStringAttribute("url");
                String mapperClass = child.getStringAttribute("class");
                if (resource != null && url == null && mapperClass == null) {
                    ErrorContext.instance().resource(resource);
                    InputStream inputStream = Resources.getResourceAsStream(resource);
                    // 如果是 resource 那么说明此处解析的是mapper.xml 文件
                    XMLMapperBuilder mapperParser = new XMLMapperBuilder(inputStream, configuration, resource, configuration.getSqlFragments());
                    mapperParser.parse();
                } else if (resource == null && url != null && mapperClass == null) {
                    ErrorContext.instance().resource(url);
                    InputStream inputStream = Resources.getUrlAsStream(url);
                    // 如果是 url 那么说明此处解析的是mapper.xml 文件
                    XMLMapperBuilder mapperParser = new XMLMapperBuilder(inputStream, configuration, url, configuration.getSqlFragments());
                    // 解析mapper.xml 核心方法
                    mapperParser.parse();
                } else if (resource == null && url == null && mapperClass != null) {
                    Class<?> mapperInterface = Resources.classForName(mapperClass);
                    // 如果是 class 那么说明此处解析的是 mapper 接口文件
                    // mapper.xml 不一定有,因为完全可以注解代替
                    configuration.addMapper(mapperInterface);
                } else {
                    throw new BuilderException("A mapper element may only specify a url, resource or class, but not more than one.");
                }
            }
        }
    }
}
// 解析xml
public void parse() {
    // 判断当前 resource 是否已经解析过 如果仍没有那么现在解析
    if (!configuration.isResourceLoaded(resource)) {
      // 具体解析逻辑
      configurationElement(parser.evalNode("/mapper"));
      // 解析完成后加入已经解析的列表,下次进来这里就不再会执行这个内容了
      configuration.addLoadedResource(resource);
      // 解析 mapper.xml 中的namespace 然后加入mapperRegistry
      bindMapperForNamespace();
    }
    // 通过再次加载,处理当前mapper.xml 中由于多层嵌套resultMapper 导致的问题
    parsePendingResultMaps();
    // 通过再次加载,二级缓存定义使用标签加载顺序问题
    parsePendingCacheRefs();
    // 通过再次加载,解决通过statmentId 上编写ResultMap 但仍然没有定义问题
    parsePendingStatements();
}

private void configurationElement(XNode context) {
    try {
      // 判空
      String namespace = context.getStringAttribute("namespace");
      if (namespace == null || namespace.isEmpty()) {
        throw new BuilderException("Mapper's namespace cannot be empty");
      }

      builderAssistant.setCurrentNamespace(namespace);
      cacheRefElement(context.evalNode("cache-ref"));
      // 二级缓存相关解析,默认使用本地Map,和LinkedHashMap 做 LRU
      cacheElement(context.evalNode("cache"));
      // parameterMap 相关解,大部分代码已过时,由parameterType 代替
      parameterMapElement(context.evalNodes("/mapper/parameterMap"));
      // resultMap 相关解析
      resultMapElements(context.evalNodes("/mapper/resultMap"));
      // 解析sql 标签,全局生效
      sqlElement(context.evalNodes("/mapper/sql"));
      // 解析CRUD相关标签
      buildStatementFromContext(context.evalNodes("select|insert|update|delete"));
    } catch (Exception e) {
      throw new BuilderException("Error parsing Mapper XML. The XML location is '" + resource + "'. Cause: " + e, e);
    }
}

public void parseStatementNode() {
    // 所有CRUD 标签必有id 属性
    String id = context.getStringAttribute("id");
    // databaseId 从当前CRUD标签获取,如果不匹配,那么直接跳过
    // 意味着不同数据库的CRUD 可以写在相同的mapper.xml 里面
    String databaseId = context.getStringAttribute("databaseId");
    // 从configuration获取元数据 比对databaseId 看是否跳过当前语句
    if (!databaseIdMatchesCurrent(id, databaseId, this.requiredDatabaseId)) {
      return;
    }
    // 获取标签名称
    String nodeName = context.getNode().getNodeName();
    // 判断对应的语句是CRUD哪一种
    SqlCommandType sqlCommandType = SqlCommandType.valueOf(nodeName.toUpperCase(Locale.ENGLISH));
    // 判断是否为select语句
    boolean isSelect = sqlCommandType == SqlCommandType.SELECT;
    // 当前是否刷新缓存,非select要考虑
    boolean flushCache = context.getBooleanAttribute("flushCache", !isSelect);
    // 当前是否使用缓存 select 要考虑
    boolean useCache = context.getBooleanAttribute("useCache", isSelect);
    // 如果为 true，则假设结果集以正确顺序（排序后）执行映射，当返回新的主结果行时，将不再发生对以前结果行的引用
    boolean resultOrdered = context.getBooleanAttribute("resultOrdered", false);

    // 在解析之前先解析 include内容
    XMLIncludeTransformer includeParser = new XMLIncludeTransformer(configuration, builderAssistant);
    includeParser.applyIncludes(context.getNode());
    // 解析parameterType
    String parameterType = context.getStringAttribute("parameterType");
    Class<?> parameterTypeClass = resolveClass(parameterType);
    // 解析lang表示使用什么样的语言驱动 默认为 XMLLanguageDriver
    String lang = context.getStringAttribute("lang");
    LanguageDriver langDriver = getLanguageDriver(lang);
    // 解析selectKeys 语句
    processSelectKeyNodes(id, parameterTypeClass, langDriver);
    // Parse the SQL (pre: <selectKey> and <include> were parsed and removed)
    KeyGenerator keyGenerator;
    String keyStatementId = id + SelectKeyGenerator.SELECT_KEY_SUFFIX;
    keyStatementId = builderAssistant.applyCurrentNamespace(keyStatementId, true);
    if (configuration.hasKeyGenerator(keyStatementId)) {
        keyGenerator = configuration.getKeyGenerator(keyStatementId);
    } else {
        keyGenerator = context.getBooleanAttribute("useGeneratedKeys",
          configuration.isUseGeneratedKeys() && SqlCommandType.INSERT.equals(sqlCommandType))
          ? Jdbc3KeyGenerator.INSTANCE : NoKeyGenerator.INSTANCE;
    }
    // 通过languageDriver 创建sqlSource 对象,这里涉及到SqlSource的策略模式
    SqlSource sqlSource = langDriver.createSqlSource(configuration, context, parameterTypeClass);
    // 所有statementType 都是prepare 在选用executor 时会根据该类型选择对应的执行器
    // STATEMENT：普通执行器
    // PREPARED: 带有预编译的执行器
    // CALLABLE: 调用存储过程使用的执行器
    StatementType statementType = StatementType.valueOf(context.getStringAttribute("statementType", StatementType.PREPARED.toString()));
    // 设置statment的fetchSize相关内容,设置一次性从数据库获取多少条数据,
    // 使用cursor 查询时常用,如果是正常sql 使用比较少
    Integer fetchSize = context.getIntAttribute("fetchSize");
    // 查询超市时间设置
    Integer timeout = context.getIntAttribute("timeout");
    // parameterMap,过时的玩法,现在也仍然支持
    String parameterMap = context.getStringAttribute("parameterMap");
    // 获取resultType类型
    String resultType = context.getStringAttribute("resultType");
    Class<?> resultTypeClass = resolveClass(resultType);
    // resultMap 类型
    String resultMap = context.getStringAttribute("resultMap");
    // ResultSet.TYPE_FORWORD_ONLY 结果集的游标只能向下滚动。
    // ResultSet.TYPE_SCROLL_INSENSITIVE 结果集的游标可以上下移动，当数据库变化时，当前结果集不变。
    // ResultSet.TYPE_SCROLL_SENSITIVE 返回可滚动的结果集，当数据库变化时，当前结果集同步改变。
    String resultSetType = context.getStringAttribute("resultSetType");
    ResultSetType resultSetTypeEnum = resolveResultSetType(resultSetType);
    if (resultSetTypeEnum == null) {
        resultSetTypeEnum = configuration.getDefaultResultSetType();
    }
    String keyProperty = context.getStringAttribute("keyProperty");
    String keyColumn = context.getStringAttribute("keyColumn");
    String resultSets = context.getStringAttribute("resultSets");
    // 由于引用指向的内存共享,这里添加的MappedStatement 就添加到Configuration 去了
    builderAssistant.addMappedStatement(id, sqlSource, statementType, sqlCommandType,
        fetchSize, timeout, parameterMap, parameterTypeClass, resultMap, resultTypeClass,
        resultSetTypeEnum, flushCache, useCache, resultOrdered,
        keyGenerator, keyProperty, keyColumn, databaseId, langDriver, resultSets);
}

//解析sql 语句
protected MixedSqlNode parseDynamicTags(XNode node) {
    // 创建公共的引用对象,用于保存解析的节点
    List<SqlNode> contents = new ArrayList<>();
    // 获取内部所有的node
    NodeList children = node.getNode().getChildNodes();
    for (int i = 0; i < children.getLength(); i++) {
      XNode child = node.newXNode(children.item(i));
      // cdata 和text 属于纯内容,使用 TextSqlNode 解析,如果有 ${}认为是动态sql
      if (child.getNode().getNodeType() == Node.CDATA_SECTION_NODE || child.getNode().getNodeType() == Node.TEXT_NODE) {
        String data = child.getStringBody("");
        TextSqlNode textSqlNode = new TextSqlNode(data);
        // 判断是否有美元符号占位 ${} 如果有就是动态sql
        if (textSqlNode.isDynamic()) {
          contents.add(textSqlNode);
          isDynamic = true;
        } else {
          contents.add(new StaticTextSqlNode(data));
        }
      } else if (child.getNode().getNodeType() == Node.ELEMENT_NODE) { // issue #628
        // 所有有元素标签的一定是动态sql 获取node名称
        String nodeName = child.getNode().getNodeName();
        // 从map里面选择对应的NodeHandler 然后执行方法 handleNode
        NodeHandler handler = nodeHandlerMap.get(nodeName);
        if (handler == null) {
          throw new BuilderException("Unknown element <" + nodeName + "> in SQL statement.");
        }
        handler.handleNode(child, contents);
        isDynamic = true;
      }
    }
    return new MixedSqlNode(contents);
}
// 判断是否是动态sql(带${}占位符判断)
public String parse(String text) {
    if (text == null || text.isEmpty()) {
        return "";
    }
    // search open token
    int start = text.indexOf(openToken);
    if (start == -1) {
        return text;
    }
    char[] src = text.toCharArray();
    int offset = 0;
    final StringBuilder builder = new StringBuilder();
    StringBuilder expression = null;
    do {
        if (start > 0 && src[start - 1] == '\\') {
        //如果 $ 前面有 \ 说明当前opentoken 已经被转义,跳过它
        // -1 表示截取的内容不包含 \
        builder.append(src, offset, start - offset - 1).append(openToken);
        // offset 定位到opentoken的位置
        offset = start + openToken.length();
        } else {
        // 有opentoken 并且没有被转义,找openToken 和closeToken 中间的内容作为 expression
        if (expression == null) {
            expression = new StringBuilder();
        } else {
            expression.setLength(0);
        }
        builder.append(src, offset, start - offset);
        offset = start + openToken.length();
        int end = text.indexOf(closeToken, offset);
        while (end > -1) {
            if (end > offset && src[end - 1] == '\\') {
            // this close token is escaped. remove the backslash and continue.
                expression.append(src, offset, end - offset - 1).append(closeToken);
                offset = end + closeToken.length();
                end = text.indexOf(closeToken, offset);
            } else {
                expression.append(src, offset, end - offset);
                break;
            }
        }
        if (end == -1) {
            // close token was not found.
            builder.append(src, start, src.length - start);
            offset = src.length;
        } else {
            // 改变 isDynamic的值
            builder.append(handler.handleToken(expression.toString()));
            offset = end + closeToken.length();
        }
        }
        start = text.indexOf(openToken, offset);
    } while (start > -1);
    if (offset < src.length) {
        builder.append(src, offset, src.length - offset);
    }
    return builder.toString();
}



// 解析接口
public <T> void addMapper(Class<T> type) {
    if (type.isInterface()) {
        if (hasMapper(type)) {
            throw new BindingException("Type " + type + " is already known to the MapperRegistry.");
        }
        boolean loadCompleted = false;
        try {
            //  将mapperclass 和MapperProxyFactory 放入knownMappers 这个Map
            knownMappers.put(type, new MapperProxyFactory<>(type));
            // 解析接口注解
            MapperAnnotationBuilder parser = new MapperAnnotationBuilder(config, type);
            parser.parse();
            loadCompleted = true;
        } finally {
            if (!loadCompleted) {
                knownMappers.remove(type);
            }
        }
    }

```
## 事务管理
> 当调用 `sqlSessionFactory.openSession()`时会开启一个带有事务的数据库连接并初始化SqlSession对象

```java
private SqlSession openSessionFromDataSource(ExecutorType execType, TransactionIsolationLevel level, boolean autoCommit) {
    Transaction tx = null;
    try {
        // 获取环境变量对象
        final Environment environment = configuration.getEnvironment();
        // 从环境变量对象里面获取TranctionFactory 对象用于创建事务对象
        final TransactionFactory transactionFactory = getTransactionFactoryFromEnvironment(environment);
        // 调用newTransaction 创建一个事务,默认事务隔离级别不修改,关闭自动提交
        tx = transactionFactory.newTransaction(environment.getDataSource(), level, autoCommit);
        // 执行器由 configuration 创建。
        // 三种执行器默认使用simple执行器
        // batch 执行flush时批量提交 调用connection.addBatch 相关
        // reuse 会复用已经预编译的语句
        final Executor executor = configuration.newExecutor(tx, execType);
        // 创建一个 defaultSqlSession 初始化执行器
        // 默认开启缓存,织入拦截器
        return new DefaultSqlSession(configuration, executor, autoCommit);
    } catch (Exception e) {
        closeTransaction(tx); // may have fetched a connection so lets call close()
        throw ExceptionFactory.wrapException("Error opening session.  Cause: " + e, e);
    } finally {
        ErrorContext.instance().reset();
    }
}
```

### mybatis 拦截器解析逻辑
> 默认创建事务时会根据一开始的类型确定使用 SimpleExecutor,开启缓存,织入拦截器,可在 Executor(执行器),ParameterHandler(设置参数),StatementHandler(sql执行),ResultSetHandler(解析返回值) 四个阶段设置拦截器
```java 
public Executor newExecutor(Transaction transaction, ExecutorType executorType) {
    executorType = executorType == null ? defaultExecutorType : executorType;
    executorType = executorType == null ? ExecutorType.SIMPLE : executorType;
    Executor executor;
    if (ExecutorType.BATCH == executorType) {
      executor = new BatchExecutor(this, transaction);
    } else if (ExecutorType.REUSE == executorType) {
      executor = new ReuseExecutor(this, transaction);
    } else {
      executor = new SimpleExecutor(this, transaction);
    }
    if (cacheEnabled) {
      executor = new CachingExecutor(executor);
    }
    // 织入拦截器
    executor = (Executor) interceptorChain.pluginAll(executor);
    return executor;
}
// 拦截器链
public Object pluginAll(Object target) {
    for (Interceptor interceptor : interceptors) {
        // 通过代理的方法返回一个Executor
      target = interceptor.plugin(target);
    }
    return target;
}
// 执行织入逻辑
public static Object wrap(Object target, Interceptor interceptor) {
    // 解析Interceptor 上的注解
    // 1.必须有 Intercepts 注解
    // 2.Intercepts 注解 value必须有Signature注解
    // 3.提取signature 注解信息的 type,method,args 获得方法列表和类型返回,并使用 map 缓存
    Map<Class<?>, Set<Method>> signatureMap = getSignatureMap(interceptor);
    Class<?> type = target.getClass();
    // 获取当前类型的所有接口
    Class<?>[] interfaces = getAllInterfaces(type, signatureMap);
    if (interfaces.length > 0) {
      // 返回当前类型的代理对象
      return Proxy.newProxyInstance(
          type.getClassLoader(),
          interfaces,
          new Plugin(target, interceptor, signatureMap));
    }
    return target;
}

// 因此,Plugin 本身是一个 InvocationHandler 关注invoke 方法
// 执行到对应逻辑前,便会执行特定的 拦截器逻辑。
public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
    try {
        // 获取缓存的方法列表 判断当前执行的方法的类是否缓存到 signatureMap里面
        Set<Method> methods = signatureMap.get(method.getDeclaringClass());
        // 是,说明要执行这个代理方法,在内部决定要不要执行,执行前后要怎么处理
        if (methods != null && methods.contains(method)) {
        return interceptor.intercept(new Invocation(target, method, args));
        }
        // 没有这个方法直接跳过，执行原逻辑
        return method.invoke(target, args);
    } catch (Exception e) {
        throw ExceptionUtil.unwrapThrowable(e);
    }
}
```





## 获取Mapper对象
> sqlSession 可以直接getMapper,最终调用MapperRegistry 的getMapper,该mapper对象需要一个 SqlSession 用于访问数据库以及处理事务等相关内容
```java
public <T> T getMapper(Class<T> type, SqlSession sqlSession) {
    // 首先从knownMappers 通过MapperClass 类型获得对应的MapperProxyFactory
    final MapperProxyFactory<T> mapperProxyFactory = (MapperProxyFactory<T>) knownMappers.get(type);
    if (mapperProxyFactory == null) {
        throw new BindingException("Type " + type + " is not known to the MapperRegistry.");
    }
    try {
        // 然后执行newInstance 调用JDK动态代理方法创建 Mapper
      return mapperProxyFactory.newInstance(sqlSession);
    } catch (Exception e) {
        throw new BindingException("Error getting mapper instance. Cause: " + e, e);
    }
}

// 内部使用JDK 的动态代理 api 创建的 Mapper 
protected T newInstance(MapperProxy<T> mapperProxy) {
    return (T) Proxy.newProxyInstance(mapperInterface.getClassLoader(), new Class[] { mapperInterface }, mapperProxy);
}

public T newInstance(SqlSession sqlSession) {
    final MapperProxy<T> mapperProxy = new MapperProxy<>(sqlSession, mapperInterface, methodCache);
    return newInstance(mapperProxy);
}
```

## 执行代理方法
### MapperProxy 初始化
```java
 static {
    Method privateLookupIn;
    try {
        // 尝试获取 privateLookupIn 方法 JDK9 新增方法 解决MethodHandler 执行default 方法效率问题
      privateLookupIn = MethodHandles.class.getMethod("privateLookupIn", Class.class, MethodHandles.Lookup.class);
    } catch (NoSuchMethodException e) {
      privateLookupIn = null;
    }
    privateLookupInMethod = privateLookupIn;

    Constructor<Lookup> lookup = null;
    if (privateLookupInMethod == null) {
      // JDK 1.8
      try {
        lookup = MethodHandles.Lookup.class.getDeclaredConstructor(Class.class, int.class);
        lookup.setAccessible(true);
      } catch (NoSuchMethodException e) {
        throw new IllegalStateException(
            "There is neither 'privateLookupIn(Class, Lookup)' nor 'Lookup(Class, int)' method in java.lang.invoke.MethodHandles.",
            e);
      } catch (Exception e) {
        lookup = null;
      }
    }
    lookupConstructor = lookup;
  }

// mapperproxy时invocationHandler 关注invoke方法
public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
    try {
      if (Object.class.equals(method.getDeclaringClass())) {
        // 判断当前方法是否是object特有方法如果是 则不走下面逻辑
        return method.invoke(this, args);
      } else {
        return cachedInvoker(method).invoke(proxy, method, args, sqlSession);
      }
    } catch (Throwable t) {
      throw ExceptionUtil.unwrapThrowable(t);
    }
}

private MapperMethodInvoker cachedInvoker(Method method) throws Throwable {
    try {
      // A workaround for https://bugs.openjdk.java.net/browse/JDK-8161372
      // It should be removed once the fix is backported to Java 8 or
      // MyBatis drops Java 8 support. See gh-1929
      MapperMethodInvoker invoker = methodCache.get(method);
      if (invoker != null) {
        return invoker;
      }

      return methodCache.computeIfAbsent(method, m -> {
        // 支持mapper 内部default 方法的调用,提升default方法执行性能
        // https://www.jianshu.com/p/a9cecf8ba5d9 methodHandler 相关内容
        // 实际业务敢这么写代码直接打死,这个代码可以不关心具体怎么玩的
        if (m.isDefault()) {
          try {
            if (privateLookupInMethod == null) {
              return new DefaultMethodInvoker(getMethodHandleJava8(method));
            } else {
              return new DefaultMethodInvoker(getMethodHandleJava9(method));
            }
          } catch (IllegalAccessException | InstantiationException | InvocationTargetException
              | NoSuchMethodException e) {
            throw new RuntimeException(e);
          }
        } else {
          // 走plainMethod 然后调用MapperMethod的execute方法
          // 对于default 和Object 内部方法的内容大部分可以忽略,业务里面基本不会出现这种代码
          return new PlainMethodInvoker(new MapperMethod(mapperInterface, method, sqlSession.getConfiguration()));
        }
      });
    } catch (RuntimeException re) {
      Throwable cause = re.getCause();
      throw cause == null ? re : cause;
    }
}
```
### MapperMethod 初始化
```java
public SqlCommand(Configuration configuration, Class<?> mapperInterface, Method method) {
    final String methodName = method.getName();
    final Class<?> declaringClass = method.getDeclaringClass();
    MappedStatement ms = resolveMappedStatement(mapperInterface, methodName, declaringClass,
        configuration);
    if (ms == null) {
        // 如果当前不存在对应的MapperStatement,
        // 说明无论是注解解析还是XML解析都没有
        // 判断是否有@Flush注解,如果有Type设置为
        if (method.getAnnotation(Flush.class) != null) {
            name = null;
            type = SqlCommandType.FLUSH;
        } else {
            throw new BindingException("Invalid bound statement (not found): "
                + mapperInterface.getName() + "." + methodName);
        }
    } else {
        // 从对源码的分析指导 name 就是方法名
        name = ms.getId();
        // 标示当前执行的方法是一个什么类型的sql执行
        // UNKNOWN, INSERT, UPDATE, DELETE, SELECT, FLUSH
        type = ms.getSqlCommandType();
        if (type == SqlCommandType.UNKNOWN) {
            throw new BindingException("Unknown execution method for: " + name);
        }
    }
}

public MethodSignature(Configuration configuration, Class<?> mapperInterface, Method method) {
    // 处理返回值类型
    Type resolvedReturnType = TypeParameterResolver.resolveReturnType(method, mapperInterface);
    if (resolvedReturnType instanceof Class<?>) {
        this.returnType = (Class<?>) resolvedReturnType;
    } else if (resolvedReturnType instanceof ParameterizedType) {
        this.returnType = (Class<?>) ((ParameterizedType) resolvedReturnType).getRawType();
    } else {
        this.returnType = method.getReturnType();
    }
    // 返回值类型为空
    this.returnsVoid = void.class.equals(this.returnType);
    // 返回值类型是集合或数组
    this.returnsMany = configuration.getObjectFactory().isCollection(this.returnType) || this.returnType.isArray();
    // 返回值类型是一个Cursor 游标
    this.returnsCursor = Cursor.class.equals(this.returnType);
    // 返回值类型带有Optional
    this.returnsOptional = Optional.class.equals(this.returnType);
    // 当返回值为Map时,可以直接通过@MapKey 指定作为key返回的
    this.mapKey = getMapKey(method);
    //  mapkey不为空时说明指定了map返回值,并且有@Mapkey注解
    this.returnsMap = this.mapKey != null;
    // 如果有rowBounds参数,列表中仅能拥有一个是RowBounds 类型,找到它的index
    this.rowBoundsIndex = getUniqueParamIndex(method, RowBounds.class);
    //  如果参数列表有ResultHandler,有且仅有一个，用于处理返回值
    this.resultHandlerIndex = getUniqueParamIndex(method, ResultHandler.class);
    // 初始化参数处理器,解析参数顺序和参数名称作为map存起来
    this.paramNameResolver = new ParamNameResolver(configuration, method);
}
```
### 入参处理
```java
// 参数处理器对参数的处理
public ParamNameResolver(Configuration config, Method method) {
    // 使用编译器推断参数名称,要指定编译参数
    this.useActualParamName = config.isUseActualParamName();
    // 获取所有参数类型
    final Class<?>[] paramTypes = method.getParameterTypes();
    // 获取所有参数注解
    final Annotation[][] paramAnnotations = method.getParameterAnnotations();
    //
    final SortedMap<Integer, String> map = new TreeMap<>();
    int paramCount = paramAnnotations.length;
    // get names from @Param annotations
    for (int paramIndex = 0; paramIndex < paramCount; paramIndex++) {
      // rowBound 和 resultHandler 是特殊参数直接跳过
      if (isSpecialParameter(paramTypes[paramIndex])) {
        // skip special parameters
        continue;
      }
      String name = null;
      // 获取参数注解,如果有@Param直接获取其value,标记上 hasParamAnnotation
      for (Annotation annotation : paramAnnotations[paramIndex]) {
        if (annotation instanceof Param) {
          hasParamAnnotation = true;
          name = ((Param) annotation).value();
          break;
        }
      }
      // 没有@Param注解 那么使用反射获取编译期,编译的参数
      if (name == null) {
        // @Param was not specified.
        if (useActualParamName) {
          name = getActualParamName(method, paramIndex);
        }
        // 如果还没有,使用当前Map最长序号作为名称
        if (name == null) {
          // use the parameter index as the name ("0", "1", ...)
          // gcode issue #71
          name = String.valueOf(map.size());
        }
      }
      map.put(paramIndex, name);
    }
    names = Collections.unmodifiableSortedMap(map);
}

// 所有execute 必经之路
public Object getNamedParams(Object[] args) {
    final int paramCount = names.size();
    if (args == null || paramCount == 0) {
      return null;
    } else if (!hasParamAnnotation && paramCount == 1) {
      Object value = args[names.firstKey()];
      return wrapToMapIfCollection(value, useActualParamName ? names.get(0) : null);
    } else {
      // 本质上是个hashmap 重写了get方法防止未知的参数名
      final Map<String, Object> param = new ParamMap<>();
      int i = 0;
      // 两套参数名称 param1 param2 或paramResolver 解析的结果
      for (Map.Entry<Integer, String> entry : names.entrySet()) {
        param.put(entry.getValue(), args[entry.getKey()]);
        // add generic param names (param1, param2, ...)
        final String genericParamName = GENERIC_NAME_PREFIX + (i + 1);
        // ensure not to overwrite parameter named with @Param
        if (!names.containsValue(genericParamName)) {
          param.put(genericParamName, args[entry.getKey()]);
        }
        i++;
      }
      return param;
    }
  }


```
### 执行 execute 方法
> 所有的xml方法最终都会走到这里 此时真正的查询才算刚刚开始,此时发现 INSERT|SELETE|UPDATE|SELECT 都是调用的sqlsession的方法本质上,而insert update delete 都是调用底层executor 的update 方法,select 调用query方法,后续内容基本和扩展没有关系,所以此处跳过 有兴趣自己研究
```java
public Object execute(SqlSession sqlSession, Object[] args) {
    Object result;
    switch (command.getType()) {
      case INSERT: {
        // 解析参数名称
        Object param = method.convertArgsToSqlCommandParam(args);
        // 处理影响条数满足返回值是 int long boolean 相关内容
        result = rowCountResult(sqlSession.insert(command.getName(), param));
        break;
      }
      case UPDATE: {
        // 解析参数名称
        Object param = method.convertArgsToSqlCommandParam(args);
        // 处理影响条数满足返回值是 int long boolean 相关内容
        result = rowCountResult(sqlSession.update(command.getName(), param));
        break;
      }
      case DELETE: {
        // 解析参数名称
        Object param = method.convertArgsToSqlCommandParam(args);
        // 处理影响条数满足返回值是 int long boolean 相关内容
        result = rowCountResult(sqlSession.delete(command.getName(), param));
        break;
      }
      case SELECT:
        // 要根据方法签名使用特定的 execute 处理
        if (method.returnsVoid() && method.hasResultHandler()) {
          executeWithResultHandler(sqlSession, args);
          result = null;
        } else if (method.returnsMany()) {
          result = executeForMany(sqlSession, args);
        } else if (method.returnsMap()) {
          result = executeForMap(sqlSession, args);
        } else if (method.returnsCursor()) {
          result = executeForCursor(sqlSession, args);
        } else {
          Object param = method.convertArgsToSqlCommandParam(args);
          result = sqlSession.selectOne(command.getName(), param);
          if (method.returnsOptional()
              && (result == null || !method.getReturnType().equals(result.getClass()))) {
            result = Optional.ofNullable(result);
          }
        }
        break;
      case FLUSH:
        result = sqlSession.flushStatements();
        break;
      default:
        throw new BindingException("Unknown execution method for: " + command.getName());
    }
    if (result == null && method.getReturnType().isPrimitive() && !method.returnsVoid()) {
      throw new BindingException("Mapper method '" + command.getName()
          + " attempted to return null from a method with a primitive return type (" + method.getReturnType() + ").");
    }
    return result;
}
```
#### mybatis executor 执行器

#### statementHandler 

## 入参和返回值处理