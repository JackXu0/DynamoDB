import java.util.Random;

public class Util{
    public static String getRandomIP(){
        Random rand = new Random();
        return rand.nextInt(256)+"."+rand.nextInt(256)+rand.nextInt(256)+"."+rand.nextInt(256);
    }


}

