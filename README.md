
# AnonyChat (embedded web GUI)

This repo builds a desktop app named **AnonyChat** that embeds a browser view (JavaFX `WebView`) and loads the website you pass as a command-line argument.

Examples:

```bash
AnonyChat localhost:8080
AnonyChat https://anonychat.example
```

## Important constraint (why it can’t be “one universal fat JAR”)

An embedded browser requires **native binaries** that differ per OS/CPU. Also, you asked to assume the user has only “normal Java” and shouldn’t install anything.

So the practical solution is:

- One codebase
- Build a **self-contained app-image per OS** that bundles a JVM + JavaFX (no end-user installs)

## Build a self-contained app-image (recommended)

This produces an app folder you can zip and ship for the **current OS**.

```bash
chmod +x build-dist.sh
./build-dist.sh
```

Output goes to `build/jpackage/`.

### Windows

```powershell
.\build-dist.ps1
```

Output goes to `build\jpackage\`.

### Build a single zip you can ship

```bash
chmod +x zip-dist.sh
./zip-dist.sh
```

Output goes to `dist/`.

End-user usage on macOS: open `AnonyChat.app` (double-click), or run from Terminal to pass args:

```bash
./AnonyChat.app/Contents/MacOS/AnonyChat localhost:8080
```

End-user usage on Linux: run `AnonyChat/bin/AnonyChat` (path depends on the folder layout under `build/jpackage`).

### Windows

```powershell
.\zip-dist.ps1
```

Output goes to `dist\AnonyChat-windows.zip`.

End-user usage on Windows: unzip, then run `AnonyChat\\bin\\AnonyChat.exe localhost:8080`.

To build for Windows/Linux/macOS you must run the build on that OS (or use CI runners for each OS).

## App icon (your logo)

Place your icon files here before building:

- macOS: `assets/icon.icns`
- Windows: `assets/icon.ico`
- Linux: `assets/icon.png`

Then rebuild (`./zip-dist.sh` on macOS/Linux or `./zip-dist.ps1` on Windows).

## Optional: build + use JNI

JNI is **not** needed for either mode. If you want JNI working anyway:

### macOS

```bash
export JAVA_HOME=$(/usr/libexec/java_home)
chmod +x native/build-macos.sh
native/build-macos.sh
javac NativeInfo.java
java -Djava.library.path=native NativeInfo
```

### Linux

```bash
export JAVA_HOME=/path/to/your/jdk
chmod +x native/build-linux.sh
native/build-linux.sh
javac NativeInfo.java
java -Djava.library.path=native NativeInfo
```

### Windows (PowerShell)

```powershell
$env:JAVA_HOME = "C:\Path\To\JDK"
cd native
.\build-windows.ps1
cd ..
javac NativeInfo.java
java -Djava.library.path=native NativeInfo
```

## Notes

- If some sites render oddly, that’s a limitation of JavaFX WebView (WebKit). For a Chromium-level embed, you’d typically use JCEF (still cross-platform, but involves shipping platform-specific native binaries).
