# NIO 准备
> 从JDK1.4 引入,为了解决传统BIO存在的以下问题
* 没有数据缓冲区,I/O 性能存在问题
* 没有 channel 的概念,只有输入和输出流
* 同步阻塞式 I/O 通信，会导致线程被长时间阻塞
* 支持字符集有限


## NIO 组件
> nio,基于事件监听机制包含三大组件
### Buffer
>缓冲区,用于读取或写入内容,一般是一个字节数组或堆外内存    
* capacity： 最大容量，它永远不可能为负数，并且是不会变化的
* limit：  限制，它永远不可能为负数，并且不会大于capacity
* position：下一个读或写的位置，它永远不可能为负数，并且不会大于limit
### Channel
>双向可读可写数据源,比如一个Socket连接,或一个文件都可以是一个通道
### Selector
>事件监听器, 通过向Selector 注册事件来监听 Channel 的变化便于读取或写入数据,常见的事件有 Connected,Accepted,Read,Write

## NIO Reactor 三种模型
### 单线程模型
> 将单个 ServerSocketChannel 和 多个SocketChannel 共同注册到同一个Selector上,单个线程轮询事件触发,并实现新SocketChannel注册和请求响应
优点: 不需要线程切换,个人职业者自己开公司

### 多线程模型
>还是只有一个Selector serverSocketChannel 和SocketChannel 共用,但是主线程处理其他socket 连接读请求内容， 每个连接的回复交给各个工作线程去做。相当于是一个领导去建 tapd 任务(读请求提交任务)，其他人去tapd上领任务
### 主从多线程模型
> 有一个主Selector 由一个主线程维护 只轮询哪个客户端注册上来,多个从Selector 用于监听连接响应，同时每个Selector 对应一个工作线程 这个时候主线程不需要处理 和连接无关的内容 所有响应都交给工作线程。集团公司控制各个分公司干活,每个分公司只有一个人,它就处理集团公司提交过来的对接公司列表,自己去找对接公司对接(读请求)，自己去回复对接公司





## NIO 实战案例
### NIO 实现服务端(参考tomcat)
```java
package nio.prepare.server;

import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.ByteBuffer;
import java.nio.channels.ServerSocketChannel;
import java.nio.channels.SocketChannel;

public class NIOServer1 {

    private static ServerSocketChannel nioServer;

    /**
     * NIO Server服务器
     *
     * @param args
     * @throws IOException
     */
    public static void main(String[] args) throws IOException {
        nioServer = ServerSocketChannel.open();
        nioServer.bind(new InetSocketAddress(8888));
        nioServer.configureBlocking(true);
        ByteBuffer allocate = ByteBuffer.allocate(1024);
        while (true) {
            SocketChannel accept = nioServer.accept();
            readContent(accept, allocate);
        }
    }

    private static void readContent(SocketChannel accept, ByteBuffer allocate) throws IOException {
        int read;
        while ((read = accept.read(allocate)) != -1) {
            allocate.flip();
            byte[] array = allocate.array();
            System.out.println(new String(array, 0, read, "UTF-8"));
            allocate.clear();

        }
    }
}



```
### TCP resp实现 简单的redis 客户端
```java
package nio.prepare.myjedis;

import redis.clients.jedis.Jedis;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.net.Socket;
import java.nio.charset.StandardCharsets;

/**
 * TCP 练习,根据resp协议编写redis 客户端
 *
 */
public class MyJedis {

    private Socket socket;
    public static final String LINE = "\r\n";
    private static final String COMMAND_COUNT_FLAG = "*";
    private static final String COMMAND_LENGTH_FLAG = "$";

    public String set(final String key, String value) {
        return command("SET", key.getBytes(StandardCharsets.UTF_8), value.getBytes(StandardCharsets.UTF_8));
    }

    public String incr(final String key) {
        String incr = command("INCR", key.getBytes(StandardCharsets.UTF_8));
        return incr;
    }

    public String get(final String key) {
        return command("GET", key.getBytes(StandardCharsets.UTF_8));
    }


    public String command(String name, byte[]... args) {
        StringBuilder sb = new StringBuilder();
        sb.append(COMMAND_COUNT_FLAG).append(1 + args.length).append(LINE);
        sb.append(COMMAND_LENGTH_FLAG).append(name.length()).append(LINE);
        sb.append(name).append(LINE);
        for (byte[] arg : args) {
            String argString = new String(arg);
            sb.append(COMMAND_LENGTH_FLAG).append(argString.length()).append(LINE);
            sb.append(argString).append(LINE);
        }
        try {
            InputStream inputStream = socket.getInputStream();
            OutputStream outputStream = socket.getOutputStream();
            outputStream.write(sb.toString().getBytes(StandardCharsets.UTF_8));
            byte[] bytes = new byte[inputStream.available()];
            int read = inputStream.read(bytes);
            return new String(bytes, 0, read);

        } catch (IOException e) {
            e.printStackTrace();
        }
        return "";
    }

    public MyJedis(String host, int port) {
        try {
            InetSocketAddress inetSocketAddress = new InetSocketAddress(host, port);

            socket = new Socket();
            socket.connect(inetSocketAddress);
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    public static void main(String[] args) {
//        jedisTest();
        myJedisTest();
    }

    private static void jedisTest() {
        Jedis jedis = new Jedis("localhost",8888);
        String set = jedis.set("myKey", "1");
        System.out.println("set:"+set);
        String myKey = jedis.get("myKey");
        System.out.println(myKey);
        long myKey1 = jedis.incr("myKey");
        System.out.println(myKey1);
    }

    private static void myJedisTest() {
        MyJedis myJedis = new MyJedis("localhost", 6379);
        String set = myJedis.set("myKey", "1");
        System.out.println("set:" + set);
        String myKey = myJedis.get("myKey");
        System.out.println(myKey);
        String myKey1 = myJedis.incr("myKey");
        System.out.println(myKey1);
    }
}
```
### 聊天室
## NIO selector 空转 bug