/**
 * 0102: set startup page [SETUP-CHROME]
 * 0=blank, 1=home, 2=last visited page, 3=resume previous session
 * [NOTE] Session Restore is cleared with history (2811), and not used in Private Browsing mode
 * [SETTING] General>Startup>Restore previous session
 */
user_pref('browser.startup.page', 3);
/**
 * 0801: disable location bar using search
 * Don't leak URL typos to a search engine, give an error message instead
 * Examples: "secretplace,com", "secretplace/com", "secretplace com", "secret place.com"
 * [NOTE] This does not affect explicit user action such as using search buttons in the
 * dropdown, or using keyword search shortcuts you configure in options (e.g. "d" for DuckDuckGo)
 * [SETUP-CHROME] Override this if you trust and use a privacy respecting search engine
 */
user_pref('keyword.enabled', true);
/**
 * 0804: disable live search suggestions
 * [NOTE] Both must be true for the location bar to work
 * [SETUP-CHROME] Override these if you trust and use a privacy respecting search engine
 * [SETTING] Search>Provide search suggestions | Show search suggestions in address bar results
 */
user_pref('browser.search.suggest.enabled', true);
user_pref('browser.urlbar.suggest.searches', true);
/**
 * 2811: set/enforce what items to clear on shutdown (if 2810 is true) [SETUP-CHROME]
 * [NOTE] If "history" is true, downloads will also be cleared
 * [NOTE] "sessions": Active Logins: refers to HTTP Basic Authentication [1], not logins via cookies
 * [1] https://en.wikipedia.org/wiki/Basic_access_authentication
 */
user_pref('privacy.clearOnShutdown.history', false);
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
user_pref('privacy.resistFingerprinting.letterboxing', false);
// user_pref("browser.sessionstore.privacy_level", 0); // 1003 optional to restore cookies/formdata
// user_pref("privacy.clearOnShutdown.history", false); // 2811
// user_pref("privacy.cpd.history", false); // 2820 optional to match when you use Ctrl-Shift-Del
