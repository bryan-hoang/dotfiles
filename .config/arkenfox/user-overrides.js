/**
 * 0102: set startup page [SETUP-CHROME]
 * 0=blank, 1=home, 2=last visited page, 3=resume previous session
 * [NOTE] Session Restore is cleared with history (2811), and not used in Private Browsing mode
 * [SETTING] General>Startup>Restore previous session
 */
user_pref("browser.startup.page", 3);

/**
 * 0801: disable location bar using search
 * Don't leak URL typos to a search engine, give an error message instead
 * Examples: "secretplace,com", "secretplace/com", "secretplace com", "secret place.com"
 * [NOTE] This does not affect explicit user action such as using search buttons in the
 * dropdown, or using keyword search shortcuts you configure in options (e.g. "d" for DuckDuckGo)
 * [SETUP-CHROME] Override this if you trust and use a privacy respecting search engine
 */
user_pref("keyword.enabled", true);

/**
 * 0804: disable live search suggestions
 * [NOTE] Both must be true for the location bar to work
 * [SETUP-CHROME] Override these if you trust and use a privacy respecting search engine
 * [SETTING] Search>Provide search suggestions | Show search suggestions in address bar results
 */
user_pref("browser.search.suggest.enabled", true);
user_pref("browser.urlbar.suggest.searches", true);

/**
 * 0810: disable search and form history
 * [SETUP-WEB] Be aware that autocomplete form data can be read by third parties [1][2]
 * [NOTE] We also clear formdata on exit (2811)
 * [SETTING] Privacy & Security>History>Custom Settings>Remember search and form history
 * [1] https://blog.mindedsecurity.com/2011/10/autocompleteagain.html
 * [2] https://bugzilla.mozilla.org/381681
 */
user_pref("browser.formfill.enable", true);

/**
 * 0903: disable auto-filling username & password form fields
 * can leak in cross-site forms *and* be spoofed
 * [NOTE] Username & password is still available when you enter the field
 * [SETTING] Privacy & Security>Logins and Passwords>Autofill logins and passwords
 * [1] https://freedom-to-tinker.com/2017/12/27/no-boundaries-for-user-identities-web-trackers-exploit-browser-login-managers/
 * [2] https://homes.esat.kuleuven.be/~asenol/leaky-forms/
 */
user_pref("signon.autofillForms", true);

/**
 * 2811: set/enforce what items to clear on shutdown (if 2810 is true) [SETUP-CHROME]
 * [NOTE] If "history" is true, downloads will also be cleared
 * [NOTE] "sessions": Active Logins: refers to HTTP Basic Authentication [1], not logins via cookies
 * [1] https://en.wikipedia.org/wiki/Basic_access_authentication
 */
user_pref("privacy.clearOnShutdown.history", false);

/**
 * 4501: enable privacy.resistFingerprinting [FF41+]
 * [SETUP-WEB] RFP can cause some website breakage: mainly canvas, use a site exception via the urlbar
 * RFP also has a few side effects: mainly timezone is UTC0, and websites will prefer light theme
 * [1] https://bugzilla.mozilla.org/418986
 */
user_pref("privacy.resistFingerprinting", false);

/**
 * 4504: enable RFP letterboxing [FF67+]
 * Dynamically resizes the inner window by applying margins in stepped ranges [2]
 * If you use the dimension pref, then it will only apply those resolutions.
 * The format is "width1xheight1, width2xheight2, ..." (e.g. "800x600, 1000x1000")
 * [SETUP-WEB] This is independent of RFP (4501). If you're not using RFP, or you are but
 * dislike the margins, then flip this pref, keeping in mind that it is effectively fingerprintable
 * [WARNING] DO NOT USE: the dimension pref is only meant for testing
 * [1] https://bugzilla.mozilla.org/1407366
 * [2] https://hg.mozilla.org/mozilla-central/rev/6d2d7856e468#l2.32
 */
user_pref("privacy.resistFingerprinting.letterboxing", false);

/**
 * 4520: disable WebGL (Web Graphics Library)
 * [SETUP-WEB] If you need it then override it. RFP still randomizes canvas for naive scripts
 */
user_pref("webgl.disabled", false);

/**
 * 5003: disable saving passwords
 * [NOTE] This does not clear any passwords already saved
 * [SETTING] Privacy & Security>Logins and Passwords>Ask to save logins and passwords for websites
 */
user_pref("signon.rememberSignons", true);

/**
 * Enable WebGPU by default.
 */
user_pref("dom.webgpu.enabled", true);
