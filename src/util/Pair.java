package util;

public class Pair<T1, T2> {
    private T1 first;
    private T2 second;

    public Pair(T1 x, T2 y) {
        this.first = x;
        this.second = y;
    }

    public T1 first() {
        return this.first;
    }

    public T2 second() {
        return this.second;
    }

    public void second(T2 second) { this.second = second; }
}