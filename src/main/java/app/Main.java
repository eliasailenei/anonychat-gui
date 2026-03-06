package app;

import me.friwi.jcefmaven.CefAppBuilder;
import me.friwi.jcefmaven.MavenCefAppHandlerAdapter;
import org.cef.CefApp;
import org.cef.CefClient;
import org.cef.CefSettings;
import org.cef.browser.CefBrowser;
import org.cef.browser.CefFrame;
import org.cef.handler.CefLoadHandler;
import org.cef.handler.CefLoadHandlerAdapter;

import javax.swing.*;
import java.awt.*;
import java.awt.event.WindowAdapter;
import java.awt.event.WindowEvent;
import java.io.File;
import java.nio.file.Path;
import java.util.concurrent.atomic.AtomicBoolean;

/**
 * AnonyChat desktop GUI — a self-contained Chromium browser window powered by JCEF.
 * <p>
 * CEF binaries are extracted once from the bundled native jar
 * into {@code ~/.anonychat/cef-runtime/} and reused on subsequent launches.
 */
public class Main {
	private static final String APP_NAME = "AnonyChat";

	public static void main(String[] args) throws Exception {
		String target = parseTarget(args);
		if (target == null) {
			System.err.println("Usage: AnonyChat <url>  (example: localhost:8080)");
			System.exit(1);
		}

		// ── Initialise JCEF ──────────────────────────────────────────────
		File installDir = Path.of(System.getProperty("user.home"), ".anonychat", "cef-runtime").toFile();
		installDir.mkdirs();

		CefAppBuilder builder = new CefAppBuilder();
		builder.setInstallDir(installDir);
		builder.getCefSettings().windowless_rendering_enabled = false;
		builder.getCefSettings().log_severity = CefSettings.LogSeverity.LOGSEVERITY_WARNING;

		builder.setAppHandler(new MavenCefAppHandlerAdapter() {
			@Override
			public void stateHasChanged(CefApp.CefAppState state) {
				if (state == CefApp.CefAppState.TERMINATED) {
					System.exit(0);
				}
			}
		});

		CefApp cefApp = builder.build();
		CefClient client = cefApp.createClient();

		// IPv4 fallback: if loading localhost / [::1] / 0.0.0.0 fails,
		// retry with 127.0.0.1 (mirrors the old JavaFX behaviour).
		AtomicBoolean didIpv4Fallback = new AtomicBoolean(false);
		client.addLoadHandler(new CefLoadHandlerAdapter() {
			@Override
			public void onLoadError(CefBrowser browser, CefFrame frame,
									CefLoadHandler.ErrorCode errorCode,
									String failedUrl, String errorText) {
				if (!didIpv4Fallback.get() && failedUrl != null
						&& (failedUrl.contains("://localhost")
							|| failedUrl.contains("://[::1]")
							|| failedUrl.contains("://0.0.0.0"))) {
					didIpv4Fallback.set(true);
					String retry = failedUrl
							.replace("://localhost", "://127.0.0.1")
							.replace("://[::1]", "://127.0.0.1")
							.replace("://0.0.0.0", "://127.0.0.1");
					browser.loadURL(retry);
					return;
				}
				System.out.println("[GUI] Failed to load: " + failedUrl + " (" + errorText + ")");
			}
		});

		CefBrowser browser = client.createBrowser(target, false, false);

		// ── Swing frame ──────────────────────────────────────────────────
		SwingUtilities.invokeAndWait(() -> {
			JFrame frame = new JFrame(APP_NAME);
			frame.setDefaultCloseOperation(JFrame.DO_NOTHING_ON_CLOSE);
			frame.addWindowListener(new WindowAdapter() {
				@Override
				public void windowClosing(WindowEvent e) {
					browser.close(true);
					cefApp.dispose();
					frame.dispose();
				}
			});

			frame.getContentPane().add(browser.getUIComponent(), BorderLayout.CENTER);
			frame.setSize(1100, 750);
			frame.setLocationRelativeTo(null);
			frame.setVisible(true);
		});
	}

	// ── URL parsing (unchanged from the JavaFX version) ──────────────────

	private static String parseTarget(String[] rawArgs) {
		if (rawArgs == null || rawArgs.length == 0) return null;
		String arg = rawArgs[0];
		if (arg == null) return null;
		arg = arg.trim();
		if (arg.isEmpty()) return null;

		// Allow scheme-less targets like: localhost:8080, 127.0.0.1:3000, example.com
		if (arg.contains("://")) {
			return arg;
		}

		String lower = arg.toLowerCase();
		boolean looksLocal = lower.startsWith("localhost") || lower.startsWith("127.")
				|| lower.startsWith("0.0.0.0") || lower.endsWith(".local");
		boolean hasPort = arg.matches(".*:[0-9]{2,5}$");
		String scheme = (looksLocal || hasPort) ? "http://" : "https://";
		return scheme + arg;
	}
}
