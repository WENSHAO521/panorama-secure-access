[Setup]
AppId={{APP_ID}}
AppVersion={{APP_VERSION}}
AppName={{DISPLAY_NAME}}
AppPublisher={{PUBLISHER_NAME}}
AppPublisherURL={{PUBLISHER_URL}}
AppSupportURL={{PUBLISHER_URL}}
AppUpdatesURL={{PUBLISHER_URL}}
DefaultDirName={{INSTALL_DIR_NAME}}
DisableProgramGroupPage=yes
OutputDir=.
OutputBaseFilename={{OUTPUT_BASE_FILENAME}}
Compression=lzma
SolidCompression=yes
SetupIconFile={{SETUP_ICON_FILE}}
WizardStyle=modern
PrivilegesRequired={{PRIVILEGES_REQUIRED}}
ArchitecturesAllowed={{ARCH}}
ArchitecturesInstallIn64BitMode={{ARCH}}

[Code]
const
  SYNCHRONIZE = $00100000;
  // Releases up to 3.5.x shipped under FlClash's AppId, binary and service
  // names; only an install whose uninstall entry carries our display name is
  // ours to take over, so a FlClash install on the same machine stays intact.
  LegacyUninstallKey = 'Software\Microsoft\Windows\CurrentVersion\Uninstall\{728B3532-C74B-4870-9068-BE70FE12A3E6}_is1';
  LegacyDisplayName = 'Panorama Secure Access';
  LegacyHelperService = 'FlClashHelperService';
  LegacyHelperServiceKey = 'SYSTEM\CurrentControlSet\Services\FlClashHelperService';

function OpenProcess(dwDesiredAccess: DWORD; bInheritHandle: BOOL; dwProcessId: DWORD): THandle;
  external 'OpenProcess@kernel32.dll stdcall';
function WaitForSingleObject(hHandle: THandle; dwMilliseconds: DWORD): DWORD;
  external 'WaitForSingleObject@kernel32.dll stdcall';
function CloseHandle(hObject: THandle): BOOL;
  external 'CloseHandle@kernel32.dll stdcall';

// The app passes /updatefrom=<pid> (windowsUpdateArguments in lib/common)
// and exits on its own, stopping the Core and clearing the system proxy.
function UpdatingAppPid: Integer;
begin
  Result := StrToIntDef(ExpandConstant('{param:updatefrom|0}'), 0);
end;

function IsAppUpdate: Boolean;
begin
  Result := UpdatingAppPid > 0;
end;

procedure WaitForUpdatingApp;
var
  Handle: THandle;
begin
  if not IsAppUpdate then
    Exit;
  Handle := OpenProcess(SYNCHRONIZE, False, UpdatingAppPid);
  if Handle <> 0 then
  begin
    WaitForSingleObject(Handle, 15000);
    CloseHandle(Handle);
  end;
end;

procedure KillProcesses;
var
  Processes: TArrayOfString;
  i: Integer;
  ResultCode: Integer;
begin
  Processes := ['{{EXECUTABLE_NAME}}', 'panorama-secure-access-core.exe', 'panorama-secure-access-helper.exe'];

  for i := 0 to GetArrayLength(Processes)-1 do
  begin
    Exec('taskkill', '/f /im ' + Processes[i], '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  end;
end;

procedure UnregisterHelperService;
var
  HelperPath: String;
  ResultCode: Integer;
begin
  HelperPath := ExpandConstant('{app}\\panorama-secure-access-helper.exe');
  if FileExists(HelperPath) then
  begin
    Exec(HelperPath, 'uninstall', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  end;
end;

procedure ClearStaleProxy;
var
  AppPath: String;
  ResultCode: Integer;
begin
  AppPath := ExpandConstant('{app}\\{{EXECUTABLE_NAME}}');
  if FileExists(AppPath) then
  begin
    Exec(AppPath, '--clear-stale-proxy', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  end;
end;

function PointsInto(Dir, Value: String): Boolean;
begin
  Result := Pos(Lowercase(AddBackslash(Dir)), Lowercase(Value)) > 0;
end;

function PointsIntoApp(Value: String): Boolean;
begin
  Result := PointsInto(ExpandConstant('{app}'), Value);
end;

// The value name is appName in lib/common; the schemes are protocolSchemes
// plus the flclash scheme that releases up to 3.5.x also registered.
procedure RemoveRegistrationsInto(Dir: String);
var
  Schemes: TArrayOfString;
  Value: String;
  i: Integer;
begin
  if RegQueryStringValue(HKCU, 'Software\Microsoft\Windows\CurrentVersion\Run', 'Panorama Secure Access', Value) and PointsInto(Dir, Value) then
  begin
    RegDeleteValue(HKCU, 'Software\Microsoft\Windows\CurrentVersion\Run', 'Panorama Secure Access');
    RegDeleteValue(HKCU, 'Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run', 'Panorama Secure Access');
  end;

  Schemes := ['clash', 'clashmeta', 'flclash'];
  for i := 0 to GetArrayLength(Schemes)-1 do
  begin
    if RegQueryStringValue(HKCU, 'Software\Classes\' + Schemes[i] + '\shell\open\command', '', Value) and PointsInto(Dir, Value) then
    begin
      RegDeleteKeyIncludingSubkeys(HKCU, 'Software\Classes\' + Schemes[i]);
    end;
  end;
end;

procedure RemoveUserRegistrations;
begin
  RemoveRegistrationsInto(ExpandConstant('{app}'));
end;

function LegacyInstallDir(var Dir: String): Boolean;
var
  Name: String;
begin
  Result := RegQueryStringValue(HKLM, LegacyUninstallKey, 'DisplayName', Name)
    and (Name = LegacyDisplayName)
    and RegQueryStringValue(HKLM, LegacyUninstallKey, 'InstallLocation', Dir)
    and (Dir <> '') and DirExists(Dir);
  if Result then
    Dir := RemoveBackslashUnlessRoot(Dir);
end;

procedure StopProcessesUnder(Dir: String);
var
  ResultCode: Integer;
begin
  StringChangeEx(Dir, '''', '''''', True);
  Exec('powershell.exe', '-NoProfile -NonInteractive -Command "Get-Process | Where-Object { $_.Path -and $_.Path.StartsWith(''' + AddBackslash(Dir) + ''', [StringComparison]::OrdinalIgnoreCase) } | Stop-Process -Force"',
    '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
end;

// Runs after the new files are in place, so a failed install leaves the old
// one working. A legacy install in this same folder already had its files
// replaced; only its own binaries, entry and service are left to remove.
procedure RemoveLegacyInstall;
var
  Dir, ImagePath: String;
  ResultCode: Integer;
  SameDir: Boolean;
begin
  if not LegacyInstallDir(Dir) then
    Exit;
  SameDir := CompareText(AddBackslash(Dir), AddBackslash(ExpandConstant('{app}'))) = 0;
  if RegQueryStringValue(HKLM, LegacyHelperServiceKey, 'ImagePath', ImagePath) and PointsInto(Dir, ImagePath) then
  begin
    Exec(ExpandConstant('{sys}\sc.exe'), 'stop ' + LegacyHelperService, '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
    Exec(ExpandConstant('{sys}\sc.exe'), 'delete ' + LegacyHelperService, '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  end;
  StopProcessesUnder(Dir);
  RemoveRegistrationsInto(Dir);
  if SameDir then
  begin
    DeleteFile(Dir + '\FlClash.exe');
    DeleteFile(Dir + '\FlClashCore.exe');
    DeleteFile(Dir + '\FlClashHelperService.exe');
  end
  else
  begin
    DelTree(Dir, True, True, True);
  end;
  RegDeleteKeyIncludingSubkeys(HKLM, LegacyUninstallKey);
end;

function PrepareToInstall(var NeedsRestart: Boolean): String;
begin
  WaitForUpdatingApp;
  UnregisterHelperService;
  KillProcesses;
  Result := '';
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    RemoveLegacyInstall;
    ClearStaleProxy;
  end;
end;

function InitializeUninstall(): Boolean;
begin
  UnregisterHelperService;
  KillProcesses;
  ClearStaleProxy;
  Result := True;
end;

// path_provider names these folders after CompanyName and ProductName in
// windows/runner/Runner.rc; com.follow\clash belongs to FlClash.
procedure RemoveUserData;
begin
  DelTree(ExpandConstant('{userappdata}\Panorama Scholarly Group\Panorama Secure Access'), True, True, True);
  DelTree(ExpandConstant('{localappdata}\Panorama Scholarly Group\Panorama Secure Access'), True, True, True);
  RemoveDir(ExpandConstant('{userappdata}\Panorama Scholarly Group'));
  RemoveDir(ExpandConstant('{localappdata}\Panorama Scholarly Group'));
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usPostUninstall then
  begin
    RemoveUserRegistrations;
    if not UninstallSilent and (MsgBox(CustomMessage('RemoveUserData'), mbConfirmation, MB_YESNO or MB_DEFBUTTON2) = IDYES) then
    begin
      RemoveUserData;
    end;
  end;
end;

[Languages]
{% for locale in LOCALES %}
{% if locale.lang == 'en' %}Name: "english"; MessagesFile: "compiler:Default.isl"{% endif %}
{% if locale.lang == 'hy' %}Name: "armenian"; MessagesFile: "compiler:Languages\\Armenian.isl"{% endif %}
{% if locale.lang == 'bg' %}Name: "bulgarian"; MessagesFile: "compiler:Languages\\Bulgarian.isl"{% endif %}
{% if locale.lang == 'ca' %}Name: "catalan"; MessagesFile: "compiler:Languages\\Catalan.isl"{% endif %}
{% if locale.lang == 'zh' %}
Name: "chineseSimplified"; MessagesFile: {% if locale.file %}{{ locale.file }}{% else %}"compiler:Languages\\ChineseSimplified.isl"{% endif %}
{% endif %}
{% if locale.lang == 'co' %}Name: "corsican"; MessagesFile: "compiler:Languages\\Corsican.isl"{% endif %}
{% if locale.lang == 'cs' %}Name: "czech"; MessagesFile: "compiler:Languages\\Czech.isl"{% endif %}
{% if locale.lang == 'da' %}Name: "danish"; MessagesFile: "compiler:Languages\\Danish.isl"{% endif %}
{% if locale.lang == 'nl' %}Name: "dutch"; MessagesFile: "compiler:Languages\\Dutch.isl"{% endif %}
{% if locale.lang == 'fi' %}Name: "finnish"; MessagesFile: "compiler:Languages\\Finnish.isl"{% endif %}
{% if locale.lang == 'fr' %}Name: "french"; MessagesFile: "compiler:Languages\\French.isl"{% endif %}
{% if locale.lang == 'de' %}Name: "german"; MessagesFile: "compiler:Languages\\German.isl"{% endif %}
{% if locale.lang == 'he' %}Name: "hebrew"; MessagesFile: "compiler:Languages\\Hebrew.isl"{% endif %}
{% if locale.lang == 'is' %}Name: "icelandic"; MessagesFile: "compiler:Languages\\Icelandic.isl"{% endif %}
{% if locale.lang == 'it' %}Name: "italian"; MessagesFile: "compiler:Languages\\Italian.isl"{% endif %}
{% if locale.lang == 'ja' %}Name: "japanese"; MessagesFile: "compiler:Languages\\Japanese.isl"{% endif %}
{% if locale.lang == 'no' %}Name: "norwegian"; MessagesFile: "compiler:Languages\\Norwegian.isl"{% endif %}
{% if locale.lang == 'pl' %}Name: "polish"; MessagesFile: "compiler:Languages\\Polish.isl"{% endif %}
{% if locale.lang == 'pt' %}Name: "portuguese"; MessagesFile: "compiler:Languages\\Portuguese.isl"{% endif %}
{% if locale.lang == 'ru' %}Name: "russian"; MessagesFile: "compiler:Languages\\Russian.isl"{% endif %}
{% if locale.lang == 'sk' %}Name: "slovak"; MessagesFile: "compiler:Languages\\Slovak.isl"{% endif %}
{% if locale.lang == 'sl' %}Name: "slovenian"; MessagesFile: "compiler:Languages\\Slovenian.isl"{% endif %}
{% if locale.lang == 'es' %}Name: "spanish"; MessagesFile: "compiler:Languages\\Spanish.isl"{% endif %}
{% if locale.lang == 'tr' %}Name: "turkish"; MessagesFile: "compiler:Languages\\Turkish.isl"{% endif %}
{% if locale.lang == 'uk' %}Name: "ukrainian"; MessagesFile: "compiler:Languages\\Ukrainian.isl"{% endif %}
{% endfor %}

[CustomMessages]
english.RemoveUserData=Also delete your profiles and settings?

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: {% if CREATE_DESKTOP_ICON != true %}unchecked{% else %}checkedonce{% endif %}
[Files]
Source: "{{SOURCE_DIR}}\\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
; NOTE: Don't use "Flags: ignoreversion" on any shared system files

[Icons]
Name: "{autoprograms}\\{{DISPLAY_NAME}}"; Filename: "{app}\\{{EXECUTABLE_NAME}}"
Name: "{autodesktop}\\{{DISPLAY_NAME}}"; Filename: "{app}\\{{EXECUTABLE_NAME}}"; Tasks: desktopicon
[Run]
Filename: "{app}\\{{EXECUTABLE_NAME}}"; Description: "{cm:LaunchProgram,{{DISPLAY_NAME}}}"; Flags: {% if PRIVILEGES_REQUIRED == 'admin' %}runascurrentuser{% endif %} nowait postinstall skipifsilent
Filename: "{app}\\{{EXECUTABLE_NAME}}"; Flags: {% if PRIVILEGES_REQUIRED == 'admin' %}runascurrentuser{% endif %} nowait; Check: IsAppUpdate
