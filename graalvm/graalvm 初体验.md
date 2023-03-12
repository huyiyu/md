# graalvm 初体验
> graalvm 是oracle 公司开发的下一代虚拟机系统,号称能编译所有语言,目前已经支持scala kotlin groovy 等jvm 语言 同时也支持R python 等解释型语言,目前公司在调研基于jdk17+graalvm+springboot3 的本地编译技术.本文主要教人如何快速上手
## 安装
> 本人使用macOS 系统,所有操作基于macOS 其他环境请参照官网,mac 系统可参照我这边
1. 卸载旧jdk
- https://stackoverflow.com/questions/19039752/removing-java-8-jdk-from-mac
- https://www.java.com/zh-CN/download/help/mac_uninstall_java.html 
> mac 系统jdk 卸载比较麻烦,建议把相关内容那个都删除,
```bash
sudo rm -rf /Library/PreferencePanes/JavaControlPanel.prefPane
sudo rm -rf /Library/Internet\ Plug-Ins/JavaAppletPlugin.plugin
sudo rm -rf /Library/LaunchAgents/com.oracle.java.Java-Updater.plist
sudo rm -rf /Library/PrivilegedHelperTools/com.oracle.java.JavaUpdateHelper
sudo rm -rf /Library/LaunchDaemons/com.oracle.java.Helper-Tool.plist
sudo rm -rf /Library/Preferences/com.oracle.java.Helper-Tool.plist
# 此处注意 需要根据对应的版本删除,graalVM 本身就有jdk 相关工具 无需安装jdk
sudo rm -rf /Library/Java/JavaVirtualMachines/<对应java版本>/
```
2. 安装
> ***一般情况下,学一项技术最快先找到官网 [get Started/quick Started 相关章节](https://www.graalvm.org/latest/docs/getting-started/)以下直接讲述mac 系统graalvm的安装

* github 下载graalvm jdk17 和native image: https://github.com/graalvm/graalvm-ce-builds/releases mac 点击以下链接安装
    * https://github.com/graalvm/graalvm-ce-builds/releases/download/vm-22.3.1/graalvm-ce-java17-darwin-amd64-22.3.1.tar.gz
    * https://github.com/graalvm/graalvm-ce-builds/releases/download/vm-22.3.1/native-image-installable-svm-java17-darwin-amd64-22.3.1.jar

- 按要求把graalVM 安装到 java 的安装目录
```bash 
## 解压到该目录
tar -xvf graalvm-ce-java17-darwin-amd64-22.3.1.tar.gz -C /Library/Java/JavaVirtualMachines/
## 如果是 10.15 Catlina 及以上版本 如BigSur ventura 系统,要移除 quarantine 属性
sudo xattr -r -d com.apple.quarantine /Library/Java/JavaVirtualMachines/graalvm-ce-java17-22.3.1
# 添加java_home 和path 指定到具体使用的 bashrc 或zshrc
export JAVA_HOME=/Library/Java/JavaVirtualMachines/graalvm-ce-java17-22.3.1/Contents/Home
export PATH=/Library/Java/JavaVirtualMachines/graalvm-ce-java17-22.3.1/Contents/Home/bin:$PATH
# 安装 native image 假如电脑没有翻墙如下提前下载文件安装安装 有翻墙 gu install native-image 即可
gu install -L native-image-installable-svm-java17-darwin-amd64-22.3.1.jar
```
### 初体验
1. 基于class 编译成可执行文件
* 新建文件 Main.java
```java
public class Main {
    public static void main(String[] args) {
        System.out.println("Hello graalvm");
    }
}
```
* 编译
```bash
#javac 编译成Main
javac Main.java
# native image 编译成可执行二进制
native-image Main
# 执行
./Main
```
### 基于spring boot 工程 构建
* 新建spring boot3 工程编写 [pom.xml](./pom.xml) 或直接使用当前工程
* src/main/java 编写 SpringApplication 主入口
```java
package com.example;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class Main {

	public static void main(String[] args) {
		SpringApplication.run(Main.class, args);
	}
}
```
执行 target 下有一个可执行文件 demo spring boot 工程启动
```bash
./target/demo
```