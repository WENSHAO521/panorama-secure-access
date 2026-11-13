// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a en locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'en';

  static String m0(count) =>
      "${Intl.plural(count, other: '${count} selected')}";

  static String m1(name) => "Added ${name} to local proxies";

  static String m2(name) => "${name} is already in local proxies";

  static String m3(count, skipped) =>
      "${count} to add, ${skipped} skipped as existing";

  static String m4(detail) => "Couldn\'t clear the data: ${detail}";

  static String m5(names) =>
      "Other proxy clients are running: ${names}. Two TUN modes or system proxies override each other; quit the others before turning on TUN or the system proxy.";

  static String m6(code) =>
      "Windows refused to run panorama-secure-access-core.exe (error ${code}). An app control policy such as Smart App Control or AppLocker blocks unsigned programs; allow Panorama Secure Access in that policy or turn it off, then try again.";

  static String m7(name) =>
      "The app failed to finish launching twice in a row. To break the loop, the profile ${name} has been deselected and automatic setup was skipped. You can select it again at any time.";

  static String m8(url) => "Do you want to create a profile from ${url}?";

  static String m9(count, label) =>
      "${Intl.plural(count, one: '1 SUB-RULE rule was dropped, since custom profiles do not support sub-rules', other: '${label} SUB-RULE rules were dropped, since custom profiles do not support sub-rules')}";

  static String m10(message) => "The core cannot parse this proxy: ${message}";

  static String m11(proxy, target) =>
      "${proxy} dials through ${target}, which leads back to ${proxy}, so the dial loops";

  static String m12(name) =>
      "The name ${name} is already used by another proxy or proxy group";

  static String m13(path) =>
      "Proxy groups reference each other in a loop: ${path}";

  static String m14(name) =>
      "The empty fallback must be a proxy, but ${name} does not exist or is a proxy group";

  static String m15(name, message) =>
      "${name} is not a valid regex: ${message}";

  static String m16(name) => "The dialer proxy ${name} does not exist";

  static String m17(names) => "These proxy providers do not exist: ${names}";

  static String m18(names) =>
      "These proxies or policies do not exist: ${names}";

  static String m19(name) =>
      "${name} is a built-in policy name and cannot be used here";

  static String m20(count) =>
      "${count} items have problems, and applying this profile may fail";

  static String m21(count) =>
      "${Intl.plural(count, one: '1 day ago', other: '${count} days ago')}";

  static String m22(count) => "${Intl.plural(count, other: '${count}d ago')}";

  static String m23(label) =>
      "Are you sure you want to delete the selected ${label}?";

  static String m24(label) => "Are you sure you want to delete this ${label}?";

  static String m25(label) => "${label} details";

  static String m26(name) =>
      "Dialing through ${name} leads back to the proxy that uses it, so the connection was stopped";

  static String m27(label) => "${label} cannot be empty";

  static String m28(label) => "${label} already exists";

  static String m29(count) => "${count} items failed. Tap to view";

  static String m30(label, message) => "${label}: ${message}";

  static String m31(name) => "${name} is already up to date";

  static String m32(name) => "${name} updated";

  static String m33(count) =>
      "${Intl.plural(count, one: '1 group', other: '${count} groups')}";

  static String m34(name) =>
      "No node is left after filtering, so traffic goes to ${name}";

  static String m35(count) => "${count} timed out";

  static String m36(action) =>
      "Already used by “${action}”. Saving moves it here.";

  static String m37(modifiers) => "Include at least one of ${modifiers}";

  static String m38(count) =>
      "${Intl.plural(count, one: '1 hour ago', other: '${count} hours ago')}";

  static String m39(count) => "${Intl.plural(count, other: '${count}h ago')}";

  static String m40(encoding) =>
      "Could not decode ${encoding}, so this is the data as it was sent.";

  static String m41(memory, body) =>
      "The oldest records go first once this many are kept or they fill ${memory} of memory. Each body keeps its first ${body}.";

  static String m42(label) =>
      "${label} contains characters that are not allowed";

  static String m43(invalid, total) => "${invalid} of ${total} invalid";

  static String m44(target) => "${target} is an invalid policy";

  static String m45(proxyName) => "${proxyName} is an invalid proxy";

  static String m46(providerName) =>
      "${providerName} is an invalid proxy provider";

  static String m47(ruleSet) => "${ruleSet} is an invalid rule set";

  static String m48(subRule) => "${subRule} is an invalid SUB_RULE";

  static String m49(count) =>
      "${Intl.plural(count, one: '1 item', other: '${count} items')}";

  static String m50(name) =>
      "The previous version (${name}) is still installed. Android cannot upgrade it in place because the app ID changed, and it cannot read another app\'s data. In the previous version open Tools → Backup and restore and back up to a local file, then restore that file here. Uninstall the previous version afterwards.";

  static String m51(path) =>
      "Your profiles, rules and settings were copied from the previous installation (${path}). The original files were left unchanged.";

  static String m52(name) =>
      "An earlier Panorama Secure Access, installed under FlClash\'s identifiers, is still on this device (${name}). Your data has already been copied. Remove it so the two do not compete for the TUN device, ports and system proxy? FlClash itself is not affected.";

  static String m53(line, message) => "Line ${line}: ${message}";

  static String m54(appName) =>
      "1. Open System Settings > Privacy & Security\n2. Choose Location Services\n3. Find and check ${appName} in the list\n\nWhen you are done, return to the app to continue. Thank you for your cooperation.";

  static String m55(label, max) => "${label} must be at most ${max} characters";

  static String m56(size) => "Released ${size}";

  static String m57(count) =>
      "${Intl.plural(count, one: '1 minute ago', other: '${count} minutes ago')}";

  static String m58(count) => "${Intl.plural(count, other: '${count}m ago')}";

  static String m59(fileName) =>
      "Saved ${fileName} to Downloads. Install it in Settings under Security › Encryption & credentials › Install a certificate › CA certificate.";

  static String m60(command) =>
      "Chrome and Firefox keep their own certificate stores, which need certutil: ${command}";

  static String m61(host) =>
      "Add ${host} to the hostname list? Panorama Secure Access can then read what is sent to it, cookies and passwords included.";

  static String m62(host) =>
      "Add -${host} to the top of the hostname list? The host is then never decrypted.";

  static String m63(size) => "The file is larger than ${size} MB";

  static String m64(stores) => "Not yet in: ${stores}";

  static String m65(name) => "${name} changed its scripts and was turned off";

  static String m66(system) =>
      "Written for ${system}; some lines may not match apps on this device.";

  static String m67(name) =>
      "The old certificate, ${name}, could not be removed. Remove it from the trusted roots yourself.";

  static String m68(name) =>
      "The old certificate, ${name}, is still among the system\'s trusted CAs. Allow Panorama Secure Access root access in your root manager and regenerate, or remove the Panorama Secure Access MITM CA module there and restart.";

  static String m69(name) =>
      "Remove the old certificate, ${name}, in Settings under Security › Encryption & credentials › Trusted credentials › User, then install the new one.";

  static String m70(section) => "The [${section}] section is not supported";

  static String m71(count) =>
      "${Intl.plural(count, one: '1 month ago', other: '${count} months ago')}";

  static String m72(count) => "${Intl.plural(count, other: '${count}mo ago')}";

  static String m73(code) =>
      "The server denied access (HTTP ${code}). The link may have expired, or the credentials are wrong";

  static String m74(code) => "The server rejected the request (HTTP ${code})";

  static String m75(count) =>
      "${count} problem(s) found. Use the button next to an item to fix it.";

  static String m76(code) =>
      "Nothing was found at this address (HTTP ${code}). Check that the URL is correct";

  static String m77(detail) => "Network request failed: ${detail}";

  static String m78(code) =>
      "The server ran into a problem (HTTP ${code}). Try again later";

  static String m79(label) => "No ${label} yet";

  static String m80(label, min, max) =>
      "${label} must be between ${min} and ${max}";

  static String m81(label) => "${label} must be a number";

  static String m82(port) =>
      "Port ${port} is used by another program, so the proxy port could not start. Change the mixed port under Ports.";

  static String m83(port, free) =>
      "Another program is listening on port ${port}, so the proxy port cannot start there, and the system proxy would send your traffic to that program instead. Switch the mixed port to the free port ${free}?";

  static String m84(port) => "Port ${port} is already in use";

  static String m85(label) => "${label} must be between 1024 and 49151";

  static String m86(port) => "Port ${port}";

  static String m87(days) =>
      "${Intl.plural(days, one: '1 day left', other: '${days} days left')}";

  static String m88(date, days) =>
      "Expires ${date}, ${Intl.plural(days, one: '1 day', other: '${days} days')} left";

  static String m89(time) => "Updated ${time}";

  static String m90(label, profiles) =>
      "${label} is still used by ${profiles}, which will not work properly once it is deleted. Are you sure you want to delete it?";

  static String m91(count, label) =>
      "${Intl.plural(count, one: '1 proxy', other: '${label} proxies')}";

  static String m92(name, count) => "${name} and others (${count} proxies)";

  static String m93(removed) =>
      "These proxies will be deleted: ${removed}. A line whose name changed counts as a new proxy, and custom profiles naming the deleted ones will flag them as missing. Apply anyway?";

  static String m94(removed, added) =>
      "These proxies will be deleted: ${removed}. These will be added: ${added}. A line whose name changed counts as a new proxy, and custom profiles naming the deleted ones will flag them as missing. Apply anyway?";

  static String m95(label) =>
      "${label} is still named by rules, proxy groups, dialer proxies, DNS or NTP in this profile, which stop working once it is deleted. Are you sure you want to delete it?";

  static String m96(count, label) =>
      "${Intl.plural(count, one: '1 proxy group', other: '${label} proxy groups')}";

  static String m97(version, tag) =>
      "Data from v${version}, saved before updating to ${tag}";

  static String m98(count, label) =>
      "${Intl.plural(count, one: '1 rule', other: '${label} rules')}";

  static String m99(appName) => "${appName} (Safe mode)";

  static String m100(count) =>
      "${Intl.plural(count, one: '1 second', other: '${count} seconds')}";

  static String m101(count) => "${count} in effect";

  static String m102(count) =>
      "${Intl.plural(count, one: '1 issue', other: '${count} issues')}";

  static String m103(count) =>
      "${Intl.plural(count, one: '1 setting', other: '${count} settings')}";

  static String m104(link) => "No proxy could be read from ${link}";

  static String m105(label) => "${label} must be a single item";

  static String m106(value) => "Peak ${value}";

  static String m107(value) => "Total ${value}";

  static String m108(transport) => "${transport} Headers";

  static String m109(label) => "${label} must be a URL";

  static String m110(date) => "Valid until ${date}";

  static String m111(count) =>
      "${Intl.plural(count, one: '1 year ago', other: '${count} years ago')}";

  static String m112(count) => "${Intl.plural(count, other: '${count}y ago')}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "about": MessageLookupByLibrary.simpleMessage("About"),
    "accessControl": MessageLookupByLibrary.simpleMessage("Access control"),
    "accessControlAllowDesc": MessageLookupByLibrary.simpleMessage(
      "Only selected apps go through the VPN",
    ),
    "accessControlDisabledDesc": MessageLookupByLibrary.simpleMessage(
      "App access control is disabled",
    ),
    "accessControlNotAllowDesc": MessageLookupByLibrary.simpleMessage(
      "Selected apps are excluded from the VPN",
    ),
    "accessControlSelectedCount": m0,
    "account": MessageLookupByLibrary.simpleMessage("Account"),
    "action": MessageLookupByLibrary.simpleMessage("Action"),
    "actionDelayTest": MessageLookupByLibrary.simpleMessage("Test all delays"),
    "actionDirectMode": MessageLookupByLibrary.simpleMessage("Direct mode"),
    "actionGlobalMode": MessageLookupByLibrary.simpleMessage("Global mode"),
    "actionMode": MessageLookupByLibrary.simpleMessage("Switch mode"),
    "actionProxy": MessageLookupByLibrary.simpleMessage("System proxy"),
    "actionRuleMode": MessageLookupByLibrary.simpleMessage("Rule mode"),
    "actionStart": MessageLookupByLibrary.simpleMessage("Start/Stop"),
    "actionTun": MessageLookupByLibrary.simpleMessage("TUN"),
    "actionUpdateProfiles": MessageLookupByLibrary.simpleMessage(
      "Update profiles",
    ),
    "actionView": MessageLookupByLibrary.simpleMessage("Show/Hide"),
    "add": MessageLookupByLibrary.simpleMessage("Add"),
    "addCustomProxy": MessageLookupByLibrary.simpleMessage("Add proxy"),
    "addFilters": MessageLookupByLibrary.simpleMessage("Add filters"),
    "addNodes": MessageLookupByLibrary.simpleMessage("Add nodes"),
    "addOverrideEntry": MessageLookupByLibrary.simpleMessage(
      "Add override entry",
    ),
    "addProfile": MessageLookupByLibrary.simpleMessage("Add profile"),
    "addProxyGroup": MessageLookupByLibrary.simpleMessage("Add proxy group"),
    "addRule": MessageLookupByLibrary.simpleMessage("Add rule"),
    "addSettingEntry": MessageLookupByLibrary.simpleMessage("Add setting"),
    "addSsid": MessageLookupByLibrary.simpleMessage("Add SSID"),
    "addToLocalProxies": MessageLookupByLibrary.simpleMessage(
      "Add to local proxies",
    ),
    "addedRules": MessageLookupByLibrary.simpleMessage("Added rules"),
    "addedToLocalProxies": m1,
    "additionalParameters": MessageLookupByLibrary.simpleMessage(
      "Additional parameters",
    ),
    "additionalPrefix": MessageLookupByLibrary.simpleMessage("Name prefix"),
    "additionalSuffix": MessageLookupByLibrary.simpleMessage("Name suffix"),
    "address": MessageLookupByLibrary.simpleMessage("Address"),
    "addressTip": MessageLookupByLibrary.simpleMessage(
      "Please enter a valid WebDAV address",
    ),
    "advancedConfig": MessageLookupByLibrary.simpleMessage(
      "Advanced configuration",
    ),
    "ageEncryptedProfile": MessageLookupByLibrary.simpleMessage(
      "Encrypted profile",
    ),
    "ageSecretKey": MessageLookupByLibrary.simpleMessage("Age secret key"),
    "ageSecretKeyRequiredTip": MessageLookupByLibrary.simpleMessage(
      "This profile is encrypted with age and needs an age secret key to decrypt",
    ),
    "agree": MessageLookupByLibrary.simpleMessage("Agree"),
    "allReferencedProxies": MessageLookupByLibrary.simpleMessage(
      "All referenced proxies",
    ),
    "allReferencedProxyProviders": MessageLookupByLibrary.simpleMessage(
      "All referenced proxy providers",
    ),
    "allowBypass": MessageLookupByLibrary.simpleMessage(
      "Allow apps to bypass VPN",
    ),
    "allowLan": MessageLookupByLibrary.simpleMessage("Allow LAN"),
    "allowedIps": MessageLookupByLibrary.simpleMessage("Allowed IPs"),
    "alreadyInLocalProxies": m2,
    "answers": MessageLookupByLibrary.simpleMessage("Answers"),
    "app": MessageLookupByLibrary.simpleMessage("App"),
    "appAccessControl": MessageLookupByLibrary.simpleMessage(
      "App access control",
    ),
    "appIconDesign": MessageLookupByLibrary.simpleMessage("App icon design"),
    "appProxiesEmpty": MessageLookupByLibrary.simpleMessage("No local proxies"),
    "appendSystemDns": MessageLookupByLibrary.simpleMessage(
      "Append system DNS",
    ),
    "applied": MessageLookupByLibrary.simpleMessage("Applied"),
    "applyNow": MessageLookupByLibrary.simpleMessage("Apply now"),
    "arguments": MessageLookupByLibrary.simpleMessage("Arguments"),
    "authentication": MessageLookupByLibrary.simpleMessage("Authentication"),
    "authenticationSystemProxyDesc": MessageLookupByLibrary.simpleMessage(
      "The system proxy is not applied while authentication is on.",
    ),
    "authorize": MessageLookupByLibrary.simpleMessage("Authorize"),
    "authorized": MessageLookupByLibrary.simpleMessage("Authorized"),
    "auto": MessageLookupByLibrary.simpleMessage("Auto"),
    "autoCheckUpdate": MessageLookupByLibrary.simpleMessage(
      "Auto check for updates",
    ),
    "autoCloseConnections": MessageLookupByLibrary.simpleMessage(
      "Auto close connections",
    ),
    "autoInclude": MessageLookupByLibrary.simpleMessage("Auto-include"),
    "autoLaunch": MessageLookupByLibrary.simpleMessage("Auto launch"),
    "autoRun": MessageLookupByLibrary.simpleMessage("Auto run"),
    "autoRunDesc": MessageLookupByLibrary.simpleMessage(
      "Auto run starts the proxy when the app opens.",
    ),
    "autoSetSystemDns": MessageLookupByLibrary.simpleMessage(
      "Auto-set system DNS",
    ),
    "autoUpdate": MessageLookupByLibrary.simpleMessage("Auto update"),
    "autoUpdateInterval": MessageLookupByLibrary.simpleMessage(
      "Auto-update interval",
    ),
    "back": MessageLookupByLibrary.simpleMessage("Back"),
    "backgroundBlur": MessageLookupByLibrary.simpleMessage("Background blur"),
    "backup": MessageLookupByLibrary.simpleMessage("Backup"),
    "backupAndRestore": MessageLookupByLibrary.simpleMessage(
      "Backup and restore",
    ),
    "backupFromNewerVersion": MessageLookupByLibrary.simpleMessage(
      "This backup comes from a newer version of the app. Update the app before restoring it",
    ),
    "backupSuccess": MessageLookupByLibrary.simpleMessage("Backup successful"),
    "basicInfo": MessageLookupByLibrary.simpleMessage("Basic info"),
    "basicStrategy": MessageLookupByLibrary.simpleMessage("Basic strategies"),
    "batchImport": MessageLookupByLibrary.simpleMessage("Batch import"),
    "batchLineInputTip": MessageLookupByLibrary.simpleMessage(
      "One item per line",
    ),
    "batchLinkInputTip": MessageLookupByLibrary.simpleMessage(
      "One link per line",
    ),
    "batchPreviewTip": m3,
    "batchUrlInputTip": MessageLookupByLibrary.simpleMessage(
      "One URL per line",
    ),
    "betaChannel": MessageLookupByLibrary.simpleMessage("Beta"),
    "betaChannelSaveFailed": MessageLookupByLibrary.simpleMessage(
      "The setting could not be saved, so the update channel is unchanged.",
    ),
    "betaJoinConfirm": MessageLookupByLibrary.simpleMessage("Join"),
    "betaJoinConfirmDesc": MessageLookupByLibrary.simpleMessage(
      "Beta builds get new features first, but they can be less stable and may not work with every profile, rule set or system. You can leave at any time.",
    ),
    "betaJoinConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Join the beta program?",
    ),
    "betaJoinedTip": MessageLookupByLibrary.simpleMessage(
      "You receive beta updates",
    ),
    "betaLeaveConfirm": MessageLookupByLibrary.simpleMessage("Leave"),
    "betaLeaveConfirmDesc": MessageLookupByLibrary.simpleMessage(
      "You will stop receiving beta updates. The installed beta is not removed or downgraded: you keep it until a stable release of the same or a newer version ships, then the app returns to stable.",
    ),
    "betaLeaveConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Leave the beta program?",
    ),
    "betaNotJoinedTip": MessageLookupByLibrary.simpleMessage(
      "You receive stable updates only",
    ),
    "betaProgram": MessageLookupByLibrary.simpleMessage("Beta program"),
    "betaProgramDesc": MessageLookupByLibrary.simpleMessage(
      "Try new features before they are released and help find problems early. Beta builds can be less stable than stable releases.",
    ),
    "betaProgramFooter": MessageLookupByLibrary.simpleMessage(
      "When the beta ends and a stable release of the same or a newer version ships, the app updates to it automatically. You can leave at any time: you keep the current beta until that stable release is out, then return to it.",
    ),
    "betaStay": MessageLookupByLibrary.simpleMessage("Keep the beta"),
    "betaUpdates": MessageLookupByLibrary.simpleMessage("Join the beta"),
    "binaryData": MessageLookupByLibrary.simpleMessage("Binary data"),
    "bind": MessageLookupByLibrary.simpleMessage("Bind"),
    "blacklistMode": MessageLookupByLibrary.simpleMessage("Blacklist mode"),
    "blockQuic": MessageLookupByLibrary.simpleMessage("Block QUIC"),
    "bodyRewrite": MessageLookupByLibrary.simpleMessage("Body rewrite"),
    "brightness": MessageLookupByLibrary.simpleMessage("Brightness"),
    "bypassDomain": MessageLookupByLibrary.simpleMessage("Bypass domains"),
    "bypassDomainDesc": MessageLookupByLibrary.simpleMessage(
      "Bypass domains apply only while the system proxy is on.",
    ),
    "bypassPrivateRoute": MessageLookupByLibrary.simpleMessage(
      "Bypass private addresses",
    ),
    "cache": MessageLookupByLibrary.simpleMessage("Cache"),
    "cacheAlgorithm": MessageLookupByLibrary.simpleMessage("Cache algorithm"),
    "cacheCorrupt": MessageLookupByLibrary.simpleMessage(
      "The cache is corrupted. Clear it?",
    ),
    "cacheMaxSize": MessageLookupByLibrary.simpleMessage("Cache size"),
    "cameraPermissionDesc": MessageLookupByLibrary.simpleMessage(
      "Allow camera access in system settings to scan QR codes, or choose a QR code image from the album.",
    ),
    "cameraPermissionRequired": MessageLookupByLibrary.simpleMessage(
      "Camera permission required",
    ),
    "cameraUnavailable": MessageLookupByLibrary.simpleMessage(
      "Camera unavailable",
    ),
    "cancel": MessageLookupByLibrary.simpleMessage("Cancel"),
    "cancelSelectAll": MessageLookupByLibrary.simpleMessage("Deselect all"),
    "cannotSave": MessageLookupByLibrary.simpleMessage("Can\'t save"),
    "certificate": MessageLookupByLibrary.simpleMessage("Certificate"),
    "changeProxyFailedTip": MessageLookupByLibrary.simpleMessage(
      "Failed to switch proxy; the previous selection has been restored",
    ),
    "changelogBreaking": MessageLookupByLibrary.simpleMessage(
      "Breaking changes",
    ),
    "changelogFeatures": MessageLookupByLibrary.simpleMessage("New features"),
    "changelogFixes": MessageLookupByLibrary.simpleMessage("Bug fixes"),
    "changelogPerformance": MessageLookupByLibrary.simpleMessage("Performance"),
    "changelogReverts": MessageLookupByLibrary.simpleMessage("Reverts"),
    "checkCertificate": MessageLookupByLibrary.simpleMessage(
      "Verify TLS certificates",
    ),
    "checkCertificateDesc": MessageLookupByLibrary.simpleMessage(
      "With TLS verification off, subscriptions and backups are open to man-in-the-middle attacks.",
    ),
    "checkUpdate": MessageLookupByLibrary.simpleMessage("Check for updates"),
    "checkUpdateError": MessageLookupByLibrary.simpleMessage(
      "The app is already up to date",
    ),
    "cipher": MessageLookupByLibrary.simpleMessage("Cipher"),
    "clearData": MessageLookupByLibrary.simpleMessage("Clear data"),
    "clearDataAndExitTip": MessageLookupByLibrary.simpleMessage(
      "This deletes all profiles, settings, and local data, then closes the app. Open it again to start fresh.",
    ),
    "clearDataFailed": m4,
    "clearDnsCache": MessageLookupByLibrary.simpleMessage("Clear DNS cache"),
    "clearDnsCacheFailed": MessageLookupByLibrary.simpleMessage(
      "Failed to clear DNS cache",
    ),
    "clearSearch": MessageLookupByLibrary.simpleMessage("Clear search"),
    "clientFingerprint": MessageLookupByLibrary.simpleMessage(
      "Client fingerprint",
    ),
    "clipboardExport": MessageLookupByLibrary.simpleMessage(
      "Export to clipboard",
    ),
    "clipboardImport": MessageLookupByLibrary.simpleMessage(
      "Import from clipboard",
    ),
    "clipboardNoPackageNames": MessageLookupByLibrary.simpleMessage(
      "No package names found in the clipboard",
    ),
    "clipboardWriteFailed": MessageLookupByLibrary.simpleMessage(
      "Couldn\'t copy to the clipboard. The selection may be too large",
    ),
    "close": MessageLookupByLibrary.simpleMessage("Close"),
    "closeConnection": MessageLookupByLibrary.simpleMessage("Close connection"),
    "closeConnections": MessageLookupByLibrary.simpleMessage(
      "Close connections",
    ),
    "color": MessageLookupByLibrary.simpleMessage("Color"),
    "colorStyle": MessageLookupByLibrary.simpleMessage("Color style"),
    "columns": MessageLookupByLibrary.simpleMessage("Columns"),
    "compact": MessageLookupByLibrary.simpleMessage("Compact"),
    "compatible": MessageLookupByLibrary.simpleMessage("Compatibility mode"),
    "confirm": MessageLookupByLibrary.simpleMessage("Confirm"),
    "confirmClearAllData": MessageLookupByLibrary.simpleMessage(
      "Are you sure you want to clear all data?",
    ),
    "confirmDeleteProxyGroup": MessageLookupByLibrary.simpleMessage(
      "Are you sure you want to delete this proxy group?",
    ),
    "confirmExitWindow": MessageLookupByLibrary.simpleMessage(
      "Are you sure you want to exit the current window?",
    ),
    "confirmForceCrashCore": MessageLookupByLibrary.simpleMessage(
      "Are you sure you want to force crash the core?",
    ),
    "conflictingClientsTip": m5,
    "congestionControl": MessageLookupByLibrary.simpleMessage(
      "Congestion control",
    ),
    "congestionController": MessageLookupByLibrary.simpleMessage(
      "TCP congestion control",
    ),
    "congestionControllerDesc": MessageLookupByLibrary.simpleMessage(
      "TCP congestion control works only with the mips stack.",
    ),
    "connected": MessageLookupByLibrary.simpleMessage("Connected"),
    "connecting": MessageLookupByLibrary.simpleMessage("Connecting…"),
    "connection": MessageLookupByLibrary.simpleMessage("Connection"),
    "connectionStats": MessageLookupByLibrary.simpleMessage("Connection stats"),
    "connectionStatsDesc": MessageLookupByLibrary.simpleMessage(
      "Live connections, recent requests and DNS queries",
    ),
    "connections": MessageLookupByLibrary.simpleMessage("Connections"),
    "connectivity": MessageLookupByLibrary.simpleMessage("Connectivity: "),
    "content": MessageLookupByLibrary.simpleMessage("Content"),
    "contentNotEmpty": MessageLookupByLibrary.simpleMessage(
      "Content cannot be empty",
    ),
    "controlGlobalAddedRules": MessageLookupByLibrary.simpleMessage(
      "Control global added rules",
    ),
    "copy": MessageLookupByLibrary.simpleMessage("Copy"),
    "copyAsBase64": MessageLookupByLibrary.simpleMessage("Copy as Base64"),
    "copyAsCurl": MessageLookupByLibrary.simpleMessage("Copy as cURL"),
    "copyDestination": MessageLookupByLibrary.simpleMessage("Copy destination"),
    "copyEnvVar": MessageLookupByLibrary.simpleMessage(
      "Copy environment variables",
    ),
    "copyHost": MessageLookupByLibrary.simpleMessage("Copy host"),
    "copyLink": MessageLookupByLibrary.simpleMessage("Copy link"),
    "copyRequest": MessageLookupByLibrary.simpleMessage("Copy request"),
    "copyResponse": MessageLookupByLibrary.simpleMessage("Copy response"),
    "copyResponseBody": MessageLookupByLibrary.simpleMessage(
      "Copy response body",
    ),
    "copySuccess": MessageLookupByLibrary.simpleMessage("Copied successfully"),
    "core": MessageLookupByLibrary.simpleMessage("Core"),
    "coreBlockedByPolicyTip": m6,
    "coreBlockedBySmartAppControlTip": MessageLookupByLibrary.simpleMessage(
      "Windows Smart App Control blocked panorama-secure-access-core.exe because it is not signed. Open Windows Security → App & browser control → Smart App Control settings, choose Off, then start Panorama Secure Access again. Smart App Control cannot be turned back on without reinstalling Windows.",
    ),
    "coreStatus": MessageLookupByLibrary.simpleMessage("Core status"),
    "country": MessageLookupByLibrary.simpleMessage("Region"),
    "crashDetected": MessageLookupByLibrary.simpleMessage("Crash detected"),
    "crashDetectedTip": m7,
    "crashTest": MessageLookupByLibrary.simpleMessage("Crash test"),
    "create": MessageLookupByLibrary.simpleMessage("Create"),
    "createProfileFromUrlTip": m8,
    "creationTime": MessageLookupByLibrary.simpleMessage("Creation time"),
    "currentOutboundDesc": MessageLookupByLibrary.simpleMessage(
      "Holds the start button and can\'t be removed",
    ),
    "currentVersion": MessageLookupByLibrary.simpleMessage("Current version"),
    "custom": MessageLookupByLibrary.simpleMessage("Custom"),
    "customColor": MessageLookupByLibrary.simpleMessage("Custom color"),
    "customImportDroppedSubRules": m9,
    "customIssueCoreRejected": m10,
    "customIssueDialerLoop": m11,
    "customIssueDuplicateName": m12,
    "customIssueEmptyName": MessageLookupByLibrary.simpleMessage(
      "The name is empty",
    ),
    "customIssueGroupLoop": m13,
    "customIssueInvalidEmptyFallback": m14,
    "customIssueInvalidFilter": m15,
    "customIssueMissingDialer": m16,
    "customIssueMissingProviders": m17,
    "customIssueMissingProxies": m18,
    "customIssueNoProxySource": MessageLookupByLibrary.simpleMessage(
      "No proxies or proxy providers are selected, so the core rejects this group",
    ),
    "customIssueReservedName": m19,
    "customIssuesSummary": m20,
    "customProfile": MessageLookupByLibrary.simpleMessage("Custom"),
    "customResources": MessageLookupByLibrary.simpleMessage("Custom"),
    "customTraffic": MessageLookupByLibrary.simpleMessage("Custom traffic"),
    "customTrafficDesc": MessageLookupByLibrary.simpleMessage(
      "Replaces the total the subscription reports. Leave empty to use it.",
    ),
    "customTrafficInvalidDesc": MessageLookupByLibrary.simpleMessage(
      "Enter a traffic amount above 0",
    ),
    "customTrafficTooLargeDesc": MessageLookupByLibrary.simpleMessage(
      "Enter at most 1024 TB",
    ),
    "cut": MessageLookupByLibrary.simpleMessage("Cut"),
    "dark": MessageLookupByLibrary.simpleMessage("Dark"),
    "dashboard": MessageLookupByLibrary.simpleMessage("Dashboard"),
    "dashboardAddableSection": MessageLookupByLibrary.simpleMessage(
      "Available to add",
    ),
    "databaseWriteFailedTip": MessageLookupByLibrary.simpleMessage(
      "Failed to save the change; it has been rolled back",
    ),
    "daysAgo": m21,
    "daysAgoShort": m22,
    "decryptUntrusted": MessageLookupByLibrary.simpleMessage(
      "Decrypt without local trust",
    ),
    "defaultNameserverDesc": MessageLookupByLibrary.simpleMessage(
      "Resolves the hostnames of the other DNS servers. Use IP addresses only.",
    ),
    "defaultSelected": MessageLookupByLibrary.simpleMessage(
      "Default selection",
    ),
    "defaultText": MessageLookupByLibrary.simpleMessage("Default"),
    "definitionNotMap": MessageLookupByLibrary.simpleMessage(
      "The configuration must be a YAML mapping with a name and a type",
    ),
    "delay": MessageLookupByLibrary.simpleMessage("Delay"),
    "delayDnsFailed": MessageLookupByLibrary.simpleMessage("DNS failed"),
    "delayFailed": MessageLookupByLibrary.simpleMessage("Failed"),
    "delayTest": MessageLookupByLibrary.simpleMessage("Delay test"),
    "delayTestTimeout": MessageLookupByLibrary.simpleMessage(
      "Delay test timeout",
    ),
    "delete": MessageLookupByLibrary.simpleMessage("Delete"),
    "deleteMultipTip": m23,
    "deleteTip": m24,
    "desc": MessageLookupByLibrary.simpleMessage(
      "A multi-platform proxy client based on ClashMeta, simple and easy to use, open-source and ad-free.",
    ),
    "destination": MessageLookupByLibrary.simpleMessage("Destination"),
    "destinationGeoIP": MessageLookupByLibrary.simpleMessage(
      "Destination GeoIP",
    ),
    "destinationIPASN": MessageLookupByLibrary.simpleMessage(
      "Destination IP ASN",
    ),
    "details": m25,
    "detectionTip": MessageLookupByLibrary.simpleMessage(
      "Relies on a third-party API; for reference only",
    ),
    "developerMode": MessageLookupByLibrary.simpleMessage("Developer mode"),
    "developerModeEnableTip": MessageLookupByLibrary.simpleMessage(
      "Developer mode is enabled.",
    ),
    "diagnosisCore": MessageLookupByLibrary.simpleMessage("Core"),
    "diagnosisDns": MessageLookupByLibrary.simpleMessage("DNS resolution"),
    "diagnosisFailed": MessageLookupByLibrary.simpleMessage("Failed"),
    "diagnosisHostLookup": MessageLookupByLibrary.simpleMessage(
      "Name lookup failed",
    ),
    "diagnosisIpv4": MessageLookupByLibrary.simpleMessage("IPv4 connectivity"),
    "diagnosisIpv6": MessageLookupByLibrary.simpleMessage("IPv6 connectivity"),
    "diagnosisMixedPort": MessageLookupByLibrary.simpleMessage("Proxy port"),
    "diagnosisNotConfigured": MessageLookupByLibrary.simpleMessage(
      "Not configured on this network",
    ),
    "diagnosisOtherClients": MessageLookupByLibrary.simpleMessage(
      "Other proxy clients",
    ),
    "diagnosisProxyFault": MessageLookupByLibrary.simpleMessage(
      "The proxy answered with an error",
    ),
    "diagnosisProxyRequest": MessageLookupByLibrary.simpleMessage(
      "Request through the proxy",
    ),
    "diagnosisRefused": MessageLookupByLibrary.simpleMessage(
      "Connection refused",
    ),
    "diagnosisSystemProxy": MessageLookupByLibrary.simpleMessage(
      "System proxy",
    ),
    "diagnosisTimeout": MessageLookupByLibrary.simpleMessage("Timed out"),
    "diagnosisTls": MessageLookupByLibrary.simpleMessage(
      "TLS handshake failed",
    ),
    "diagnosisTun": MessageLookupByLibrary.simpleMessage("TUN authorization"),
    "diagnosisUnreachable": MessageLookupByLibrary.simpleMessage("No route"),
    "dialerProxy": MessageLookupByLibrary.simpleMessage("Dialer proxy"),
    "dialerProxyLoopStopped": m26,
    "dialog": MessageLookupByLibrary.simpleMessage("Dialog"),
    "direct": MessageLookupByLibrary.simpleMessage("Direct"),
    "directNameserverDesc": MessageLookupByLibrary.simpleMessage(
      "Resolves domains for connections that go direct.",
    ),
    "disableIcmpForwarding": MessageLookupByLibrary.simpleMessage(
      "Disable ICMP forwarding",
    ),
    "disableIcmpForwardingDesc": MessageLookupByLibrary.simpleMessage(
      "With ICMP forwarding disabled, TUN answers ping itself, so ping no longer shows the real latency.",
    ),
    "disableKeepAlive": MessageLookupByLibrary.simpleMessage(
      "Disable TCP keep-alive",
    ),
    "disableUDP": MessageLookupByLibrary.simpleMessage("Disable UDP"),
    "disabled": MessageLookupByLibrary.simpleMessage("Disabled"),
    "discardChanges": MessageLookupByLibrary.simpleMessage(
      "Discard the changes?",
    ),
    "disclaimer": MessageLookupByLibrary.simpleMessage(
      "Terms of Use and Disclaimer",
    ),
    "disclaimerAcceptContent": MessageLookupByLibrary.simpleMessage(
      "By installing, copying, or using the Software, you confirm that you have read and agree to this statement in full. If you do not agree with any of its terms, stop using and uninstall the Software immediately.",
    ),
    "disclaimerAcceptTitle": MessageLookupByLibrary.simpleMessage("Acceptance"),
    "disclaimerAcknowledgeLabel": MessageLookupByLibrary.simpleMessage(
      "I have read and understood the statement above",
    ),
    "disclaimerAcknowledgeTip": MessageLookupByLibrary.simpleMessage(
      "To confirm your understanding, read the following statement and check the box below:",
    ),
    "disclaimerAcknowledgeTitle": MessageLookupByLibrary.simpleMessage(
      "Confirm Statement",
    ),
    "disclaimerChangesContent": MessageLookupByLibrary.simpleMessage(
      "The Group may revise this statement with new versions of the Software. Revisions take effect when the new version is released. Continuing to use the Software after an update constitutes acceptance of the revised statement.",
    ),
    "disclaimerChangesTitle": MessageLookupByLibrary.simpleMessage(
      "Changes to These Terms",
    ),
    "disclaimerCommitmentStatement": MessageLookupByLibrary.simpleMessage(
      "I agree to use the Software only for the Group\'s internal testing and learning, and to comply with applicable laws and regulations.",
    ),
    "disclaimerDesc": MessageLookupByLibrary.simpleMessage(
      "Thank you for choosing Panorama Secure Access (\"the Software\"). The Software is developed and maintained by Panorama Scholarly Group (\"the Group\"). Please read the following terms carefully before use. By tapping \"Agree\", you confirm that you have read, understood, and accepted this statement in full. If you do not agree, tap \"Exit\" and stop using the Software.",
    ),
    "disclaimerLiabilityContent": MessageLookupByLibrary.simpleMessage(
      "To the fullest extent permitted by applicable law, the Group and its developers and contributors accept no liability for any direct, indirect, incidental, special, punitive, or consequential damages arising from the use of, or inability to use, the Software, including but not limited to data loss, device damage, network outages, business interruption, or loss of profits, even if advised of the possibility of such damages.",
    ),
    "disclaimerLiabilityTitle": MessageLookupByLibrary.simpleMessage(
      "Limitation of Liability",
    ),
    "disclaimerLicenseContent": MessageLookupByLibrary.simpleMessage(
      "The Software is a modified version of FlClash, which is open source under GPL-3.0, and continues to be released under GPL-3.0. You may use, modify, and distribute the Software in accordance with that license, provided that you release your version under the same license and retain the copyright notices of the original authors and the Group.\n\nThird-party components included in the Software, including the Clash.Meta core, are governed by their own open-source licenses.",
    ),
    "disclaimerLicenseTitle": MessageLookupByLibrary.simpleMessage(
      "Open-Source License",
    ),
    "disclaimerNoServiceStatement": MessageLookupByLibrary.simpleMessage(
      "The Software does not provide any proxy server, node, subscription, or network access service, and the Group does not recommend or vouch for any such service.",
    ),
    "disclaimerPrivacyContent": MessageLookupByLibrary.simpleMessage(
      "The Software does not collect or upload your subscription URLs, node details, configuration content, browsing records, connection records, traffic content, or logs. This data is stored only on your device.\n\nThe Software only accesses the network when you use a feature that requires it, such as fetching the subscription URL you provided when updating a profile, or contacting GitHub when checking for updates.\n\nThe Software includes no analytics or crash reporting service on any platform.",
    ),
    "disclaimerPrivacyTitle": MessageLookupByLibrary.simpleMessage(
      "Data and Privacy",
    ),
    "disclaimerResponsibilityContent": MessageLookupByLibrary.simpleMessage(
      "Before use, you are responsible for confirming that your use of the Software complies with the laws and regulations of your country or region and with the policies of your organization. You bear sole responsibility for all of your actions with the Software and their consequences.\n\nThe subscriptions, nodes, and configurations you import are your own choice. You and the relevant providers are responsible for their lawful origin, the safety of their content, and the reliability of their service.",
    ),
    "disclaimerResponsibilityTitle": MessageLookupByLibrary.simpleMessage(
      "Your Responsibilities",
    ),
    "disclaimerRestateHint": MessageLookupByLibrary.simpleMessage(
      "Enter the statement above",
    ),
    "disclaimerRestateMismatch": MessageLookupByLibrary.simpleMessage(
      "The text does not match the statement",
    ),
    "disclaimerRestateTip": MessageLookupByLibrary.simpleMessage(
      "To confirm your understanding, enter the following statement in full in the field below:",
    ),
    "disclaimerRestateTitle": MessageLookupByLibrary.simpleMessage(
      "Confirm Statement",
    ),
    "disclaimerSoftwareContent": MessageLookupByLibrary.simpleMessage(
      "The Software is a network proxy client built on the open-source FlClash project and the Clash.Meta (mihomo) core. It only provides local tooling on your device, such as configuration management, rule-based routing, and traffic forwarding.",
    ),
    "disclaimerSoftwareTitle": MessageLookupByLibrary.simpleMessage(
      "About the Software",
    ),
    "disclaimerThirdPartyContent": MessageLookupByLibrary.simpleMessage(
      "Subscription links, configuration files, rule sets, scripts, and external resources are provided by third parties. The Group does not review them and makes no guarantee as to their legality, accuracy, security, or availability.\n\nAny data leak, financial loss, account restriction, or other loss caused by third-party content is to be resolved between you and the third party concerned.",
    ),
    "disclaimerThirdPartyTitle": MessageLookupByLibrary.simpleMessage(
      "Third-Party Content",
    ),
    "disclaimerUsageContent": MessageLookupByLibrary.simpleMessage(
      "The Software is provided to members of the Group for functional testing, technical research, and learning only. It is not offered as a commercial service and must not be distributed publicly.\n\nWithout the Group\'s written authorization, no one may use the Software for commercial purposes, including but not limited to paid distribution, bundled sales, or use as part of a commercial service.\n\nYou must not use the Software for any activity that violates the laws and regulations of your country or region, including but not limited to circumventing lawfully established network access controls, spreading illegal content, launching network attacks, or infringing the lawful rights of others.",
    ),
    "disclaimerUsageTitle": MessageLookupByLibrary.simpleMessage(
      "Scope of Use",
    ),
    "disclaimerWarrantyContent": MessageLookupByLibrary.simpleMessage(
      "The Software is provided \"as is\" and \"as available\", without warranty of any kind, express or implied, including but not limited to warranties of merchantability, fitness for a particular purpose, non-infringement, continuous availability, or freedom from errors or security vulnerabilities.\n\nThe Group does not guarantee that the Software will meet your specific needs or that it will run without interruption or error.",
    ),
    "disclaimerWarrantyTitle": MessageLookupByLibrary.simpleMessage(
      "No Warranty",
    ),
    "disconnected": MessageLookupByLibrary.simpleMessage("Disconnected"),
    "discoverNewVersion": MessageLookupByLibrary.simpleMessage(
      "New version found",
    ),
    "dnsCacheCleared": MessageLookupByLibrary.simpleMessage(
      "DNS cache cleared",
    ),
    "dnsHijackDesc": MessageLookupByLibrary.simpleMessage(
      "Without this entry, TUN hijacks every DNS query to port 53 (any:53).",
    ),
    "dnsHijacking": MessageLookupByLibrary.simpleMessage("DNS hijacking"),
    "dnsMode": MessageLookupByLibrary.simpleMessage("DNS mode"),
    "dnsOverrideDesc": MessageLookupByLibrary.simpleMessage(
      "Entries added here replace the DNS of every URL and file profile; anything not added keeps the profile\'s own setting. Custom profiles set their DNS in their content.",
    ),
    "dnsQueries": MessageLookupByLibrary.simpleMessage("DNS queries"),
    "docked": MessageLookupByLibrary.simpleMessage("Docked"),
    "domain": MessageLookupByLibrary.simpleMessage("Domain"),
    "done": MessageLookupByLibrary.simpleMessage("Done"),
    "download": MessageLookupByLibrary.simpleMessage("Download"),
    "downloadBandwidth": MessageLookupByLibrary.simpleMessage(
      "Download bandwidth",
    ),
    "downloadingUpdate": MessageLookupByLibrary.simpleMessage(
      "Downloading update",
    ),
    "duration": MessageLookupByLibrary.simpleMessage("Duration"),
    "edit": MessageLookupByLibrary.simpleMessage("Edit"),
    "editDashboard": MessageLookupByLibrary.simpleMessage("Edit dashboard"),
    "editGlobalRules": MessageLookupByLibrary.simpleMessage(
      "Edit global rules",
    ),
    "editProxy": MessageLookupByLibrary.simpleMessage("Edit proxy"),
    "editProxyGroup": MessageLookupByLibrary.simpleMessage("Edit proxy group"),
    "editRule": MessageLookupByLibrary.simpleMessage("Edit rule"),
    "editSsid": MessageLookupByLibrary.simpleMessage("Edit SSID"),
    "editorUnavailable": MessageLookupByLibrary.simpleMessage(
      "Editor unavailable",
    ),
    "elapsed": MessageLookupByLibrary.simpleMessage("Took"),
    "emptyFallback": MessageLookupByLibrary.simpleMessage("Empty fallback"),
    "emptyTip": m27,
    "en": MessageLookupByLibrary.simpleMessage("English"),
    "enabled": MessageLookupByLibrary.simpleMessage("Enabled"),
    "entries": MessageLookupByLibrary.simpleMessage(" entries"),
    "error": MessageLookupByLibrary.simpleMessage("Error"),
    "errorDetails": MessageLookupByLibrary.simpleMessage("Error details"),
    "es": MessageLookupByLibrary.simpleMessage("Spanish"),
    "exclude": MessageLookupByLibrary.simpleMessage("Hide from recent tasks"),
    "excludeDstPort": MessageLookupByLibrary.simpleMessage(
      "Excluded destination ports",
    ),
    "excludeFilter": MessageLookupByLibrary.simpleMessage("Exclude filter"),
    "excludeInterface": MessageLookupByLibrary.simpleMessage(
      "Excluded interfaces",
    ),
    "excludeSrcPort": MessageLookupByLibrary.simpleMessage(
      "Excluded source ports",
    ),
    "excludeSsids": MessageLookupByLibrary.simpleMessage("Exclude SSIDs"),
    "excludeSsidsDesc": MessageLookupByLibrary.simpleMessage(
      "When connected to Wi-Fi with an excluded SSID, the app\'s running state switches automatically.",
    ),
    "excludeUid": MessageLookupByLibrary.simpleMessage("Excluded user IDs"),
    "existsTip": m28,
    "exit": MessageLookupByLibrary.simpleMessage("Exit"),
    "exitFullScreen": MessageLookupByLibrary.simpleMessage("Exit full screen"),
    "exitNodes": MessageLookupByLibrary.simpleMessage("Exit nodes"),
    "expectedStatus": MessageLookupByLibrary.simpleMessage("Expected status"),
    "expireTime": MessageLookupByLibrary.simpleMessage("Expiration time"),
    "exportCertificate": MessageLookupByLibrary.simpleMessage(
      "Export certificate",
    ),
    "exportFile": MessageLookupByLibrary.simpleMessage("Export file"),
    "exportHar": MessageLookupByLibrary.simpleMessage("Export HAR"),
    "exportLogs": MessageLookupByLibrary.simpleMessage("Export logs"),
    "exportSuccess": MessageLookupByLibrary.simpleMessage("Export successful"),
    "extend": MessageLookupByLibrary.simpleMessage("Extend"),
    "extendMode": MessageLookupByLibrary.simpleMessage("Extend mode"),
    "extendScript": MessageLookupByLibrary.simpleMessage("Extend script"),
    "externalController": MessageLookupByLibrary.simpleMessage(
      "External controller",
    ),
    "externalControllerDesc": MessageLookupByLibrary.simpleMessage(
      "The external controller lets you control the core on port 9090.",
    ),
    "externalControllerSecret": MessageLookupByLibrary.simpleMessage(
      "External controller secret",
    ),
    "externalLink": MessageLookupByLibrary.simpleMessage("External link"),
    "extraLarge": MessageLookupByLibrary.simpleMessage("Extra large"),
    "fade": MessageLookupByLibrary.simpleMessage("Fade"),
    "failedCount": m29,
    "failedItem": m30,
    "fakeipFilter": MessageLookupByLibrary.simpleMessage("Fake-IP filter"),
    "fakeipFilterDesc": MessageLookupByLibrary.simpleMessage(
      "These domains get real IPs instead of Fake-IPs. In whitelist mode, only they get Fake-IPs.",
    ),
    "fakeipFilterMode": MessageLookupByLibrary.simpleMessage(
      "Fake-IP filter mode",
    ),
    "fakeipRange": MessageLookupByLibrary.simpleMessage("Fake-IP range"),
    "fakeipRange6": MessageLookupByLibrary.simpleMessage(
      "Fake-IP range (IPv6)",
    ),
    "fakeipTtl": MessageLookupByLibrary.simpleMessage("Fake-IP TTL"),
    "fallbackDesc": MessageLookupByLibrary.simpleMessage(
      "Used instead of Nameserver when the fallback filter treats its answer as polluted.",
    ),
    "fallbackFilter": MessageLookupByLibrary.simpleMessage("Fallback filter"),
    "fallbackFilterDomainDesc": MessageLookupByLibrary.simpleMessage(
      "These domains are resolved by Fallback directly.",
    ),
    "fallbackFilterGeositeDesc": MessageLookupByLibrary.simpleMessage(
      "Domains in these GeoSite categories are resolved by Fallback directly.",
    ),
    "fallbackFilterIpcidrDesc": MessageLookupByLibrary.simpleMessage(
      "When Nameserver returns an IP in these ranges, the Fallback answer is used.",
    ),
    "file": MessageLookupByLibrary.simpleMessage("File"),
    "fileIsUpdate": MessageLookupByLibrary.simpleMessage(
      "The file has been modified. Save the changes?",
    ),
    "filter": MessageLookupByLibrary.simpleMessage("Filter"),
    "filters": MessageLookupByLibrary.simpleMessage("Filters"),
    "findProcessMode": MessageLookupByLibrary.simpleMessage("Find process"),
    "floating": MessageLookupByLibrary.simpleMessage("Floating"),
    "followProfile": MessageLookupByLibrary.simpleMessage("Follow profile"),
    "followSystem": MessageLookupByLibrary.simpleMessage("Follow system"),
    "fontFamily": MessageLookupByLibrary.simpleMessage("Font family"),
    "fontSize": MessageLookupByLibrary.simpleMessage("Size"),
    "forceDnsMapping": MessageLookupByLibrary.simpleMessage(
      "Force DNS mapping",
    ),
    "forceDnsMappingDesc": MessageLookupByLibrary.simpleMessage(
      "Force DNS mapping also sniffs connections whose domain came from a DNS mapping.",
    ),
    "forceDomain": MessageLookupByLibrary.simpleMessage("Force domains"),
    "forceDomainDesc": MessageLookupByLibrary.simpleMessage(
      "Force domains are sniffed too; other connections that already have a domain are left alone.",
    ),
    "forceRestartCoreTip": MessageLookupByLibrary.simpleMessage(
      "Are you sure you want to force restart the core?",
    ),
    "fr": MessageLookupByLibrary.simpleMessage("French"),
    "general": MessageLookupByLibrary.simpleMessage("General"),
    "generalOverrideDesc": MessageLookupByLibrary.simpleMessage(
      "Entries added here replace the setting of every profile; anything not added keeps the profile\'s own setting, or the core default when the profile has none.",
    ),
    "generateCertificate": MessageLookupByLibrary.simpleMessage(
      "Generate certificate",
    ),
    "geoResources": MessageLookupByLibrary.simpleMessage("Geo"),
    "geoSkipped": m31,
    "geoUpdated": m32,
    "geodataLoader": MessageLookupByLibrary.simpleMessage(
      "Geo low-memory mode",
    ),
    "global": MessageLookupByLibrary.simpleMessage("Global"),
    "globalDirectTip": MessageLookupByLibrary.simpleMessage(
      "GLOBAL is set to DIRECT, so global mode sends traffic direct",
    ),
    "go": MessageLookupByLibrary.simpleMessage("Go"),
    "goDownload": MessageLookupByLibrary.simpleMessage("Download"),
    "goToConfigureAddedRules": MessageLookupByLibrary.simpleMessage(
      "Go to added rules configuration",
    ),
    "goToConfigureScript": MessageLookupByLibrary.simpleMessage(
      "Go to script configuration",
    ),
    "grid": MessageLookupByLibrary.simpleMessage("Grid"),
    "groupBy": MessageLookupByLibrary.simpleMessage("Group by"),
    "groupCount": m33,
    "groupCountUnit": MessageLookupByLibrary.simpleMessage("groups"),
    "groupEmptyFallbackTip": m34,
    "groupTimeoutCount": m35,
    "hasCacheChange": MessageLookupByLibrary.simpleMessage(
      "Cache the changes?",
    ),
    "hashByInUser": MessageLookupByLibrary.simpleMessage(
      "Hash by inbound user",
    ),
    "headerRewrite": MessageLookupByLibrary.simpleMessage("Header rewrite"),
    "healthCheck": MessageLookupByLibrary.simpleMessage("Health check"),
    "helperCorruptTip": MessageLookupByLibrary.simpleMessage(
      "Helper service unavailable; TUN mode cannot be enabled. Reinstall Panorama Secure Access to restore it.",
    ),
    "hex": MessageLookupByLibrary.simpleMessage("Hex"),
    "hideFromList": MessageLookupByLibrary.simpleMessage("Hide from list"),
    "hideIp": MessageLookupByLibrary.simpleMessage("Hide IP"),
    "hidePassword": MessageLookupByLibrary.simpleMessage("Hide password"),
    "hideTimeoutProxies": MessageLookupByLibrary.simpleMessage(
      "Hide timed-out proxies",
    ),
    "hopInterval": MessageLookupByLibrary.simpleMessage("Hop interval"),
    "host": MessageLookupByLibrary.simpleMessage("Host"),
    "hostname": MessageLookupByLibrary.simpleMessage("Hostname"),
    "hotkeyConflictWith": m36,
    "hotkeyDesc": MessageLookupByLibrary.simpleMessage(
      "Global hotkeys work even while the window is hidden. Tap an action to record its key combination.",
    ),
    "hotkeyManagement": MessageLookupByLibrary.simpleMessage(
      "Hotkey management",
    ),
    "hotkeyNeedsModifier": m37,
    "hotkeyNotSet": MessageLookupByLibrary.simpleMessage("Not set"),
    "hotkeyUnavailable": MessageLookupByLibrary.simpleMessage(
      "Not registered, it may be taken by another app",
    ),
    "hours": MessageLookupByLibrary.simpleMessage("hours"),
    "hoursAgo": m38,
    "hoursAgoShort": m39,
    "http2": MessageLookupByLibrary.simpleMessage("HTTP/2"),
    "httpBodyNotKept": MessageLookupByLibrary.simpleMessage(
      "Not recorded while memory was short.",
    ),
    "httpBodyProtobufGuess": MessageLookupByLibrary.simpleMessage(
      "Read as Protobuf without its schema: field numbers only, and the types are guesses.",
    ),
    "httpBodyTruncated": MessageLookupByLibrary.simpleMessage(
      "Only the start of this body was recorded.",
    ),
    "httpBodyUndecoded": m40,
    "httpCapture": MessageLookupByLibrary.simpleMessage("HTTP capture"),
    "httpCaptureDesc": MessageLookupByLibrary.simpleMessage(
      "Records requests to the hosts listed under Hostname, to view in connection details. Records stay in memory only.",
    ),
    "httpCaptureLimit": MessageLookupByLibrary.simpleMessage("Maximum records"),
    "httpCaptureLimitDesc": m41,
    "httpCaptureNoHosts": MessageLookupByLibrary.simpleMessage(
      "No host is listed, so nothing is recorded. Add hosts under Hostname on the MITM page, or from the details of a connection.",
    ),
    "httpCaptureOff": MessageLookupByLibrary.simpleMessage("Capture is off"),
    "httpExportPrivate": MessageLookupByLibrary.simpleMessage(
      "A request can carry cookies, tokens, passwords and form contents. Check what you share, and with whom.",
    ),
    "httpExportPrivateTitle": MessageLookupByLibrary.simpleMessage(
      "Contains private data",
    ),
    "httpRequestCleared": MessageLookupByLibrary.simpleMessage(
      "This request is no longer kept",
    ),
    "httpRequests": MessageLookupByLibrary.simpleMessage("HTTP requests"),
    "httpRequestsMissing": MessageLookupByLibrary.simpleMessage(
      "Requests made before capture was on, or since cleared, are not listed.",
    ),
    "httpsDecryption": MessageLookupByLibrary.simpleMessage("HTTPS decryption"),
    "hue": MessageLookupByLibrary.simpleMessage("Hue"),
    "icon": MessageLookupByLibrary.simpleMessage("Icon"),
    "iconRecords": MessageLookupByLibrary.simpleMessage("Icon records"),
    "iconSets": MessageLookupByLibrary.simpleMessage("Icon sets"),
    "iconSetsEmptyTip": MessageLookupByLibrary.simpleMessage(
      "No icon sets yet. Add them in Custom profile resources → Icon sets",
    ),
    "iconStyle": MessageLookupByLibrary.simpleMessage("Icon style"),
    "iconStyleFilled": MessageLookupByLibrary.simpleMessage("Filled"),
    "iconStyleHidden": MessageLookupByLibrary.simpleMessage("Hidden"),
    "iconStylePlain": MessageLookupByLibrary.simpleMessage("Plain"),
    "iconUrl": MessageLookupByLibrary.simpleMessage("Icon URL"),
    "ignoreBatteryOptimization": MessageLookupByLibrary.simpleMessage(
      "Ignore battery optimization",
    ),
    "import": MessageLookupByLibrary.simpleMessage("Import"),
    "importConfigInvalid": MessageLookupByLibrary.simpleMessage(
      "This file is not a config that can be imported",
    ),
    "importConfigReplaceTip": MessageLookupByLibrary.simpleMessage(
      "Importing replaces the proxy groups, rules and settings this profile has now",
    ),
    "importFile": MessageLookupByLibrary.simpleMessage("Import from file"),
    "importFromLink": MessageLookupByLibrary.simpleMessage("Import from link"),
    "importUrl": MessageLookupByLibrary.simpleMessage("Import from URL"),
    "inProgress": MessageLookupByLibrary.simpleMessage("In progress"),
    "inbound": MessageLookupByLibrary.simpleMessage("Inbound"),
    "includeInterface": MessageLookupByLibrary.simpleMessage(
      "Included interfaces",
    ),
    "includeInterfaceDesc": MessageLookupByLibrary.simpleMessage(
      "Only traffic arriving on included interfaces goes through TUN, and excluded interfaces no longer apply.",
    ),
    "includeUid": MessageLookupByLibrary.simpleMessage("Included user IDs"),
    "infiniteTime": MessageLookupByLibrary.simpleMessage("Never expires"),
    "init": MessageLookupByLibrary.simpleMessage("Init"),
    "initFailed": MessageLookupByLibrary.simpleMessage("Startup failed"),
    "initFailedTip": MessageLookupByLibrary.simpleMessage(
      "Panorama Secure Access ran into an error while starting and can\'t continue. Copy the details to report the problem. If it keeps happening, clearing the data usually lets the app start again.",
    ),
    "initiator": MessageLookupByLibrary.simpleMessage("Initiator"),
    "initiatorShort": MessageLookupByLibrary.simpleMessage("From"),
    "inputProxyGroupName": MessageLookupByLibrary.simpleMessage(
      "Enter the proxy group name",
    ),
    "inputRuleContent": MessageLookupByLibrary.simpleMessage(
      "Enter the rule content",
    ),
    "installCertificate": MessageLookupByLibrary.simpleMessage(
      "Install to system",
    ),
    "installCertificateSuccess": MessageLookupByLibrary.simpleMessage(
      "Certificate installed",
    ),
    "installNow": MessageLookupByLibrary.simpleMessage("Install now"),
    "installedAppsPermissionDeniedMessage": MessageLookupByLibrary.simpleMessage(
      "The app list permission was denied, so installed apps cannot be listed. Please grant it manually in system settings.",
    ),
    "installedAppsPermissionDesc": MessageLookupByLibrary.simpleMessage(
      "This system hides the installed app list until the permission is granted. Authorize it to configure the per-app proxy.",
    ),
    "installedAppsPermissionRequired": MessageLookupByLibrary.simpleMessage(
      "App list permission required",
    ),
    "installedFonts": MessageLookupByLibrary.simpleMessage("Installed fonts"),
    "installedVersion": MessageLookupByLibrary.simpleMessage(
      "Installed version",
    ),
    "intelligentSelected": MessageLookupByLibrary.simpleMessage(
      "Smart selection",
    ),
    "interfaceName": MessageLookupByLibrary.simpleMessage("Interface name"),
    "interfaceNameMode": MessageLookupByLibrary.simpleMessage(
      "Outbound interface",
    ),
    "interfaceNameModeClear": MessageLookupByLibrary.simpleMessage("Clear"),
    "interfaceNameModeCustom": MessageLookupByLibrary.simpleMessage("Custom"),
    "interfaceNameModeFollow": MessageLookupByLibrary.simpleMessage(
      "Follow config",
    ),
    "internet": MessageLookupByLibrary.simpleMessage("Internet"),
    "interval": MessageLookupByLibrary.simpleMessage("Interval"),
    "intranetIP": MessageLookupByLibrary.simpleMessage("Intranet IP"),
    "invalidBackupFile": MessageLookupByLibrary.simpleMessage(
      "Invalid backup file",
    ),
    "invalidCharactersTip": m42,
    "invalidCidrContent": MessageLookupByLibrary.simpleMessage(
      "Enter an IP range in CIDR form such as 192.168.0.0/16",
    ),
    "invalidDscpContent": MessageLookupByLibrary.simpleMessage(
      "A DSCP mark cannot exceed 63",
    ),
    "invalidHostContent": MessageLookupByLibrary.simpleMessage(
      "Enter a domain or an IP address",
    ),
    "invalidIconSet": MessageLookupByLibrary.simpleMessage(
      "Not a valid icon set",
    ),
    "invalidLinkTip": MessageLookupByLibrary.simpleMessage(
      "Not a subscription link or a proxy share link",
    ),
    "invalidListenContent": MessageLookupByLibrary.simpleMessage(
      "Enter an address and port such as 0.0.0.0:1053",
    ),
    "invalidNetworkContent": MessageLookupByLibrary.simpleMessage(
      "Only tcp or udp is supported",
    ),
    "invalidOfCount": m43,
    "invalidPolicy": m44,
    "invalidPortRangeContent": MessageLookupByLibrary.simpleMessage(
      "Enter a port or a range such as 443 or 8000-9000",
    ),
    "invalidProfileQrcode": MessageLookupByLibrary.simpleMessage(
      "This QR code doesn\'t contain a profile link",
    ),
    "invalidProxy": m45,
    "invalidProxyProvider": m46,
    "invalidRangeContent": MessageLookupByLibrary.simpleMessage(
      "Enter numbers or ranges such as 80 or 8000-9000, separated by /",
    ),
    "invalidRuleSet": m47,
    "invalidSubRule": m48,
    "ipAddress": MessageLookupByLibrary.simpleMessage("IP address"),
    "ipAsn": MessageLookupByLibrary.simpleMessage("ASN"),
    "ipFlagAbuser": MessageLookupByLibrary.simpleMessage("Abuse history"),
    "ipFlagProxy": MessageLookupByLibrary.simpleMessage("Proxy"),
    "ipFlagTor": MessageLookupByLibrary.simpleMessage("Tor"),
    "ipFlagVpn": MessageLookupByLibrary.simpleMessage("VPN"),
    "ipFlags": MessageLookupByLibrary.simpleMessage("Flags"),
    "ipOrganization": MessageLookupByLibrary.simpleMessage("Organization"),
    "ipQualityFailed": MessageLookupByLibrary.simpleMessage(
      "Couldn\'t determine the IP type",
    ),
    "ipQualityGood": MessageLookupByLibrary.simpleMessage("Good"),
    "ipQualityLevel": MessageLookupByLibrary.simpleMessage("Level"),
    "ipQualityNormal": MessageLookupByLibrary.simpleMessage("Normal"),
    "ipQualityRetry": MessageLookupByLibrary.simpleMessage("Check again"),
    "ipQualityRisky": MessageLookupByLibrary.simpleMessage("Risky"),
    "ipQualityShort": MessageLookupByLibrary.simpleMessage("Quality"),
    "ipQualitySource": MessageLookupByLibrary.simpleMessage("Answered by"),
    "ipQualitySources": MessageLookupByLibrary.simpleMessage("Sources"),
    "ipSourceIpMismatch": MessageLookupByLibrary.simpleMessage(
      "Different outbound IP",
    ),
    "ipSourceNoType": MessageLookupByLibrary.simpleMessage("No type"),
    "ipSourceRateLimited": MessageLookupByLibrary.simpleMessage("Rate limited"),
    "ipType": MessageLookupByLibrary.simpleMessage("Type"),
    "ipTypeBusiness": MessageLookupByLibrary.simpleMessage("Business"),
    "ipTypeHosting": MessageLookupByLibrary.simpleMessage("Data center"),
    "ipTypeMobile": MessageLookupByLibrary.simpleMessage("Mobile network"),
    "ipTypeResidential": MessageLookupByLibrary.simpleMessage("Residential"),
    "ipTypeUnknown": MessageLookupByLibrary.simpleMessage("Unknown type"),
    "ipVersion": MessageLookupByLibrary.simpleMessage("IP version"),
    "ipv6Desc": MessageLookupByLibrary.simpleMessage(
      "IPv6 traffic is received only while IPv6 is on.",
    ),
    "ipv6Timeout": MessageLookupByLibrary.simpleMessage("IPv6 timeout (ms)"),
    "itemsCount": m49,
    "ja": MessageLookupByLibrary.simpleMessage("Japanese"),
    "justNow": MessageLookupByLibrary.simpleMessage("Just now"),
    "keep": MessageLookupByLibrary.simpleMessage("Keep"),
    "keepAliveIdle": MessageLookupByLibrary.simpleMessage(
      "TCP keep-alive idle",
    ),
    "keepAliveIntervalDesc": MessageLookupByLibrary.simpleMessage(
      "TCP keep-alive interval",
    ),
    "key": MessageLookupByLibrary.simpleMessage("Key"),
    "ko": MessageLookupByLibrary.simpleMessage("Korean"),
    "label": MessageLookupByLibrary.simpleMessage("Label"),
    "language": MessageLookupByLibrary.simpleMessage("Language"),
    "large": MessageLookupByLibrary.simpleMessage("Large"),
    "lastUpdated": MessageLookupByLibrary.simpleMessage("Last updated"),
    "launchInterrupted": MessageLookupByLibrary.simpleMessage(
      "Launch did not finish",
    ),
    "launchInterruptedTip": MessageLookupByLibrary.simpleMessage(
      "The app exited unexpectedly while it was starting up last time. Automatic setup was skipped for this launch; you can start it manually to retry.",
    ),
    "layout": MessageLookupByLibrary.simpleMessage("Layout"),
    "legacyAndroidImportAction": MessageLookupByLibrary.simpleMessage(
      "Restore now",
    ),
    "legacyAndroidImportTip": m50,
    "legacyAndroidImportTitle": MessageLookupByLibrary.simpleMessage(
      "Import from the previous version",
    ),
    "legacyDataImported": m51,
    "legacyInstallRemove": MessageLookupByLibrary.simpleMessage("Remove"),
    "legacyInstallRemoveFailed": MessageLookupByLibrary.simpleMessage(
      "The previous version could not be removed. Uninstall it with your package manager or move it to the Trash.",
    ),
    "legacyInstallTip": m52,
    "legacyInstallTitle": MessageLookupByLibrary.simpleMessage(
      "Previous version still installed",
    ),
    "light": MessageLookupByLibrary.simpleMessage("Light"),
    "lineIssueTip": m53,
    "lineWrap": MessageLookupByLibrary.simpleMessage("Word wrap"),
    "link": MessageLookupByLibrary.simpleMessage("Link"),
    "linuxHelperSetupFailed": MessageLookupByLibrary.simpleMessage(
      "The TUN service was not installed. Turning on TUN will ask again.",
    ),
    "linuxHelperSetupTip": MessageLookupByLibrary.simpleMessage(
      "TUN mode runs through a system service. Authorize it once as an administrator: after that, starting Panorama Secure Access, turning on TUN and restarting the computer no longer ask for a password. The app itself keeps running under your account.",
    ),
    "linuxHelperSetupTitle": MessageLookupByLibrary.simpleMessage(
      "Set up the TUN service",
    ),
    "liquidGlass": MessageLookupByLibrary.simpleMessage("Liquid Glass"),
    "list": MessageLookupByLibrary.simpleMessage("List"),
    "listen": MessageLookupByLibrary.simpleMessage("Listen"),
    "listenRoutingMark": MessageLookupByLibrary.simpleMessage(
      "Listen routing mark",
    ),
    "listenRoutingMarkDesc": MessageLookupByLibrary.simpleMessage(
      "Listen routing mark works only on Linux.",
    ),
    "liveConnections": MessageLookupByLibrary.simpleMessage("Live connections"),
    "loading": MessageLookupByLibrary.simpleMessage("Loading…"),
    "local": MessageLookupByLibrary.simpleMessage("Local"),
    "localImage": MessageLookupByLibrary.simpleMessage("Local image"),
    "localNetworkDeniedTip": MessageLookupByLibrary.simpleMessage(
      "Local network permission denied: using the gvisor stack, LAN is unreachable.",
    ),
    "localProxies": MessageLookupByLibrary.simpleMessage("Local proxies"),
    "locationPermission": MessageLookupByLibrary.simpleMessage(
      "Location permission",
    ),
    "locationPermissionDeniedMessage": MessageLookupByLibrary.simpleMessage(
      "Location permission was denied, so the current Wi-Fi name cannot be read. Please enable location permission manually in system settings.",
    ),
    "locationPermissionDesc": MessageLookupByLibrary.simpleMessage(
      "The system requires location permission to read the Wi-Fi name. On Android choose \"Allow all the time\", otherwise the Wi-Fi name cannot be read while the app is in the background.",
    ),
    "locationPermissionGuide": m54,
    "locationPermissionRequired": MessageLookupByLibrary.simpleMessage(
      "Location permission required",
    ),
    "log": MessageLookupByLibrary.simpleMessage("Log"),
    "logLevel": MessageLookupByLibrary.simpleMessage("Log level"),
    "logcat": MessageLookupByLibrary.simpleMessage("Logcat"),
    "logcatDesc": MessageLookupByLibrary.simpleMessage(
      "Turning off Logcat hides the logs entry.",
    ),
    "logs": MessageLookupByLibrary.simpleMessage("Logs"),
    "logsAndDiagnostics": MessageLookupByLibrary.simpleMessage(
      "Logs and diagnostics",
    ),
    "logsTest": MessageLookupByLibrary.simpleMessage("Logs test"),
    "loopback": MessageLookupByLibrary.simpleMessage("UWP loopback exemption"),
    "loose": MessageLookupByLibrary.simpleMessage("Loose"),
    "mapLocal": MessageLookupByLibrary.simpleMessage("Map local"),
    "matchCase": MessageLookupByLibrary.simpleMessage("Match case"),
    "matchSourceIp": MessageLookupByLibrary.simpleMessage("Match source IP"),
    "matchTarget": MessageLookupByLibrary.simpleMessage("MATCH-TARGET"),
    "matchedRules": MessageLookupByLibrary.simpleMessage("Matched rules"),
    "maxFailedTimes": MessageLookupByLibrary.simpleMessage("Max failures"),
    "maxLengthTip": m55,
    "maximize": MessageLookupByLibrary.simpleMessage("Maximize"),
    "memoryAppResident": MessageLookupByLibrary.simpleMessage(
      "Resident memory",
    ),
    "memoryAppShared": MessageLookupByLibrary.simpleMessage("App & shared"),
    "memoryCoreHeapIdle": MessageLookupByLibrary.simpleMessage("Heap idle"),
    "memoryCoreHeapInuse": MessageLookupByLibrary.simpleMessage("Heap in use"),
    "memoryCoreNotRunning": MessageLookupByLibrary.simpleMessage(
      "Core is not running",
    ),
    "memoryCoreRuntime": MessageLookupByLibrary.simpleMessage(
      "Runtime overhead",
    ),
    "memoryCoreStack": MessageLookupByLibrary.simpleMessage("Goroutine stacks"),
    "memoryEstimateDesc": MessageLookupByLibrary.simpleMessage(
      "Estimated from process resident memory; it may differ from what the system reports.",
    ),
    "memoryEstimateSharedDesc": MessageLookupByLibrary.simpleMessage(
      "The Core runs inside the app process. Its share is estimated from runtime stats, and the rest counts as app and shared memory.",
    ),
    "memoryInfo": MessageLookupByLibrary.simpleMessage("Memory info"),
    "memoryInfoDesc": MessageLookupByLibrary.simpleMessage(
      "Memory the app and the core use",
    ),
    "memoryReleased": MessageLookupByLibrary.simpleMessage("Memory released"),
    "memoryReleasedSize": m56,
    "messageTest": MessageLookupByLibrary.simpleMessage("Message test"),
    "messageTestTip": MessageLookupByLibrary.simpleMessage(
      "This is a message.",
    ),
    "method": MessageLookupByLibrary.simpleMessage("Method"),
    "minimize": MessageLookupByLibrary.simpleMessage("Minimize"),
    "minimizeOnExit": MessageLookupByLibrary.simpleMessage("Minimize on exit"),
    "minutes": MessageLookupByLibrary.simpleMessage("minutes"),
    "minutesAgo": m57,
    "minutesAgoShort": m58,
    "mitm": MessageLookupByLibrary.simpleMessage("MITM"),
    "mitmAddLocalFile": MessageLookupByLibrary.simpleMessage(
      "Add a local file",
    ),
    "mitmAddMapLocalRule": MessageLookupByLibrary.simpleMessage(
      "Add a map local rule",
    ),
    "mitmAddRejectRule": MessageLookupByLibrary.simpleMessage(
      "Add a reject rule",
    ),
    "mitmAttachments": MessageLookupByLibrary.simpleMessage("Attachments"),
    "mitmAttachmentsDesc": MessageLookupByLibrary.simpleMessage(
      "Lines refer to attachments by file name, as in script-path=a.js.",
    ),
    "mitmCertificateAndroidReadyTip": MessageLookupByLibrary.simpleMessage(
      "Only apps that trust user certificates, mostly browsers, are decrypted.",
    ),
    "mitmCertificateExportTip": MessageLookupByLibrary.simpleMessage(
      "Export it and trust it on the devices you want to decrypt.",
    ),
    "mitmCertificateLinuxTip": MessageLookupByLibrary.simpleMessage(
      "Flatpak browsers need the exported certificate imported by hand.",
    ),
    "mitmCertificateSavedTip": m59,
    "mitmCertutilMissing": m60,
    "mitmClientRefusedCertificate": MessageLookupByLibrary.simpleMessage(
      "The client refused the certificate. Install the CA, or exclude this host if the app pins its certificate.",
    ),
    "mitmDecryptHost": MessageLookupByLibrary.simpleMessage(
      "Decrypt this host",
    ),
    "mitmDecryptHostTip": m61,
    "mitmEnableTip": MessageLookupByLibrary.simpleMessage(
      "Panorama Secure Access will be able to read everything sent to the decrypted hosts, cookies and passwords included. Turn this on only for hosts you mean to rewrite.",
    ),
    "mitmExcludeHost": MessageLookupByLibrary.simpleMessage(
      "Exclude from decryption",
    ),
    "mitmExcludeHostTip": m62,
    "mitmFileTooLarge": m63,
    "mitmHostnameDesc": MessageLookupByLibrary.simpleMessage(
      "A leading - excludes a host, and the first match decides.",
    ),
    "mitmIgnoredLines": MessageLookupByLibrary.simpleMessage("Ignored lines"),
    "mitmInstallSystemCaTip": MessageLookupByLibrary.simpleMessage(
      "Root was found, so the certificate goes into the system\'s trusted certificates as a Panorama Secure Access MITM CA module for Magisk, KernelSU or APatch. Every app on this device will then trust it, and anyone holding its private key could decrypt this device\'s HTTPS traffic. To undo it, regenerate the certificate or remove the module in the root manager and restart. If root is denied, it is installed as a user certificate instead.",
    ),
    "mitmInstallUserCaTip": MessageLookupByLibrary.simpleMessage(
      "No root was found, so the certificate can only be installed as a user certificate. Only apps that trust user certificates, mostly browsers, are decrypted; other apps fail on the hosts you list, so leave those hosts out. On Android 11 and later you finish the install yourself in system settings.",
    ),
    "mitmMissingStores": m64,
    "mitmModule": MessageLookupByLibrary.simpleMessage("Module"),
    "mitmModuleInvalid": MessageLookupByLibrary.simpleMessage(
      "This is not a Surge module, a Loon plugin, a Quantumult X snippet or a Stash override",
    ),
    "mitmModuleRulesDesc": MessageLookupByLibrary.simpleMessage(
      "Routing rules go in front of the profile’s own.",
    ),
    "mitmModuleScriptsChanged": m65,
    "mitmModuleSystemTip": m66,
    "mitmModules": MessageLookupByLibrary.simpleMessage("Modules"),
    "mitmNewModule": MessageLookupByLibrary.simpleMessage("New module"),
    "mitmOldCertificateLeftTip": m67,
    "mitmOldSystemCertificateLeftTip": m68,
    "mitmRemoveOldCertificateTip": m69,
    "mitmRootPendingReboot": MessageLookupByLibrary.simpleMessage(
      "The certificate takes effect after the device restarts.",
    ),
    "mitmRootUntilReboot": MessageLookupByLibrary.simpleMessage(
      "No Magisk, KernelSU or APatch was found to keep the certificate. Install it again after the device restarts.",
    ),
    "mitmRoutingRules": MessageLookupByLibrary.simpleMessage("Routing rules"),
    "mitmRuleCopiedForStash": MessageLookupByLibrary.simpleMessage(
      "This module is a Stash override, so the rule was copied for you to add by hand.",
    ),
    "mitmRunScript": MessageLookupByLibrary.simpleMessage("Run now"),
    "mitmScriptNoOutput": MessageLookupByLibrary.simpleMessage(
      "The script finished without output",
    ),
    "mitmScriptRisk": MessageLookupByLibrary.simpleMessage(
      "Its scripts read and change the traffic of the hosts they match, cookies and tokens included, and can send requests of their own. Turn it on only if you trust where it comes from.",
    ),
    "mitmScriptRiskTitle": MessageLookupByLibrary.simpleMessage(
      "Run this module\'s scripts?",
    ),
    "mitmSkipConditional": MessageLookupByLibrary.simpleMessage(
      "Conditional rewrites are not supported",
    ),
    "mitmSkipDisabled": MessageLookupByLibrary.simpleMessage(
      "Turned off by an argument",
    ),
    "mitmSkipEvent": MessageLookupByLibrary.simpleMessage(
      "This event is not supported",
    ),
    "mitmSkipJq": MessageLookupByLibrary.simpleMessage(
      "jq rewrites are not supported",
    ),
    "mitmSkipJsonBody": MessageLookupByLibrary.simpleMessage(
      "JSON body rewrites are not supported",
    ),
    "mitmSkipNotDownloaded": MessageLookupByLibrary.simpleMessage(
      "Its file has not been downloaded",
    ),
    "mitmSkipPolicy": MessageLookupByLibrary.simpleMessage(
      "Only the DIRECT and REJECT policies are supported",
    ),
    "mitmSkipRawHeader": MessageLookupByLibrary.simpleMessage(
      "Rewriting all headers as one text is not supported",
    ),
    "mitmSkipRelativeData": MessageLookupByLibrary.simpleMessage(
      "The file this line names is not attached; use a URL or attach it",
    ),
    "mitmSkipRule": MessageLookupByLibrary.simpleMessage(
      "This rule type is not supported",
    ),
    "mitmSkipScriptType": MessageLookupByLibrary.simpleMessage(
      "This script type is not supported",
    ),
    "mitmSkipSection": m70,
    "mitmSkipSetting": MessageLookupByLibrary.simpleMessage(
      "This setting is not supported",
    ),
    "mitmSkipUnreadable": MessageLookupByLibrary.simpleMessage(
      "This line cannot be read",
    ),
    "mitmSystemStoreFailed": MessageLookupByLibrary.simpleMessage(
      "Adding the certificate to the system\'s trusted roots failed",
    ),
    "mitmTrustChecking": MessageLookupByLibrary.simpleMessage("Checking…"),
    "mitmTrustNotInstalled": MessageLookupByLibrary.simpleMessage(
      "Not installed",
    ),
    "mitmTrustReady": MessageLookupByLibrary.simpleMessage("Trusted"),
    "mitmTrustUntrusted": MessageLookupByLibrary.simpleMessage(
      "Not fully trusted",
    ),
    "mixedPort": MessageLookupByLibrary.simpleMessage("Mixed port"),
    "mode": MessageLookupByLibrary.simpleMessage("Mode"),
    "monochromeIcon": MessageLookupByLibrary.simpleMessage("Monochrome icon"),
    "monochromeScheme": MessageLookupByLibrary.simpleMessage("Monochrome"),
    "monthsAgo": m71,
    "monthsAgoShort": m72,
    "more": MessageLookupByLibrary.simpleMessage("More"),
    "name": MessageLookupByLibrary.simpleMessage("Name"),
    "nameserverDesc": MessageLookupByLibrary.simpleMessage(
      "The default DNS servers, such as 223.5.5.5, tls://1.1.1.1 or https://dns.google/dns-query.",
    ),
    "nameserverPolicyDesc": MessageLookupByLibrary.simpleMessage(
      "Matching domains use the DNS server given here instead of Nameserver and Fallback.",
    ),
    "navigationBarStyle": MessageLookupByLibrary.simpleMessage("Bottom bar"),
    "network": MessageLookupByLibrary.simpleMessage("Network"),
    "networkAccessDeniedError": m73,
    "networkBadResponseError": m74,
    "networkCancelledError": MessageLookupByLibrary.simpleMessage(
      "The request was cancelled",
    ),
    "networkConnectionError": MessageLookupByLibrary.simpleMessage(
      "Couldn\'t connect to the server. Check your network connection or proxy settings",
    ),
    "networkDiagnosis": MessageLookupByLibrary.simpleMessage(
      "Network diagnosis",
    ),
    "networkDiagnosisAllPassed": MessageLookupByLibrary.simpleMessage(
      "No problems found.",
    ),
    "networkDiagnosisProblems": m75,
    "networkDiagnosisRun": MessageLookupByLibrary.simpleMessage("Run again"),
    "networkHostLookupError": MessageLookupByLibrary.simpleMessage(
      "Couldn\'t resolve the server address. Check that the URL is correct and DNS is working",
    ),
    "networkName": MessageLookupByLibrary.simpleMessage("Network name"),
    "networkNotFoundError": m76,
    "networkRateLimitedError": MessageLookupByLibrary.simpleMessage(
      "Too many requests (HTTP 429). Wait a moment and try again",
    ),
    "networkRequestFailed": m77,
    "networkSecret": MessageLookupByLibrary.simpleMessage("Network secret"),
    "networkServerError": m78,
    "networkSpeed": MessageLookupByLibrary.simpleMessage("Network speed"),
    "networkTakeover": MessageLookupByLibrary.simpleMessage("Traffic takeover"),
    "networkTimeoutError": MessageLookupByLibrary.simpleMessage(
      "The request timed out. Check your network or proxy, then try again",
    ),
    "networkTlsError": MessageLookupByLibrary.simpleMessage(
      "Secure connection failed. The server\'s certificate may be invalid, or the connection is being intercepted",
    ),
    "networkType": MessageLookupByLibrary.simpleMessage("Network type"),
    "nextMatch": MessageLookupByLibrary.simpleMessage("Next match"),
    "no": MessageLookupByLibrary.simpleMessage("No"),
    "noData": MessageLookupByLibrary.simpleMessage("No data"),
    "noInfo": MessageLookupByLibrary.simpleMessage("No info"),
    "noLongerRemind": MessageLookupByLibrary.simpleMessage(
      "Don\'t remind me again",
    ),
    "noNetwork": MessageLookupByLibrary.simpleMessage("No network"),
    "noNetworkApp": MessageLookupByLibrary.simpleMessage("No-network apps"),
    "noResolve": MessageLookupByLibrary.simpleMessage("Don\'t resolve IP"),
    "noResolveHostname": MessageLookupByLibrary.simpleMessage(
      "Don\'t resolve hostname",
    ),
    "noSearchResults": MessageLookupByLibrary.simpleMessage(
      "No matching results",
    ),
    "nodes": MessageLookupByLibrary.simpleMessage("Nodes"),
    "nonTextProviderFile": MessageLookupByLibrary.simpleMessage(
      "This external resource is not a text file",
    ),
    "none": MessageLookupByLibrary.simpleMessage("None"),
    "notRunning": MessageLookupByLibrary.simpleMessage("Not running"),
    "notSelectedTip": MessageLookupByLibrary.simpleMessage(
      "The current proxy group cannot be selected",
    ),
    "ntpInterval": MessageLookupByLibrary.simpleMessage(
      "Sync interval (minutes)",
    ),
    "nullProfileDesc": MessageLookupByLibrary.simpleMessage(
      "Add a profile to get started",
    ),
    "nullTip": m79,
    "numberRangeTip": m80,
    "numberTip": m81,
    "obfs": MessageLookupByLibrary.simpleMessage("Obfuscation"),
    "obfsHost": MessageLookupByLibrary.simpleMessage("Obfuscation host"),
    "obfsMode": MessageLookupByLibrary.simpleMessage("Obfuscation mode"),
    "obfsParam": MessageLookupByLibrary.simpleMessage("Obfuscation parameter"),
    "obfsPassword": MessageLookupByLibrary.simpleMessage(
      "Obfuscation password",
    ),
    "onDemand": MessageLookupByLibrary.simpleMessage("On demand"),
    "onlyStatisticsProxy": MessageLookupByLibrary.simpleMessage(
      "Only count proxy traffic",
    ),
    "openSettings": MessageLookupByLibrary.simpleMessage("Open settings"),
    "optional": MessageLookupByLibrary.simpleMessage("Optional"),
    "options": MessageLookupByLibrary.simpleMessage("Options"),
    "originalUrl": MessageLookupByLibrary.simpleMessage("Original URL"),
    "ostreeUpdateTip": MessageLookupByLibrary.simpleMessage(
      "This system is managed by rpm-ostree (such as Fedora Silverblue), which installs packages into a new system image. Run the command below, then restart the computer: the new version and its TUN service start only after the restart.",
    ),
    "ostreeUpdateTitle": MessageLookupByLibrary.simpleMessage(
      "Finish the update in a terminal",
    ),
    "other": MessageLookupByLibrary.simpleMessage("Other"),
    "otherContributors": MessageLookupByLibrary.simpleMessage(
      "Other contributors",
    ),
    "outbound": MessageLookupByLibrary.simpleMessage("Outbound"),
    "outboundExit": MessageLookupByLibrary.simpleMessage("Exit"),
    "outboundIp": MessageLookupByLibrary.simpleMessage("Outbound IP"),
    "outboundMode": MessageLookupByLibrary.simpleMessage("Outbound mode"),
    "overrideDestination": MessageLookupByLibrary.simpleMessage(
      "Override destination",
    ),
    "overrideEntries": MessageLookupByLibrary.simpleMessage("Override entries"),
    "overview": MessageLookupByLibrary.simpleMessage("Overview"),
    "parsePureIp": MessageLookupByLibrary.simpleMessage("Parse pure IP"),
    "password": MessageLookupByLibrary.simpleMessage("Password"),
    "paste": MessageLookupByLibrary.simpleMessage("Paste"),
    "peers": MessageLookupByLibrary.simpleMessage("Peers"),
    "pickFromAlbum": MessageLookupByLibrary.simpleMessage("Choose from album"),
    "pinWindow": MessageLookupByLibrary.simpleMessage("Pin window"),
    "pleaseBindWebDAV": MessageLookupByLibrary.simpleMessage(
      "Please bind WebDAV",
    ),
    "pleaseEnterScriptName": MessageLookupByLibrary.simpleMessage(
      "Please enter a script name",
    ),
    "pleaseUploadValidQrcode": MessageLookupByLibrary.simpleMessage(
      "Please upload a valid QR code",
    ),
    "plugin": MessageLookupByLibrary.simpleMessage("Plugin"),
    "pluginCipher": MessageLookupByLibrary.simpleMessage("Plugin cipher"),
    "pluginHost": MessageLookupByLibrary.simpleMessage("Plugin host"),
    "pluginMode": MessageLookupByLibrary.simpleMessage("Plugin mode"),
    "pluginPassword": MessageLookupByLibrary.simpleMessage("Plugin password"),
    "pluginPath": MessageLookupByLibrary.simpleMessage("Plugin path"),
    "pluginUsername": MessageLookupByLibrary.simpleMessage("Plugin username"),
    "port": MessageLookupByLibrary.simpleMessage("Port"),
    "portConflictTip": MessageLookupByLibrary.simpleMessage(
      "Please enter a different port",
    ),
    "portHopping": MessageLookupByLibrary.simpleMessage("Port hopping"),
    "portInUseBanner": m82,
    "portInUseSwitch": MessageLookupByLibrary.simpleMessage("Switch port"),
    "portInUseTip": m83,
    "portInUseTitle": m84,
    "portTip": m85,
    "portValue": m86,
    "ports": MessageLookupByLibrary.simpleMessage("Ports"),
    "preSharedKey": MessageLookupByLibrary.simpleMessage("Pre-shared key"),
    "preferred": MessageLookupByLibrary.simpleMessage("Preferred"),
    "prerequisites": MessageLookupByLibrary.simpleMessage("Prerequisites"),
    "pressKeyboard": MessageLookupByLibrary.simpleMessage(
      "Press a key combination",
    ),
    "preview": MessageLookupByLibrary.simpleMessage("Preview"),
    "previousMatch": MessageLookupByLibrary.simpleMessage("Previous match"),
    "privateKey": MessageLookupByLibrary.simpleMessage("Private key"),
    "privateKeyPassphrase": MessageLookupByLibrary.simpleMessage(
      "Private key passphrase",
    ),
    "process": MessageLookupByLibrary.simpleMessage("Process"),
    "profile": MessageLookupByLibrary.simpleMessage("Profile"),
    "profileAutoUpdateIntervalInvalidValidationDesc":
        MessageLookupByLibrary.simpleMessage("Please enter a valid interval"),
    "profileAutoUpdateIntervalNullValidationDesc":
        MessageLookupByLibrary.simpleMessage(
          "Please enter the auto-update interval",
        ),
    "profileDaysLeft": m87,
    "profileExpiresIn": m88,
    "profileHasUpdate": MessageLookupByLibrary.simpleMessage(
      "The profile has been modified. Turn off auto update?",
    ),
    "profileNameNullValidationDesc": MessageLookupByLibrary.simpleMessage(
      "Please enter the profile name",
    ),
    "profileSettingsDesc": MessageLookupByLibrary.simpleMessage(
      "Applies to this profile only; anything not added uses its default.",
    ),
    "profileTunSettingsDesc": MessageLookupByLibrary.simpleMessage(
      "Applies to this profile only and takes precedence over the TUN override entries in the network settings.",
    ),
    "profileUpdatedAt": m89,
    "profileUrlInvalidValidationDesc": MessageLookupByLibrary.simpleMessage(
      "Please enter a valid profile URL",
    ),
    "profileUrlNullValidationDesc": MessageLookupByLibrary.simpleMessage(
      "Please enter the profile URL",
    ),
    "profiles": MessageLookupByLibrary.simpleMessage("Profiles"),
    "profilesSort": MessageLookupByLibrary.simpleMessage("Sort profiles"),
    "project": MessageLookupByLibrary.simpleMessage("Project"),
    "protocol": MessageLookupByLibrary.simpleMessage("Protocol"),
    "protocolParam": MessageLookupByLibrary.simpleMessage("Protocol parameter"),
    "protocolVersion": MessageLookupByLibrary.simpleMessage("Protocol version"),
    "providerInUse": m90,
    "providerUrlTip": MessageLookupByLibrary.simpleMessage(
      "Only remote providers are supported",
    ),
    "providers": MessageLookupByLibrary.simpleMessage("External resources"),
    "proxies": MessageLookupByLibrary.simpleMessage("Proxies"),
    "proxiesCount": m91,
    "proxiesProfileLabel": m92,
    "proxiesRemovedTip": m93,
    "proxiesReplacedTip": m94,
    "proxyChains": MessageLookupByLibrary.simpleMessage("Proxy chain"),
    "proxyGroup": MessageLookupByLibrary.simpleMessage("Proxy group"),
    "proxyGroupEmpty": MessageLookupByLibrary.simpleMessage(
      "Proxy group is empty",
    ),
    "proxyGroupInUse": m95,
    "proxyGroupsAfterStart": MessageLookupByLibrary.simpleMessage(
      "Groups show up here once the core starts",
    ),
    "proxyGroupsCount": m96,
    "proxyProviders": MessageLookupByLibrary.simpleMessage("Proxy providers"),
    "proxyServerNameserverDesc": MessageLookupByLibrary.simpleMessage(
      "Resolves proxy server hostnames only.",
    ),
    "proxyServerNameserverPolicyDesc": MessageLookupByLibrary.simpleMessage(
      "Matching proxy server hostnames use the DNS server given here instead of Proxy Server Nameserver.",
    ),
    "proxyType": MessageLookupByLibrary.simpleMessage("Proxy type"),
    "pruneCache": MessageLookupByLibrary.simpleMessage("Prune cache"),
    "publicKey": MessageLookupByLibrary.simpleMessage("Public key"),
    "pureBlack": MessageLookupByLibrary.simpleMessage("Pure black"),
    "pureBlackMode": MessageLookupByLibrary.simpleMessage("Pure black mode"),
    "qrcode": MessageLookupByLibrary.simpleMessage("QR code"),
    "qrcodeDesc": MessageLookupByLibrary.simpleMessage(
      "Scan a QR code to obtain a profile",
    ),
    "qrcodeTooLongTip": MessageLookupByLibrary.simpleMessage(
      "This link is too long for a QR code. Use Copy link instead.",
    ),
    "quickActions": MessageLookupByLibrary.simpleMessage("Quick actions"),
    "quickEdit": MessageLookupByLibrary.simpleMessage("Quick edit"),
    "recentRequests": MessageLookupByLibrary.simpleMessage("Recent requests"),
    "recommendedIcons": MessageLookupByLibrary.simpleMessage("Suggested"),
    "recordType": MessageLookupByLibrary.simpleMessage("Record type"),
    "redirPort": MessageLookupByLibrary.simpleMessage("Redir port"),
    "redo": MessageLookupByLibrary.simpleMessage("Redo"),
    "regenerateCertificate": MessageLookupByLibrary.simpleMessage(
      "Regenerate certificate",
    ),
    "regenerateCertificateTip": MessageLookupByLibrary.simpleMessage(
      "The new certificate replaces the current one, which Panorama Secure Access takes out of this device\'s trusted roots where it can. Every other device that trusts the current one has to install the new one.",
    ),
    "regex": MessageLookupByLibrary.simpleMessage("Regex"),
    "releaseMemory": MessageLookupByLibrary.simpleMessage("Release memory"),
    "releaseMemoryFailed": MessageLookupByLibrary.simpleMessage(
      "Failed to release memory",
    ),
    "remote": MessageLookupByLibrary.simpleMessage("Remote"),
    "remoteDestination": MessageLookupByLibrary.simpleMessage(
      "Remote destination",
    ),
    "remoteDnsResolve": MessageLookupByLibrary.simpleMessage(
      "Remote DNS resolution",
    ),
    "remove": MessageLookupByLibrary.simpleMessage("Remove"),
    "rename": MessageLookupByLibrary.simpleMessage("Rename"),
    "repairAuthorizeTun": MessageLookupByLibrary.simpleMessage("Authorize"),
    "repairClearProxy": MessageLookupByLibrary.simpleMessage("Clear"),
    "repairDisableIpv6": MessageLookupByLibrary.simpleMessage("Turn off IPv6"),
    "repairFlushDns": MessageLookupByLibrary.simpleMessage("Flush DNS"),
    "repairReapplyProxy": MessageLookupByLibrary.simpleMessage("Set again"),
    "repairRestartCore": MessageLookupByLibrary.simpleMessage("Restart core"),
    "replace": MessageLookupByLibrary.simpleMessage("Replace"),
    "replaceAll": MessageLookupByLibrary.simpleMessage("Replace all"),
    "request": MessageLookupByLibrary.simpleMessage("Request"),
    "requestBody": MessageLookupByLibrary.simpleMessage("Request body"),
    "requestHeaders": MessageLookupByLibrary.simpleMessage("Request headers"),
    "requests": MessageLookupByLibrary.simpleMessage("Requests"),
    "requestsAndUpdates": MessageLookupByLibrary.simpleMessage(
      "Requests and updates",
    ),
    "required": MessageLookupByLibrary.simpleMessage("Required"),
    "reset": MessageLookupByLibrary.simpleMessage("Reset"),
    "resetPageChangesTip": MessageLookupByLibrary.simpleMessage(
      "This page has changes. Are you sure you want to reset?",
    ),
    "resetTip": MessageLookupByLibrary.simpleMessage(
      "Are you sure you want to reset?",
    ),
    "resourceUpdateInterval": MessageLookupByLibrary.simpleMessage(
      "Auto-update interval",
    ),
    "resourceUpdateIntervalTip": MessageLookupByLibrary.simpleMessage(
      "The auto-update interval must be greater than 0",
    ),
    "resources": MessageLookupByLibrary.simpleMessage("Resources"),
    "respectRules": MessageLookupByLibrary.simpleMessage("Respect rules"),
    "respectRulesDesc": MessageLookupByLibrary.simpleMessage(
      "Respect rules routes DNS connections by the rules and needs a Proxy Server Nameserver.",
    ),
    "response": MessageLookupByLibrary.simpleMessage("Response"),
    "responseBody": MessageLookupByLibrary.simpleMessage("Response body"),
    "responseCode": MessageLookupByLibrary.simpleMessage("Response code"),
    "responseHeaders": MessageLookupByLibrary.simpleMessage("Response headers"),
    "restart": MessageLookupByLibrary.simpleMessage("Restart"),
    "restartCoreTip": MessageLookupByLibrary.simpleMessage(
      "Are you sure you want to restart the core?",
    ),
    "restore": MessageLookupByLibrary.simpleMessage("Restore"),
    "restoreAllData": MessageLookupByLibrary.simpleMessage("Restore all data"),
    "restoreBeforeUpdate": MessageLookupByLibrary.simpleMessage(
      "Restore from before the update",
    ),
    "restoreBeforeUpdateTip": m97,
    "restoreOnlyConfig": MessageLookupByLibrary.simpleMessage(
      "Restore profiles only",
    ),
    "restoreStrategy": MessageLookupByLibrary.simpleMessage("Restore strategy"),
    "restoreStrategyCompatible": MessageLookupByLibrary.simpleMessage(
      "Compatible",
    ),
    "restoreStrategyOverride": MessageLookupByLibrary.simpleMessage("Override"),
    "restoreSuccess": MessageLookupByLibrary.simpleMessage(
      "Restore successful",
    ),
    "result": MessageLookupByLibrary.simpleMessage("Result"),
    "retry": MessageLookupByLibrary.simpleMessage("Retry"),
    "root": MessageLookupByLibrary.simpleMessage("Root"),
    "routeAddress": MessageLookupByLibrary.simpleMessage("Route addresses"),
    "routeExcludeAddress": MessageLookupByLibrary.simpleMessage(
      "Route exclude addresses",
    ),
    "routingMark": MessageLookupByLibrary.simpleMessage("Routing mark"),
    "ru": MessageLookupByLibrary.simpleMessage("Russian"),
    "rule": MessageLookupByLibrary.simpleMessage("Rule"),
    "ruleActionAndDesc": MessageLookupByLibrary.simpleMessage(
      "Logical rule AND",
    ),
    "ruleActionDomainDesc": MessageLookupByLibrary.simpleMessage(
      "Match the full domain",
    ),
    "ruleActionDomainKeywordDesc": MessageLookupByLibrary.simpleMessage(
      "Match a domain keyword",
    ),
    "ruleActionDomainRegexDesc": MessageLookupByLibrary.simpleMessage(
      "Match a domain regex",
    ),
    "ruleActionDomainSuffixDesc": MessageLookupByLibrary.simpleMessage(
      "Match a domain suffix",
    ),
    "ruleActionDomainWildcardDesc": MessageLookupByLibrary.simpleMessage(
      "Wildcard match; only * and ? are supported",
    ),
    "ruleActionDscpDesc": MessageLookupByLibrary.simpleMessage(
      "Match the DSCP mark (tproxy UDP inbound only)",
    ),
    "ruleActionDstPortDesc": MessageLookupByLibrary.simpleMessage(
      "Match the destination port range",
    ),
    "ruleActionGeoipDesc": MessageLookupByLibrary.simpleMessage(
      "Match the IP\'s country code",
    ),
    "ruleActionGeositeDesc": MessageLookupByLibrary.simpleMessage(
      "Match domains in Geosite",
    ),
    "ruleActionInNameDesc": MessageLookupByLibrary.simpleMessage(
      "Match the inbound name",
    ),
    "ruleActionInPortDesc": MessageLookupByLibrary.simpleMessage(
      "Match the inbound port",
    ),
    "ruleActionInTypeDesc": MessageLookupByLibrary.simpleMessage(
      "Match the inbound type",
    ),
    "ruleActionInUserDesc": MessageLookupByLibrary.simpleMessage(
      "Match the inbound username; separate multiple usernames with /",
    ),
    "ruleActionIpAsnDesc": MessageLookupByLibrary.simpleMessage(
      "Match the IP\'s ASN",
    ),
    "ruleActionIpCidr6Desc": MessageLookupByLibrary.simpleMessage(
      "Match an IP address range; IP-CIDR6 is just an alias",
    ),
    "ruleActionIpCidrDesc": MessageLookupByLibrary.simpleMessage(
      "Match an IP address range",
    ),
    "ruleActionIpSuffixDesc": MessageLookupByLibrary.simpleMessage(
      "Match an IP suffix range",
    ),
    "ruleActionMatchDesc": MessageLookupByLibrary.simpleMessage(
      "Match all requests, no conditions needed",
    ),
    "ruleActionNetworkDesc": MessageLookupByLibrary.simpleMessage(
      "Match TCP or UDP",
    ),
    "ruleActionNotDesc": MessageLookupByLibrary.simpleMessage(
      "Logical rule NOT",
    ),
    "ruleActionOrDesc": MessageLookupByLibrary.simpleMessage("Logical rule OR"),
    "ruleActionProcessNameDesc": MessageLookupByLibrary.simpleMessage(
      "Match by process name; matches the package name on Android",
    ),
    "ruleActionProcessNameRegexDesc": MessageLookupByLibrary.simpleMessage(
      "Match by process name regex; matches the package name on Android",
    ),
    "ruleActionProcessNameWildcardDesc": MessageLookupByLibrary.simpleMessage(
      "Match by process name wildcard; only * and ? are supported",
    ),
    "ruleActionProcessPathDesc": MessageLookupByLibrary.simpleMessage(
      "Match by the full process path",
    ),
    "ruleActionProcessPathRegexDesc": MessageLookupByLibrary.simpleMessage(
      "Match by process path regex",
    ),
    "ruleActionProcessPathWildcardDesc": MessageLookupByLibrary.simpleMessage(
      "Match by process path wildcard; only * and ? are supported",
    ),
    "ruleActionRematchNameDesc": MessageLookupByLibrary.simpleMessage(
      "Match the rematch name; separate multiple names with /",
    ),
    "ruleActionRuleSetDesc": MessageLookupByLibrary.simpleMessage(
      "Reference a rule set; requires rule-providers",
    ),
    "ruleActionSrcGeoipDesc": MessageLookupByLibrary.simpleMessage(
      "Match the source IP\'s country code",
    ),
    "ruleActionSrcIpAsnDesc": MessageLookupByLibrary.simpleMessage(
      "Match the source IP\'s ASN",
    ),
    "ruleActionSrcIpCidrDesc": MessageLookupByLibrary.simpleMessage(
      "Match a source IP address range",
    ),
    "ruleActionSrcIpSuffixDesc": MessageLookupByLibrary.simpleMessage(
      "Match a source IP suffix range",
    ),
    "ruleActionSrcPortDesc": MessageLookupByLibrary.simpleMessage(
      "Match the source port range",
    ),
    "ruleActionSubRuleDesc": MessageLookupByLibrary.simpleMessage(
      "Match into a sub-rule; mind the parentheses",
    ),
    "ruleActionUidDesc": MessageLookupByLibrary.simpleMessage(
      "Match the Linux user ID",
    ),
    "ruleEmpty": MessageLookupByLibrary.simpleMessage("Rule is empty"),
    "ruleListInvalid": MessageLookupByLibrary.simpleMessage(
      "The rules must be a YAML list with one rule per item, such as - DOMAIN,example.com,DIRECT",
    ),
    "rulePresetBittorrentDirect": MessageLookupByLibrary.simpleMessage(
      "BitTorrent direct",
    ),
    "rulePresetBlockDot": MessageLookupByLibrary.simpleMessage(
      "Block DNS over TLS",
    ),
    "rulePresetBlockLoopback": MessageLookupByLibrary.simpleMessage(
      "Block proxy loopback",
    ),
    "rulePresetBlockQuic": MessageLookupByLibrary.simpleMessage("Block QUIC"),
    "rulePresetBlockStun": MessageLookupByLibrary.simpleMessage("Block STUN"),
    "rulePresetLanDirect": MessageLookupByLibrary.simpleMessage("LAN direct"),
    "rulePresetSystemServicesDirect": MessageLookupByLibrary.simpleMessage(
      "Apple and Microsoft direct",
    ),
    "ruleProviders": MessageLookupByLibrary.simpleMessage("Rule providers"),
    "ruleSet": MessageLookupByLibrary.simpleMessage("Rule set"),
    "ruleSetEmptyTip": MessageLookupByLibrary.simpleMessage(
      "The rule set has no usable entries",
    ),
    "ruleSetInvalidTip": MessageLookupByLibrary.simpleMessage(
      "This mrs file cannot be read",
    ),
    "ruleSetMixedTip": MessageLookupByLibrary.simpleMessage(
      "The rule set mixes domains and IP ranges, so its type cannot be told",
    ),
    "ruleTarget": MessageLookupByLibrary.simpleMessage("Rule target"),
    "ruleTextInvalid": MessageLookupByLibrary.simpleMessage(
      "The rule must start with a supported type, such as DOMAIN,example.com,DIRECT",
    ),
    "rules": MessageLookupByLibrary.simpleMessage("Rules"),
    "rulesCount": m98,
    "runTime": MessageLookupByLibrary.simpleMessage("Run time"),
    "running": MessageLookupByLibrary.simpleMessage("Running"),
    "runtimeConfig": MessageLookupByLibrary.simpleMessage("Runtime config"),
    "safeMode": MessageLookupByLibrary.simpleMessage("Safe mode"),
    "safeModeAppTitle": m99,
    "saturation": MessageLookupByLibrary.simpleMessage("Saturation"),
    "save": MessageLookupByLibrary.simpleMessage("Save"),
    "saveChanges": MessageLookupByLibrary.simpleMessage("Save the changes?"),
    "script": MessageLookupByLibrary.simpleMessage("Script"),
    "scriptModeDesc": MessageLookupByLibrary.simpleMessage(
      "Script mode: rewrites the whole profile with an extension script",
    ),
    "scrollToSelected": MessageLookupByLibrary.simpleMessage(
      "Scroll to selected",
    ),
    "search": MessageLookupByLibrary.simpleMessage("Search"),
    "seconds": MessageLookupByLibrary.simpleMessage("seconds"),
    "secondsCount": m100,
    "secretKey": MessageLookupByLibrary.simpleMessage("Key"),
    "sectionsInEffect": m101,
    "select": MessageLookupByLibrary.simpleMessage("Select"),
    "selectAll": MessageLookupByLibrary.simpleMessage("Select all"),
    "selectRuleSet": MessageLookupByLibrary.simpleMessage(
      "Please select a rule set",
    ),
    "selectSplitStrategy": MessageLookupByLibrary.simpleMessage(
      "Please select a split strategy",
    ),
    "send": MessageLookupByLibrary.simpleMessage("Send"),
    "sendFromPhone": MessageLookupByLibrary.simpleMessage("Send from phone"),
    "sendFromPhoneConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Import the link from your phone?",
    ),
    "sendFromPhoneNoNetwork": MessageLookupByLibrary.simpleMessage(
      "This device is not connected to a local network",
    ),
    "sendFromPhonePageHint": MessageLookupByLibrary.simpleMessage(
      "Subscription link or proxy share link",
    ),
    "sendFromPhonePageSent": MessageLookupByLibrary.simpleMessage(
      "Sent. Confirm the import on the other device.",
    ),
    "sendFromPhonePageTitle": MessageLookupByLibrary.simpleMessage(
      "Send a link to Panorama Secure Access",
    ),
    "sendFromPhonePermissionDenied": MessageLookupByLibrary.simpleMessage(
      "Receiving a link from your phone needs the Nearby devices permission, which lets Panorama Secure Access reach the local network. Turn it on in the app\'s settings.",
    ),
    "sendFromPhoneTip": MessageLookupByLibrary.simpleMessage(
      "Scan the code with your phone\'s camera and paste the link on the page that opens. Both devices need to be on the same network.",
    ),
    "server": MessageLookupByLibrary.simpleMessage("Server"),
    "serviceAbnormalCount": m102,
    "serviceAllAvailable": MessageLookupByLibrary.simpleMessage(
      "All available",
    ),
    "serviceAvailable": MessageLookupByLibrary.simpleMessage("Available"),
    "serviceBlocked": MessageLookupByLibrary.simpleMessage("Blocked"),
    "serviceCheckAll": MessageLookupByLibrary.simpleMessage("Check all"),
    "serviceComingSoon": MessageLookupByLibrary.simpleMessage("Coming soon"),
    "serviceDisallowedIsp": MessageLookupByLibrary.simpleMessage(
      "Disallowed ISP",
    ),
    "serviceFailed": MessageLookupByLibrary.simpleMessage("Check failed"),
    "serviceManage": MessageLookupByLibrary.simpleMessage("Manage services"),
    "serviceOriginalsOnly": MessageLookupByLibrary.simpleMessage(
      "Originals only",
    ),
    "servicePending": MessageLookupByLibrary.simpleMessage("Not checked"),
    "serviceRestricted": MessageLookupByLibrary.simpleMessage(
      "Access restricted",
    ),
    "serviceShownOnDashboard": MessageLookupByLibrary.simpleMessage(
      "Shown on the dashboard",
    ),
    "serviceStatus": MessageLookupByLibrary.simpleMessage("Service status"),
    "serviceUnavailable": MessageLookupByLibrary.simpleMessage("Unavailable"),
    "serviceUnsupportedRegion": MessageLookupByLibrary.simpleMessage(
      "Region not supported",
    ),
    "settingEntries": MessageLookupByLibrary.simpleMessage("settings"),
    "settings": MessageLookupByLibrary.simpleMessage("Settings"),
    "settingsCount": m103,
    "shareLinkUnreadable": m104,
    "shareLinksInvalid": MessageLookupByLibrary.simpleMessage(
      "No proxy could be read from the links",
    ),
    "shareQrcodeTip": MessageLookupByLibrary.simpleMessage(
      "Scan with Panorama Secure Access on another device to import this profile.",
    ),
    "show": MessageLookupByLibrary.simpleMessage("Show"),
    "showLess": MessageLookupByLibrary.simpleMessage("Collapse"),
    "showMore": MessageLookupByLibrary.simpleMessage("Expand"),
    "showNotificationStopAction": MessageLookupByLibrary.simpleMessage(
      "Stop button in notification",
    ),
    "showPassword": MessageLookupByLibrary.simpleMessage("Show password"),
    "sidebar": MessageLookupByLibrary.simpleMessage("Sidebar"),
    "silentLaunch": MessageLookupByLibrary.simpleMessage("Silent launch"),
    "singleImport": MessageLookupByLibrary.simpleMessage("Single import"),
    "singleShareLinkOnly": MessageLookupByLibrary.simpleMessage(
      "Enter one link here; edit several from the quick edit of the list",
    ),
    "singleValueTip": m105,
    "size": MessageLookupByLibrary.simpleMessage("Size"),
    "skipCertVerify": MessageLookupByLibrary.simpleMessage(
      "Skip certificate verification",
    ),
    "skipDomain": MessageLookupByLibrary.simpleMessage("Skip domains"),
    "skipDstAddress": MessageLookupByLibrary.simpleMessage(
      "Skip destination addresses",
    ),
    "skipServerCertVerify": MessageLookupByLibrary.simpleMessage(
      "Skip server certificate verification",
    ),
    "skipSrcAddress": MessageLookupByLibrary.simpleMessage(
      "Skip source addresses",
    ),
    "slide": MessageLookupByLibrary.simpleMessage("Slide"),
    "sliders": MessageLookupByLibrary.simpleMessage("Sliders"),
    "sniffProtocols": MessageLookupByLibrary.simpleMessage("Protocols"),
    "sniffer": MessageLookupByLibrary.simpleMessage("Sniffer"),
    "socksPort": MessageLookupByLibrary.simpleMessage("SOCKS port"),
    "softStyle": MessageLookupByLibrary.simpleMessage("Soft"),
    "sort": MessageLookupByLibrary.simpleMessage("Sort"),
    "source": MessageLookupByLibrary.simpleMessage("Source"),
    "sourceIp": MessageLookupByLibrary.simpleMessage("Source IP"),
    "specialProxy": MessageLookupByLibrary.simpleMessage("Special proxy"),
    "specialRules": MessageLookupByLibrary.simpleMessage("Special rules"),
    "spectrum": MessageLookupByLibrary.simpleMessage("Spectrum"),
    "speedStatistics": MessageLookupByLibrary.simpleMessage("Speed statistics"),
    "splitStrategy": MessageLookupByLibrary.simpleMessage("Split strategy"),
    "splitStrategyNotEmpty": MessageLookupByLibrary.simpleMessage(
      "Split strategy cannot be empty",
    ),
    "ssidsEmpty": MessageLookupByLibrary.simpleMessage("SSIDs are empty"),
    "stableChannel": MessageLookupByLibrary.simpleMessage("Stable"),
    "stackMode": MessageLookupByLibrary.simpleMessage("Stack mode"),
    "stackTrace": MessageLookupByLibrary.simpleMessage("Stack trace"),
    "standard": MessageLookupByLibrary.simpleMessage("Standard"),
    "standardModeDesc": MessageLookupByLibrary.simpleMessage(
      "Standard mode: adds rules on top of the profile",
    ),
    "start": MessageLookupByLibrary.simpleMessage("Start"),
    "startFromScratch": MessageLookupByLibrary.simpleMessage(
      "Start from scratch",
    ),
    "startVpn": MessageLookupByLibrary.simpleMessage("Starting VPN…"),
    "startupAndBackground": MessageLookupByLibrary.simpleMessage(
      "Startup and background",
    ),
    "status": MessageLookupByLibrary.simpleMessage("Status"),
    "statusDesc": MessageLookupByLibrary.simpleMessage(
      "With DNS off, the system DNS is used.",
    ),
    "stop": MessageLookupByLibrary.simpleMessage("Stop"),
    "stopUpdateDownloadTip": MessageLookupByLibrary.simpleMessage(
      "Stop downloading the update?",
    ),
    "stopVpn": MessageLookupByLibrary.simpleMessage("Stopping VPN…"),
    "strategy": MessageLookupByLibrary.simpleMessage("Strategy"),
    "strictRoute": MessageLookupByLibrary.simpleMessage("Strict route"),
    "strictRouteDesc": MessageLookupByLibrary.simpleMessage(
      "Strict route keeps traffic such as DNS from bypassing TUN, and with IPv6 off it blocks this device\'s IPv6 connections.",
    ),
    "style": MessageLookupByLibrary.simpleMessage("Style"),
    "submit": MessageLookupByLibrary.simpleMessage("Submit"),
    "subscriptionInfo": MessageLookupByLibrary.simpleMessage(
      "Subscription info",
    ),
    "sudoPasswordTitle": MessageLookupByLibrary.simpleMessage(
      "Enter your password for sudo",
    ),
    "suspended": MessageLookupByLibrary.simpleMessage("Suspended…"),
    "switchProfile": MessageLookupByLibrary.simpleMessage("Switch profile"),
    "sync": MessageLookupByLibrary.simpleMessage("Sync"),
    "system": MessageLookupByLibrary.simpleMessage("System"),
    "systemApp": MessageLookupByLibrary.simpleMessage("System apps"),
    "systemProxy": MessageLookupByLibrary.simpleMessage("System proxy"),
    "tab": MessageLookupByLibrary.simpleMessage("Tab"),
    "tabAnimation": MessageLookupByLibrary.simpleMessage("Tab animation"),
    "tapIconToRetry": MessageLookupByLibrary.simpleMessage(
      "Tap the icon to retry",
    ),
    "tapToAuthorize": MessageLookupByLibrary.simpleMessage("Tap to authorize"),
    "target": MessageLookupByLibrary.simpleMessage("Target"),
    "tcpConcurrent": MessageLookupByLibrary.simpleMessage("TCP concurrent"),
    "testInterval": MessageLookupByLibrary.simpleMessage("Test interval"),
    "testUrl": MessageLookupByLibrary.simpleMessage("Test URL"),
    "testWhenUsed": MessageLookupByLibrary.simpleMessage("Test when used"),
    "textScale": MessageLookupByLibrary.simpleMessage("Text scaling"),
    "textScalePreview": MessageLookupByLibrary.simpleMessage(
      "Text in the app will look like this",
    ),
    "theme": MessageLookupByLibrary.simpleMessage("Theme"),
    "themeColor": MessageLookupByLibrary.simpleMessage("Theme color"),
    "themeMode": MessageLookupByLibrary.simpleMessage("Theme mode"),
    "tight": MessageLookupByLibrary.simpleMessage("Tight"),
    "time": MessageLookupByLibrary.simpleMessage("Time"),
    "timeToFirstByte": MessageLookupByLibrary.simpleMessage(
      "Time to first byte",
    ),
    "timeout": MessageLookupByLibrary.simpleMessage("Timeout"),
    "tintedStyle": MessageLookupByLibrary.simpleMessage("Tinted"),
    "tip": MessageLookupByLibrary.simpleMessage("Tip"),
    "toggle": MessageLookupByLibrary.simpleMessage("Toggle"),
    "tolerance": MessageLookupByLibrary.simpleMessage("Tolerance"),
    "tools": MessageLookupByLibrary.simpleMessage("Tools"),
    "torch": MessageLookupByLibrary.simpleMessage("Flashlight"),
    "total": MessageLookupByLibrary.simpleMessage("Total"),
    "totalDownload": MessageLookupByLibrary.simpleMessage("Downloaded"),
    "totalTraffic": MessageLookupByLibrary.simpleMessage("Total traffic"),
    "totalUpload": MessageLookupByLibrary.simpleMessage("Uploaded"),
    "tproxyPort": MessageLookupByLibrary.simpleMessage("TProxy port"),
    "traffic": MessageLookupByLibrary.simpleMessage("Traffic"),
    "trafficMonthly": MessageLookupByLibrary.simpleMessage("Resets monthly"),
    "trafficPeak": m106,
    "trafficPeriod": MessageLookupByLibrary.simpleMessage("Traffic period"),
    "trafficPermanent": MessageLookupByLibrary.simpleMessage("Permanent"),
    "trafficTotal": m107,
    "trafficUsage": MessageLookupByLibrary.simpleMessage("Traffic usage"),
    "transport": MessageLookupByLibrary.simpleMessage("Transport"),
    "transportHeaders": m108,
    "trustCertificate": MessageLookupByLibrary.simpleMessage(
      "Trust certificate",
    ),
    "tun": MessageLookupByLibrary.simpleMessage("TUN"),
    "tunAuthorizationFailed": MessageLookupByLibrary.simpleMessage(
      "TUN could not be authorized, so it was turned off.",
    ),
    "tunDesc": MessageLookupByLibrary.simpleMessage(
      "TUN works only in administrator mode.",
    ),
    "tunOverrideDesc": MessageLookupByLibrary.simpleMessage(
      "Entries added here replace the TUN settings of every profile; anything not added keeps the profile\'s own setting. Entries a custom profile adds itself take precedence.",
    ),
    "turnOff": MessageLookupByLibrary.simpleMessage("Turn off"),
    "turnOn": MessageLookupByLibrary.simpleMessage("Turn on"),
    "udpRelayMode": MessageLookupByLibrary.simpleMessage("UDP relay mode"),
    "udpTimeout": MessageLookupByLibrary.simpleMessage("UDP timeout"),
    "udpTimeoutDesc": MessageLookupByLibrary.simpleMessage(
      "The UDP timeout is in seconds and works only with the gvisor, system and mixed stacks.",
    ),
    "ultra": MessageLookupByLibrary.simpleMessage("Ultra"),
    "undo": MessageLookupByLibrary.simpleMessage("Undo"),
    "unifiedDelay": MessageLookupByLibrary.simpleMessage("Unified delay"),
    "uninstallApp": MessageLookupByLibrary.simpleMessage("Uninstall"),
    "uninstallAppDesc": MessageLookupByLibrary.simpleMessage(
      "Remove the app, its background service and cache from this computer",
    ),
    "uninstallConfirm": MessageLookupByLibrary.simpleMessage(
      "Remove Panorama Secure Access from this computer? Its background service, launch at login, link handler and cache go too, and the app quits.",
    ),
    "uninstallDeleteDataTip": MessageLookupByLibrary.simpleMessage(
      "Also delete your subscriptions, settings and logs? They cannot be recovered. Keep them if you plan to install again.",
    ),
    "uninstallFailed": MessageLookupByLibrary.simpleMessage(
      "The app was not removed, so nothing was deleted.",
    ),
    "uninstallRebootTip": MessageLookupByLibrary.simpleMessage(
      "On Fedora Atomic (rpm-ostree) the app disappears after the next reboot.",
    ),
    "unknown": MessageLookupByLibrary.simpleMessage("Unknown"),
    "unknownNetworkError": MessageLookupByLibrary.simpleMessage(
      "Unknown network error",
    ),
    "unmaximize": MessageLookupByLibrary.simpleMessage("Restore down"),
    "unnamed": MessageLookupByLibrary.simpleMessage("Unnamed"),
    "unpinWindow": MessageLookupByLibrary.simpleMessage("Unpin window"),
    "update": MessageLookupByLibrary.simpleMessage("Update"),
    "updateChannel": MessageLookupByLibrary.simpleMessage("Update channel"),
    "updateDownloadFailed": MessageLookupByLibrary.simpleMessage(
      "The update could not be downloaded.",
    ),
    "updateDownloadStarted": MessageLookupByLibrary.simpleMessage(
      "Downloading the update. Follow its progress on the dashboard.",
    ),
    "updateDownloadTest": MessageLookupByLibrary.simpleMessage(
      "Update download test",
    ),
    "updateDownloading": MessageLookupByLibrary.simpleMessage(
      "Downloading update",
    ),
    "updateFailed": MessageLookupByLibrary.simpleMessage("Download failed"),
    "updateInstallFailed": MessageLookupByLibrary.simpleMessage(
      "The update could not be installed. You can download it from the release page instead.",
    ),
    "updateLater": MessageLookupByLibrary.simpleMessage("Later"),
    "updateNotVerified": MessageLookupByLibrary.simpleMessage(
      "The downloaded update could not be verified.",
    ),
    "updateNow": MessageLookupByLibrary.simpleMessage("Update now"),
    "updateReady": MessageLookupByLibrary.simpleMessage("Ready to install"),
    "updateReadyTip": MessageLookupByLibrary.simpleMessage(
      "The update has downloaded. Tap to install it.",
    ),
    "updateRestartTip": MessageLookupByLibrary.simpleMessage(
      "Panorama Secure Access closes to install the update and opens again when it is done.",
    ),
    "updateRetryHint": MessageLookupByLibrary.simpleMessage(
      "Check your network and try again.",
    ),
    "updateVerifying": MessageLookupByLibrary.simpleMessage(
      "Verifying download",
    ),
    "updateWhatsNew": MessageLookupByLibrary.simpleMessage("What\'s new"),
    "upload": MessageLookupByLibrary.simpleMessage("Upload"),
    "uploadBandwidth": MessageLookupByLibrary.simpleMessage("Upload bandwidth"),
    "url": MessageLookupByLibrary.simpleMessage("URL"),
    "urlRewrite": MessageLookupByLibrary.simpleMessage("URL rewrite"),
    "urlTip": m109,
    "useHosts": MessageLookupByLibrary.simpleMessage("Use hosts"),
    "useSystemHosts": MessageLookupByLibrary.simpleMessage("Use system hosts"),
    "usedShort": MessageLookupByLibrary.simpleMessage("used"),
    "usedTraffic": MessageLookupByLibrary.simpleMessage("Used traffic"),
    "userAgent": MessageLookupByLibrary.simpleMessage("User-Agent"),
    "username": MessageLookupByLibrary.simpleMessage("Username"),
    "validUntil": m110,
    "value": MessageLookupByLibrary.simpleMessage("Value"),
    "view": MessageLookupByLibrary.simpleMessage("View"),
    "viewAll": MessageLookupByLibrary.simpleMessage("View all"),
    "virtualIpv4": MessageLookupByLibrary.simpleMessage("Virtual IPv4"),
    "vividStyle": MessageLookupByLibrary.simpleMessage("Vivid"),
    "vpnConfigChangeDetected": MessageLookupByLibrary.simpleMessage(
      "VPN settings changed. Tap to restart",
    ),
    "webDAVConfiguration": MessageLookupByLibrary.simpleMessage(
      "WebDAV configuration",
    ),
    "whitelistMode": MessageLookupByLibrary.simpleMessage("Whitelist mode"),
    "writeToSystem": MessageLookupByLibrary.simpleMessage("Write to system"),
    "writeToSystemDesc": MessageLookupByLibrary.simpleMessage(
      "Write to system also sets the system clock; Android ignores it.",
    ),
    "yearsAgo": m111,
    "yearsAgoShort": m112,
    "yes": MessageLookupByLibrary.simpleMessage("Yes"),
    "zhCN": MessageLookupByLibrary.simpleMessage("Simplified Chinese"),
  };
}
