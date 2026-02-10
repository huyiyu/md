class MyThread {

    static {
        System.setProperty("java.library.path", ".");
        System.loadLibrary("myThreadNative");
    }


    public void run() {

        System.out.println(Thread.currentThread().getName() + ":I am running");
    }


    public native void start();

    public static void main(String[] args) {
        MyThread myThread = new MyThread();
        myThread.start();
    }

}