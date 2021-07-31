# 第二节 Bean Definiction
> spring 体系复杂,内容繁多,建议初学者先看完[spring体系结构]()以及本节内容，接着再去关心启动流程,生命周期等细节
## 一些问题的回答
* BeanDefiniction 是什么
> BeanDefiniction 是Spring Bean 的抽象,类比 class 是对象的抽象
* 为什么需要 BeanDefiniction 
> spring bean 具有 普通对象无法描述的行为,建立一个描述 spring bean 的行为如(如作用域,自动注入模型,是否作为候选Bean等信息)
## bean Definiction 体系结构
![BeanDefiniction 类图](img/classview.png)
* AttributeAccessor: 供了一套对属性CRUD的顶层接口
* AttributeAccessorSupport: 实现了这一组接口内部是一个LinkedHashMap,将Map作为存储空间提供属性的CRUD
* BeanMetaDataElement: 提供了获取 source 的顶层实现
* BeanMetaDataAttributeAccessor: 继承 AttributeAccessorSupport 获得对属性 CRUD 的实现,提供对source get/set 的实现
* BeanDefinition: 是一个子接口,他的两个父接口为 AttributeAccessor(属性访问器),BeanMetadataElement(Bean 元数据元素),
* AbstractBeanDefiniction: 提供一个Bean Definiction模板并提供一些BeanDefinition 的默认配置它继承AttributeAccessorSupport获得了设置source 和对attrbute 的CRUD,
* GenericBeanDefinition: 通用的BeanDefinition，提供给程序员开发使用,可直接往BeanFactory中设置
* ChildBeanDefinition:
* RootBeanDefinition:
* ClassDriverBeanDefinition:
* ScannedGenericBeanDefinition:
* AnnotationGenericBeanDefinition:
## Bean Definition 属性
