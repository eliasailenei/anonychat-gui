public final class NativeInfo {
	private static volatile boolean loaded;

	private NativeInfo() {}

	public static boolean isLoaded() {
		return loaded;
	}

	public static void tryLoad() {
		if (loaded) return;
		try {
			System.loadLibrary("universaljni");
			loaded = true;
		} catch (UnsatisfiedLinkError ignored) {
			loaded = false;
		} catch (SecurityException ignored) {
			loaded = false;
		}
	}

	public static native String platform();

	public static void main(String[] args) {
		tryLoad();
		System.out.println(isLoaded() ? platform() : "jni-not-loaded");
	}
}
