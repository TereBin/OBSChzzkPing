#ifndef MyAppVersion
  #define MyAppVersion "0.8.3"
#endif

#define MyAppName "OBSChzzkPing"
#define MyPublisher "TereBin"
#define MyAppUrl "https://github.com/TereBin/OBSChzzkPing-Release"

[Setup]
AppId={{D0783C79-659A-4CC6-8483-7D73DE54040B}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyPublisher}
AppPublisherURL={#MyAppUrl}
AppSupportURL=https://github.com/TereBin/OBSChzzkPing/issues
AppUpdatesURL=https://github.com/TereBin/OBSChzzkPing-Release/releases/latest
DefaultDirName={autopf}\OBSChzzkPing
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
DisableDirPage=yes
LicenseFile=..\LICENSE
OutputDir=..\artifacts
OutputBaseFilename=OBSChzzkPing-Setup
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
UninstallDisplayName={#MyAppName}
UninstallDisplayIcon={code:GetObsExecutable}
VersionInfoVersion={#MyAppVersion}.0
VersionInfoCompany={#MyPublisher}
VersionInfoDescription=OBS Studio용 치지직 LIVE 알림 플러그인 설치 관리자
VersionInfoProductName={#MyAppName}
VersionInfoProductVersion={#MyAppVersion}

[Languages]
Name: "korean"; MessagesFile: "compiler:Languages\Korean.isl"

[Files]
Source: "..\build\RelWithDebInfo\streamping.dll"; DestDir: "{code:GetObsPluginDir}"; Flags: ignoreversion; BeforeInstall: BackupExistingPlugin
Source: "..\data\locale\ko-KR.ini"; DestDir: "{code:GetObsLocaleDir}"; Flags: ignoreversion

[Icons]
Name: "{group}\OBSChzzkPing 최신 릴리스"; Filename: "https://github.com/TereBin/OBSChzzkPing-Release/releases/latest"
Name: "{group}\OBSChzzkPing 제거"; Filename: "{uninstallexe}"

[Run]
Filename: "{code:GetObsExecutable}"; Description: "OBS Studio 실행"; Flags: postinstall nowait skipifsilent unchecked

[Code]
var
  ObsPathPage: TInputDirWizardPage;

function IsObsRoot(const Path: String): Boolean;
begin
  Result := FileExists(AddBackslash(Path) + 'bin\64bit\obs64.exe');
end;

function DetectObsRoot(): String;
var
  Candidate: String;
begin
  Result := '';
  if RegQueryStringValue(HKLM64, 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\OBS Studio',
    'InstallLocation', Candidate) and IsObsRoot(Candidate) then
    Result := Candidate
  else if RegQueryStringValue(HKLM32, 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\OBS Studio',
    'InstallLocation', Candidate) and IsObsRoot(Candidate) then
    Result := Candidate
  else if RegQueryStringValue(HKCU, 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\OBS Studio',
    'InstallLocation', Candidate) and IsObsRoot(Candidate) then
    Result := Candidate
  else begin
    Candidate := ExpandConstant('{autopf}\obs-studio');
    if IsObsRoot(Candidate) then
      Result := Candidate;
  end;
end;

function IsObsRunning(): Boolean;
var
  ResultCode: Integer;
begin
  Result := Exec(ExpandConstant('{cmd}'),
    '/C tasklist /FI "IMAGENAME eq obs64.exe" | find /I "obs64.exe" >nul',
    '', SW_HIDE, ewWaitUntilTerminated, ResultCode) and (ResultCode = 0);
end;

procedure InitializeWizard();
var
  DetectedPath: String;
begin
  ObsPathPage := CreateInputDirPage(wpSelectDir,
    'OBS Studio 위치',
    'OBS Studio가 설치된 폴더를 선택하세요.',
    'bin\64bit\obs64.exe가 들어 있는 OBS Studio 최상위 폴더를 선택합니다.',
    False, '');
  ObsPathPage.Add('OBS Studio 폴더:');
  DetectedPath := ExpandConstant('{param:OBSPATH|}');
  if DetectedPath = '' then
    DetectedPath := DetectObsRoot();
  if DetectedPath <> '' then
    ObsPathPage.Values[0] := DetectedPath
  else
    ObsPathPage.Values[0] := ExpandConstant('{autopf}\obs-studio');
end;

function NextButtonClick(CurPageID: Integer): Boolean;
begin
  Result := True;
  if CurPageID = ObsPathPage.ID then begin
    if not IsObsRoot(ObsPathPage.Values[0]) then begin
      MsgBox('선택한 폴더에서 OBS Studio를 찾을 수 없습니다.' + #13#10 +
        'bin\64bit\obs64.exe가 있는 OBS Studio 최상위 폴더를 선택해 주세요.',
        mbError, MB_OK);
      Result := False;
    end;
  end;
end;

function PrepareToInstall(var NeedsRestart: Boolean): String;
begin
  Result := '';
  if IsObsRunning() then
    Result := 'OBS Studio가 실행 중입니다. OBS를 완전히 종료한 뒤 다시 시도해 주세요.';
end;

function GetObsRoot(Param: String): String;
begin
  Result := RemoveBackslashUnlessRoot(ObsPathPage.Values[0]);
end;

function GetObsPluginDir(Param: String): String;
begin
  Result := AddBackslash(GetObsRoot('')) + 'obs-plugins\64bit';
end;

function GetObsLocaleDir(Param: String): String;
begin
  Result := AddBackslash(GetObsRoot('')) + 'data\obs-plugins\streamping\locale';
end;

function GetObsExecutable(Param: String): String;
begin
  Result := AddBackslash(GetObsRoot('')) + 'bin\64bit\obs64.exe';
end;

procedure BackupExistingPlugin();
var
  ExistingPlugin: String;
begin
  ExistingPlugin := AddBackslash(GetObsPluginDir('')) + 'streamping.dll';
  if FileExists(ExistingPlugin) then
    CopyFile(ExistingPlugin, ExistingPlugin + '.bak', False);
end;
