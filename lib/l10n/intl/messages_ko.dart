// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a ko locale. All the
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
  String get localeName => 'ko';

  static String m0(count) =>
      "${Intl.plural(count, one: '1일 전', other: '${count}일 전')}";

  static String m1(label) => "선택한 ${label}을(를) 삭제하시겠습니까?";

  static String m2(label) => "현재 ${label}을(를) 삭제하시겠습니까?";

  static String m3(label) => "${label} 세부 정보";

  static String m4(label) => "${label}은(는) 비워둘 수 없습니다";

  static String m5(count) => "${count}개 항목";

  static String m6(label) => "현재 ${label}이(가) 이미 존재합니다";

  static String m7(name) => "${name} 건너뜀";

  static String m8(name) => "${name} 업데이트됨";

  static String m9(name) => "${name} 업데이트 중...";

  static String m10(count) =>
      "${Intl.plural(count, one: '1시간 전', other: '${count}시간 전')}";

  static String m11(count) => "${count}시간";

  static String m12(target) => "${target}은(는) 잘못된 정책입니다";

  static String m13(proxyName) => "${proxyName}은(는) 잘못된 프록시입니다";

  static String m14(providerName) => "${providerName}은(는) 잘못된 프록시 제공자입니다";

  static String m15(subRule) => "${subRule}은(는) 잘못된 SUB_RULE입니다";

  static String m16(appName) =>
      "1. 시스템 설정 > 개인정보 보호 및 보안을 엽니다\n2. 위치 서비스를 선택합니다\n3. 오른쪽 목록에서 ${appName}을(를) 찾아 체크합니다\n\n설정을 완료한 후 앱으로 돌아와 평소대로 이용해 주세요. 협조해 주셔서 감사합니다.";

  static String m17(count) =>
      "${Intl.plural(count, one: '1분 전', other: '${count}분 전')}";

  static String m18(count) =>
      "${Intl.plural(count, one: '1개월 전', other: '${count}개월 전')}";

  static String m19(label) => "아직 ${label}이(가) 없습니다";

  static String m20(label) => "${label}은(는) 숫자여야 합니다";

  static String m21(label) => "${label}은(는) 1024에서 49151 사이여야 합니다";

  static String m22(count) => "${count}초";

  static String m23(count) => "${count}개 항목이 선택되었습니다";

  static String m24(label) => "${label}은(는) URL 형식이어야 합니다";

  static String m25(count) =>
      "${Intl.plural(count, one: '1년 전', other: '${count}년 전')}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "about": MessageLookupByLibrary.simpleMessage("정보"),
    "accessControl": MessageLookupByLibrary.simpleMessage("접근 제어"),
    "accessControlAllowDesc": MessageLookupByLibrary.simpleMessage(
      "선택한 앱만 VPN 접속을 허용합니다",
    ),
    "accessControlDesc": MessageLookupByLibrary.simpleMessage(
      "애플리케이션의 프록시 접근을 설정합니다",
    ),
    "accessControlNotAllowDesc": MessageLookupByLibrary.simpleMessage(
      "선택한 애플리케이션은 VPN에서 제외됩니다",
    ),
    "accessControlSettings": MessageLookupByLibrary.simpleMessage("접근 제어 설정"),
    "account": MessageLookupByLibrary.simpleMessage("계정"),
    "action": MessageLookupByLibrary.simpleMessage("동작"),
    "action_mode": MessageLookupByLibrary.simpleMessage("모드 전환"),
    "action_proxy": MessageLookupByLibrary.simpleMessage("시스템 프록시"),
    "action_start": MessageLookupByLibrary.simpleMessage("시작/중지"),
    "action_tun": MessageLookupByLibrary.simpleMessage("TUN"),
    "action_view": MessageLookupByLibrary.simpleMessage("표시/숨김"),
    "add": MessageLookupByLibrary.simpleMessage("추가"),
    "addProfile": MessageLookupByLibrary.simpleMessage("프로필 추가"),
    "addProxies": MessageLookupByLibrary.simpleMessage("프록시 추가"),
    "addProxyGroup": MessageLookupByLibrary.simpleMessage("프록시 그룹 추가"),
    "addProxyProviders": MessageLookupByLibrary.simpleMessage("프록시 제공자 추가"),
    "addRule": MessageLookupByLibrary.simpleMessage("규칙 추가"),
    "addSsid": MessageLookupByLibrary.simpleMessage("SSID 추가"),
    "addedRules": MessageLookupByLibrary.simpleMessage("추가된 규칙"),
    "additionalParameters": MessageLookupByLibrary.simpleMessage("추가 매개변수"),
    "address": MessageLookupByLibrary.simpleMessage("주소"),
    "addressHelp": MessageLookupByLibrary.simpleMessage("WebDAV 서버 주소"),
    "addressTip": MessageLookupByLibrary.simpleMessage(
      "올바른 WebDAV 주소를 입력해 주세요",
    ),
    "advancedConfig": MessageLookupByLibrary.simpleMessage("고급 설정"),
    "advancedConfigDesc": MessageLookupByLibrary.simpleMessage(
      "다양한 설정 옵션을 제공합니다",
    ),
    "agree": MessageLookupByLibrary.simpleMessage("동의"),
    "allowBypass": MessageLookupByLibrary.simpleMessage("애플리케이션의 VPN 우회 허용"),
    "allowBypassDesc": MessageLookupByLibrary.simpleMessage(
      "활성화하면 일부 앱이 VPN을 우회할 수 있습니다",
    ),
    "allowLan": MessageLookupByLibrary.simpleMessage("LAN 허용"),
    "allowLanDesc": MessageLookupByLibrary.simpleMessage(
      "LAN을 통한 프록시 접근을 허용합니다",
    ),
    "app": MessageLookupByLibrary.simpleMessage("앱"),
    "appAccessControl": MessageLookupByLibrary.simpleMessage("앱 접근 제어"),
    "appendSystemDns": MessageLookupByLibrary.simpleMessage("시스템 DNS 추가"),
    "appendSystemDnsTip": MessageLookupByLibrary.simpleMessage(
      "설정에 시스템 DNS를 강제로 추가합니다",
    ),
    "application": MessageLookupByLibrary.simpleMessage("애플리케이션"),
    "applicationDesc": MessageLookupByLibrary.simpleMessage(
      "애플리케이션 관련 설정을 수정합니다",
    ),
    "authorized": MessageLookupByLibrary.simpleMessage("승인됨"),
    "auto": MessageLookupByLibrary.simpleMessage("자동"),
    "autoCheckUpdate": MessageLookupByLibrary.simpleMessage("자동 업데이트 확인"),
    "autoCheckUpdateDesc": MessageLookupByLibrary.simpleMessage(
      "앱 시작 시 자동으로 업데이트를 확인합니다",
    ),
    "autoCloseConnections": MessageLookupByLibrary.simpleMessage("연결 자동 종료"),
    "autoCloseConnectionsDesc": MessageLookupByLibrary.simpleMessage(
      "노드 변경 후 연결을 자동으로 종료합니다",
    ),
    "autoLaunch": MessageLookupByLibrary.simpleMessage("자동 시작"),
    "autoLaunchDesc": MessageLookupByLibrary.simpleMessage(
      "시스템 부팅 시 자동으로 시작합니다",
    ),
    "autoRun": MessageLookupByLibrary.simpleMessage("자동 실행"),
    "autoRunDesc": MessageLookupByLibrary.simpleMessage("앱이 열릴 때 자동으로 실행합니다"),
    "autoSetSystemDns": MessageLookupByLibrary.simpleMessage("시스템 DNS 자동 설정"),
    "autoUpdate": MessageLookupByLibrary.simpleMessage("자동 업데이트"),
    "autoUpdateInterval": MessageLookupByLibrary.simpleMessage("자동 업데이트 간격(분)"),
    "backup": MessageLookupByLibrary.simpleMessage("백업"),
    "backupAndRestore": MessageLookupByLibrary.simpleMessage("백업 및 복원"),
    "backupAndRestoreDesc": MessageLookupByLibrary.simpleMessage(
      "WebDAV 또는 파일을 통해 데이터를 동기화합니다",
    ),
    "backupSuccess": MessageLookupByLibrary.simpleMessage("백업 성공"),
    "basicConfig": MessageLookupByLibrary.simpleMessage("기본 설정"),
    "basicConfigDesc": MessageLookupByLibrary.simpleMessage("전역 기본 설정을 수정합니다"),
    "basicInfo": MessageLookupByLibrary.simpleMessage("기본 정보"),
    "basicStrategy": MessageLookupByLibrary.simpleMessage("기본 전략"),
    "batteryOptimizationDesc": MessageLookupByLibrary.simpleMessage(
      "백그라운드 실행을 보장하려면 이 앱의 배터리 최적화를 비활성화해 주세요. 탭하면 설정으로 이동합니다.",
    ),
    "batteryOptimizationStatusTip": MessageLookupByLibrary.simpleMessage(
      "시스템의 영향을 받으므로 이 상태가 항상 정확하지 않을 수 있습니다.",
    ),
    "bind": MessageLookupByLibrary.simpleMessage("연결"),
    "blacklistMode": MessageLookupByLibrary.simpleMessage("블랙리스트 모드"),
    "bypassDomain": MessageLookupByLibrary.simpleMessage("우회 도메인"),
    "bypassDomainDesc": MessageLookupByLibrary.simpleMessage(
      "시스템 프록시가 활성화된 경우에만 적용됩니다",
    ),
    "cacheCorrupt": MessageLookupByLibrary.simpleMessage(
      "캐시가 손상되었습니다. 삭제하시겠습니까?",
    ),
    "cancel": MessageLookupByLibrary.simpleMessage("취소"),
    "cancelSelectAll": MessageLookupByLibrary.simpleMessage("전체 선택 취소"),
    "checkUpdate": MessageLookupByLibrary.simpleMessage("업데이트 확인"),
    "checkUpdateError": MessageLookupByLibrary.simpleMessage(
      "현재 애플리케이션은 이미 최신 버전입니다",
    ),
    "clearData": MessageLookupByLibrary.simpleMessage("데이터 지우기"),
    "clipboardExport": MessageLookupByLibrary.simpleMessage("클립보드로 내보내기"),
    "clipboardImport": MessageLookupByLibrary.simpleMessage("클립보드에서 가져오기"),
    "color": MessageLookupByLibrary.simpleMessage("색상"),
    "colorSchemes": MessageLookupByLibrary.simpleMessage("색상 구성표"),
    "columns": MessageLookupByLibrary.simpleMessage("열"),
    "compatible": MessageLookupByLibrary.simpleMessage("호환 모드"),
    "configDataDetected": MessageLookupByLibrary.simpleMessage(
      "설정에서 데이터가 감지되었습니다",
    ),
    "confirm": MessageLookupByLibrary.simpleMessage("확인"),
    "confirmClearAllData": MessageLookupByLibrary.simpleMessage(
      "모든 데이터를 지우시겠습니까?",
    ),
    "confirmDeleteProxyGroup": MessageLookupByLibrary.simpleMessage(
      "현재 프록시 그룹을 삭제하시겠습니까?",
    ),
    "confirmExitWindow": MessageLookupByLibrary.simpleMessage(
      "현재 창을 종료하시겠습니까?",
    ),
    "confirmForceCrashCore": MessageLookupByLibrary.simpleMessage(
      "코어를 강제로 충돌시키시겠습니까?",
    ),
    "confirmOverwriteTip": MessageLookupByLibrary.simpleMessage(
      "확인하면 기존 데이터가 덮어쓰기됩니다",
    ),
    "connected": MessageLookupByLibrary.simpleMessage("연결됨"),
    "connecting": MessageLookupByLibrary.simpleMessage("연결 중..."),
    "connection": MessageLookupByLibrary.simpleMessage("연결"),
    "connections": MessageLookupByLibrary.simpleMessage("연결"),
    "connectionsDesc": MessageLookupByLibrary.simpleMessage("현재 연결 데이터를 확인합니다"),
    "connectivity": MessageLookupByLibrary.simpleMessage("연결 상태："),
    "content": MessageLookupByLibrary.simpleMessage("내용"),
    "contentNotEmpty": MessageLookupByLibrary.simpleMessage("내용은 비워둘 수 없습니다"),
    "contentScheme": MessageLookupByLibrary.simpleMessage("콘텐츠"),
    "controlGlobalAddedRules": MessageLookupByLibrary.simpleMessage(
      "전역 추가 규칙 제어",
    ),
    "copy": MessageLookupByLibrary.simpleMessage("복사"),
    "copyEnvVar": MessageLookupByLibrary.simpleMessage("환경 변수 복사 중"),
    "copyLink": MessageLookupByLibrary.simpleMessage("링크 복사"),
    "copySuccess": MessageLookupByLibrary.simpleMessage("복사 성공"),
    "core": MessageLookupByLibrary.simpleMessage("코어"),
    "coreStatus": MessageLookupByLibrary.simpleMessage("코어 상태"),
    "country": MessageLookupByLibrary.simpleMessage("국가"),
    "crashTest": MessageLookupByLibrary.simpleMessage("충돌 테스트"),
    "crashlytics": MessageLookupByLibrary.simpleMessage("충돌 분석"),
    "crashlyticsTip": MessageLookupByLibrary.simpleMessage(
      "활성화하면 앱이 충돌할 때 민감한 정보 없이 충돌 로그를 자동으로 업로드합니다",
    ),
    "create": MessageLookupByLibrary.simpleMessage("생성"),
    "createProfile": MessageLookupByLibrary.simpleMessage("프로필 생성"),
    "creationTime": MessageLookupByLibrary.simpleMessage("생성 시간"),
    "custom": MessageLookupByLibrary.simpleMessage("사용자 지정"),
    "cut": MessageLookupByLibrary.simpleMessage("잘라내기"),
    "dark": MessageLookupByLibrary.simpleMessage("다크"),
    "dashboard": MessageLookupByLibrary.simpleMessage("대시보드"),
    "dataChangedSave": MessageLookupByLibrary.simpleMessage(
      "데이터 변경이 감지되었습니다. 저장하시겠습니까?",
    ),
    "dataCollectionContent": MessageLookupByLibrary.simpleMessage(
      "이 앱은 앱 안정성 향상을 위해 Firebase Crashlytics를 사용하여 충돌 정보를 수집합니다.\n수집되는 데이터에는 기기 정보와 충돌 세부 정보가 포함되며, 개인 민감 정보는 포함되지 않습니다.\n설정에서 이 기능을 비활성화할 수 있습니다.",
    ),
    "dataCollectionTip": MessageLookupByLibrary.simpleMessage("데이터 수집 안내"),
    "daysAgo": m0,
    "defaultNameserver": MessageLookupByLibrary.simpleMessage("기본 네임서버"),
    "defaultNameserverDesc": MessageLookupByLibrary.simpleMessage("DNS 서버 확인용"),
    "defaultText": MessageLookupByLibrary.simpleMessage("기본값"),
    "delay": MessageLookupByLibrary.simpleMessage("지연 시간"),
    "delayTest": MessageLookupByLibrary.simpleMessage("지연 시간 테스트"),
    "delete": MessageLookupByLibrary.simpleMessage("삭제"),
    "deleteMultipTip": m1,
    "deleteTip": m2,
    "desc": MessageLookupByLibrary.simpleMessage(
      "심플하고 사용하기 쉬운, 오픈소스이자 광고 없는 ClashMeta 기반 멀티플랫폼 프록시 클라이언트입니다.",
    ),
    "destination": MessageLookupByLibrary.simpleMessage("대상"),
    "destinationGeoIP": MessageLookupByLibrary.simpleMessage("대상 GeoIP"),
    "destinationIPASN": MessageLookupByLibrary.simpleMessage("대상 IP ASN"),
    "details": m3,
    "detectionTip": MessageLookupByLibrary.simpleMessage(
      "서드파티 API에 의존하므로 참고용으로만 사용하세요",
    ),
    "developerMode": MessageLookupByLibrary.simpleMessage("개발자 모드"),
    "developerModeEnableTip": MessageLookupByLibrary.simpleMessage(
      "개발자 모드가 활성화되었습니다.",
    ),
    "direct": MessageLookupByLibrary.simpleMessage("직접 연결"),
    "disableUDP": MessageLookupByLibrary.simpleMessage("UDP 비활성화"),
    "disclaimer": MessageLookupByLibrary.simpleMessage("면책 조항"),
    "disclaimerDesc": MessageLookupByLibrary.simpleMessage(
      "Panorama Secure Access를 이용해 주셔서 감사합니다.\n\n본 소프트웨어는 Panorama Scholarly Group이 개발 및 유지 관리하며, 내부 기능 테스트와 기술 학습 목적으로만 제공됩니다. 상업적 서비스로 제공되지 않으며 공개 배포를 목적으로 하지 않습니다.\n\n본 소프트웨어는 상품성, 특정 목적에의 적합성, 비침해에 대한 묵시적 보증을 포함하되 이에 국한되지 않는 어떠한 명시적 또는 묵시적 보증 없이 \"있는 그대로(AS IS)\" 제공됩니다.\n\n본 소프트웨어를 사용하기 전에, 귀하는 본인의 사용 목적이 해당 지역에 적용되는 모든 법률 및 규정을 준수하는지 확인할 책임이 있습니다. 본 소프트웨어의 사용 또는 오용으로 인해 발생하는 모든 위험과 법적 책임은 전적으로 귀하 본인에게 있습니다.\n\n법률이 허용하는 최대 범위 내에서, Panorama Scholarly Group 및 그 개발자는 본 소프트웨어의 사용 또는 사용 불능으로 인해 발생하는 직접적, 간접적, 부수적 또는 결과적 손해에 대해 어떠한 책임도 지지 않습니다.",
    ),
    "disconnected": MessageLookupByLibrary.simpleMessage("연결 끊김"),
    "discoverNewVersion": MessageLookupByLibrary.simpleMessage("새 버전을 발견했습니다"),
    "dnsDesc": MessageLookupByLibrary.simpleMessage("DNS 관련 설정을 업데이트합니다"),
    "dnsHijacking": MessageLookupByLibrary.simpleMessage("DNS 하이재킹"),
    "dnsMode": MessageLookupByLibrary.simpleMessage("DNS 모드"),
    "doYouWantToPass": MessageLookupByLibrary.simpleMessage("통과하시겠습니까"),
    "domain": MessageLookupByLibrary.simpleMessage("도메인"),
    "download": MessageLookupByLibrary.simpleMessage("다운로드"),
    "downloadUpdateFailed": MessageLookupByLibrary.simpleMessage(
      "다운로드에 실패했습니다. 다시 시도해 주세요",
    ),
    "downloadingUpdate": MessageLookupByLibrary.simpleMessage("업데이트 다운로드 중..."),
    "edit": MessageLookupByLibrary.simpleMessage("편집"),
    "editGlobalRules": MessageLookupByLibrary.simpleMessage("전역 규칙 편집"),
    "editProxy": MessageLookupByLibrary.simpleMessage("프록시 편집"),
    "editProxyGroup": MessageLookupByLibrary.simpleMessage("프록시 그룹 편집"),
    "editRule": MessageLookupByLibrary.simpleMessage("규칙 편집"),
    "editSsid": MessageLookupByLibrary.simpleMessage("SSID 편집"),
    "emptyTip": m4,
    "en": MessageLookupByLibrary.simpleMessage("영어"),
    "entries": MessageLookupByLibrary.simpleMessage(" 항목"),
    "entriesCount": m5,
    "exclude": MessageLookupByLibrary.simpleMessage("최근 작업에서 숨기기"),
    "excludeDesc": MessageLookupByLibrary.simpleMessage(
      "앱이 백그라운드에 있을 때 최근 작업 목록에서 숨깁니다",
    ),
    "excludeProxyFilter": MessageLookupByLibrary.simpleMessage("제외 프록시 필터"),
    "excludeSsids": MessageLookupByLibrary.simpleMessage("제외할 SSID"),
    "excludeSsidsDesc": MessageLookupByLibrary.simpleMessage(
      "제외된 SSID의 Wi-Fi에 연결되면 앱 실행 상태가 자동으로 전환됩니다.",
    ),
    "excludeType": MessageLookupByLibrary.simpleMessage("제외 유형"),
    "existsTip": m6,
    "exit": MessageLookupByLibrary.simpleMessage("종료"),
    "expand": MessageLookupByLibrary.simpleMessage("표준"),
    "expectedStatus": MessageLookupByLibrary.simpleMessage("예상 상태"),
    "exportFile": MessageLookupByLibrary.simpleMessage("파일 내보내기"),
    "exportLogs": MessageLookupByLibrary.simpleMessage("로그 내보내기"),
    "exportSuccess": MessageLookupByLibrary.simpleMessage("내보내기 성공"),
    "expressiveScheme": MessageLookupByLibrary.simpleMessage("표현력"),
    "externalController": MessageLookupByLibrary.simpleMessage("외부 컨트롤러"),
    "externalControllerDesc": MessageLookupByLibrary.simpleMessage(
      "활성화하면 9090 포트에서 Clash 코어를 제어할 수 있습니다",
    ),
    "externalFetch": MessageLookupByLibrary.simpleMessage("외부 가져오기"),
    "externalLink": MessageLookupByLibrary.simpleMessage("외부 링크"),
    "fakeipFilter": MessageLookupByLibrary.simpleMessage("Fake IP 필터"),
    "fakeipRange": MessageLookupByLibrary.simpleMessage("Fake IP 범위"),
    "fallback": MessageLookupByLibrary.simpleMessage("Fallback"),
    "fallbackDesc": MessageLookupByLibrary.simpleMessage("일반적으로 해외 DNS를 사용합니다"),
    "fallbackFilter": MessageLookupByLibrary.simpleMessage("Fallback 필터"),
    "fidelityScheme": MessageLookupByLibrary.simpleMessage("정확도"),
    "file": MessageLookupByLibrary.simpleMessage("파일"),
    "fileDesc": MessageLookupByLibrary.simpleMessage("프로필을 직접 업로드합니다"),
    "fileIsUpdate": MessageLookupByLibrary.simpleMessage(
      "파일이 수정되었습니다. 변경 사항을 저장하시겠습니까?",
    ),
    "findProcessMode": MessageLookupByLibrary.simpleMessage("프로세스 찾기"),
    "findProcessModeDesc": MessageLookupByLibrary.simpleMessage(
      "활성화하면 일정한 성능 손실이 발생합니다",
    ),
    "fontFamily": MessageLookupByLibrary.simpleMessage("글꼴"),
    "forceRestartCoreTip": MessageLookupByLibrary.simpleMessage(
      "코어를 강제로 재시작하시겠습니까?",
    ),
    "fruitSaladScheme": MessageLookupByLibrary.simpleMessage("프루트 샐러드"),
    "general": MessageLookupByLibrary.simpleMessage("일반"),
    "geoAutoUpdate": MessageLookupByLibrary.simpleMessage("자동 업데이트"),
    "geoAutoUpdateInterval": MessageLookupByLibrary.simpleMessage("자동 업데이트 간격"),
    "geoAutoUpdateIntervalTip": MessageLookupByLibrary.simpleMessage(
      "자동 업데이트 간격은 0보다 커야 합니다",
    ),
    "geoOptions": MessageLookupByLibrary.simpleMessage("Geo 옵션"),
    "geoResources": MessageLookupByLibrary.simpleMessage("Geo 리소스"),
    "geoSkipped": m7,
    "geoUpdated": m8,
    "geoUpdating": m9,
    "geodataLoader": MessageLookupByLibrary.simpleMessage("Geo 저메모리 모드"),
    "geodataLoaderDesc": MessageLookupByLibrary.simpleMessage(
      "활성화하면 Geo 저메모리 로더를 사용합니다",
    ),
    "geoipCode": MessageLookupByLibrary.simpleMessage("Geoip 코드"),
    "global": MessageLookupByLibrary.simpleMessage("전역"),
    "go": MessageLookupByLibrary.simpleMessage("이동"),
    "goDownload": MessageLookupByLibrary.simpleMessage("다운로드로 이동"),
    "goToConfigureScript": MessageLookupByLibrary.simpleMessage("스크립트 설정으로 이동"),
    "hasCacheChange": MessageLookupByLibrary.simpleMessage("변경 사항을 캐시하시겠습니까?"),
    "hideFromList": MessageLookupByLibrary.simpleMessage("목록에서 숨기기"),
    "host": MessageLookupByLibrary.simpleMessage("호스트"),
    "hostsDesc": MessageLookupByLibrary.simpleMessage("Hosts 추가"),
    "hotkeyConflict": MessageLookupByLibrary.simpleMessage("단축키 충돌"),
    "hotkeyManagement": MessageLookupByLibrary.simpleMessage("단축키 관리"),
    "hotkeyManagementDesc": MessageLookupByLibrary.simpleMessage(
      "키보드로 애플리케이션을 제어합니다",
    ),
    "hours": MessageLookupByLibrary.simpleMessage("시간"),
    "hoursAgo": m10,
    "hoursCount": m11,
    "icon": MessageLookupByLibrary.simpleMessage("아이콘"),
    "iconRecords": MessageLookupByLibrary.simpleMessage("아이콘 기록"),
    "iconStyle": MessageLookupByLibrary.simpleMessage("아이콘 스타일"),
    "iconUrl": MessageLookupByLibrary.simpleMessage("아이콘 URL"),
    "ignoreBatteryOptimization": MessageLookupByLibrary.simpleMessage(
      "배터리 최적화 무시",
    ),
    "import": MessageLookupByLibrary.simpleMessage("가져오기"),
    "importFile": MessageLookupByLibrary.simpleMessage("파일에서 가져오기"),
    "importFromURL": MessageLookupByLibrary.simpleMessage("URL에서 가져오기"),
    "importUrl": MessageLookupByLibrary.simpleMessage("URL에서 가져오기"),
    "includeAllProxies": MessageLookupByLibrary.simpleMessage("모든 프록시 포함"),
    "includeAllProxiesTip": MessageLookupByLibrary.simpleMessage(
      "프록시 그룹을 포함하지 않는 모든 프록시를 가져오며, 아래에 추가 프록시 그룹을 더할 수 있습니다",
    ),
    "includeAllProxyProviders": MessageLookupByLibrary.simpleMessage(
      "모든 프록시 제공자 포함",
    ),
    "includeAllProxyProvidersTip": MessageLookupByLibrary.simpleMessage(
      "활성화하면 가져온 프록시 제공자를 재정의합니다",
    ),
    "infiniteTime": MessageLookupByLibrary.simpleMessage("영구 적용"),
    "init": MessageLookupByLibrary.simpleMessage("초기화"),
    "inputCorrectHotkey": MessageLookupByLibrary.simpleMessage(
      "올바른 단축키를 입력해 주세요",
    ),
    "inputProxyGroupName": MessageLookupByLibrary.simpleMessage("프록시 그룹 이름 입력"),
    "inputRuleContent": MessageLookupByLibrary.simpleMessage("규칙 내용 입력"),
    "intelligentSelected": MessageLookupByLibrary.simpleMessage("지능형 선택"),
    "internet": MessageLookupByLibrary.simpleMessage("인터넷"),
    "interval": MessageLookupByLibrary.simpleMessage("간격"),
    "intranetIP": MessageLookupByLibrary.simpleMessage("인트라넷 IP"),
    "invalidBackupFile": MessageLookupByLibrary.simpleMessage("잘못된 백업 파일입니다"),
    "invalidPolicy": m12,
    "invalidProxy": m13,
    "invalidProxyProvider": m14,
    "invalidSubRule": m15,
    "ipcidr": MessageLookupByLibrary.simpleMessage("IP/서브넷"),
    "ipv6Desc": MessageLookupByLibrary.simpleMessage(
      "활성화하면 IPv6 트래픽을 수신할 수 있습니다",
    ),
    "ipv6InboundDesc": MessageLookupByLibrary.simpleMessage("IPv6 인바운드를 허용합니다"),
    "ja": MessageLookupByLibrary.simpleMessage("일본어"),
    "justNow": MessageLookupByLibrary.simpleMessage("방금 전"),
    "keepAliveIntervalDesc": MessageLookupByLibrary.simpleMessage(
      "TCP Keep-Alive 간격",
    ),
    "key": MessageLookupByLibrary.simpleMessage("키"),
    "ko": MessageLookupByLibrary.simpleMessage("한국어"),
    "language": MessageLookupByLibrary.simpleMessage("언어"),
    "layout": MessageLookupByLibrary.simpleMessage("레이아웃"),
    "light": MessageLookupByLibrary.simpleMessage("라이트"),
    "list": MessageLookupByLibrary.simpleMessage("목록"),
    "listen": MessageLookupByLibrary.simpleMessage("리슨"),
    "loadTest": MessageLookupByLibrary.simpleMessage("부하 테스트"),
    "loading": MessageLookupByLibrary.simpleMessage("로딩 중..."),
    "local": MessageLookupByLibrary.simpleMessage("로컬"),
    "localBackupDesc": MessageLookupByLibrary.simpleMessage(
      "로컬 데이터를 로컬에 백업합니다",
    ),
    "locationPermission": MessageLookupByLibrary.simpleMessage("위치 권한"),
    "locationPermissionDeniedMessage": MessageLookupByLibrary.simpleMessage(
      "위치 권한이 거부되어 현재 Wi-Fi 이름을 가져올 수 없습니다. 시스템 설정에서 위치 권한을 직접 열어 주세요.",
    ),
    "locationPermissionDesc": MessageLookupByLibrary.simpleMessage(
      "시스템 요구 사항에 따라 Wi-Fi 이름을 가져오려면 위치 권한을 허용해야 합니다.",
    ),
    "locationPermissionGuide": m16,
    "locationPermissionRequired": MessageLookupByLibrary.simpleMessage(
      "위치 권한 필요",
    ),
    "log": MessageLookupByLibrary.simpleMessage("로그"),
    "logLevel": MessageLookupByLibrary.simpleMessage("로그 레벨"),
    "logcat": MessageLookupByLibrary.simpleMessage("로그캣"),
    "logcatDesc": MessageLookupByLibrary.simpleMessage("비활성화하면 로그 항목이 숨겨집니다"),
    "logs": MessageLookupByLibrary.simpleMessage("로그"),
    "logsDesc": MessageLookupByLibrary.simpleMessage("로그 캡처 기록"),
    "logsTest": MessageLookupByLibrary.simpleMessage("로그 테스트"),
    "loopback": MessageLookupByLibrary.simpleMessage("Loopback 잠금 해제 도구"),
    "loopbackDesc": MessageLookupByLibrary.simpleMessage(
      "UWP Loopback 잠금 해제에 사용됩니다",
    ),
    "loose": MessageLookupByLibrary.simpleMessage("넓게"),
    "matchSourceIp": MessageLookupByLibrary.simpleMessage("소스 IP 일치"),
    "maxFailedTimes": MessageLookupByLibrary.simpleMessage("최대 실패 횟수"),
    "memoryInfo": MessageLookupByLibrary.simpleMessage("메모리 정보"),
    "messageTest": MessageLookupByLibrary.simpleMessage("메시지 테스트"),
    "messageTestTip": MessageLookupByLibrary.simpleMessage("이것은 메시지입니다."),
    "min": MessageLookupByLibrary.simpleMessage("최소화"),
    "minimizeOnExit": MessageLookupByLibrary.simpleMessage("종료 시 최소화"),
    "minimizeOnExitDesc": MessageLookupByLibrary.simpleMessage(
      "기본 시스템 종료 동작을 변경합니다",
    ),
    "minutesAgo": m17,
    "mixedPort": MessageLookupByLibrary.simpleMessage("Mixed 포트"),
    "mode": MessageLookupByLibrary.simpleMessage("모드"),
    "monochromeScheme": MessageLookupByLibrary.simpleMessage("단색"),
    "monthsAgo": m18,
    "more": MessageLookupByLibrary.simpleMessage("더 보기"),
    "name": MessageLookupByLibrary.simpleMessage("이름"),
    "nameserver": MessageLookupByLibrary.simpleMessage("네임서버"),
    "nameserverDesc": MessageLookupByLibrary.simpleMessage("도메인 확인용"),
    "nameserverPolicy": MessageLookupByLibrary.simpleMessage("네임서버 정책"),
    "nameserverPolicyDesc": MessageLookupByLibrary.simpleMessage(
      "해당하는 네임서버 정책을 지정합니다",
    ),
    "network": MessageLookupByLibrary.simpleMessage("네트워크"),
    "networkDesc": MessageLookupByLibrary.simpleMessage("네트워크 관련 설정을 수정합니다"),
    "networkDetection": MessageLookupByLibrary.simpleMessage("네트워크 감지"),
    "networkException": MessageLookupByLibrary.simpleMessage(
      "네트워크 오류입니다. 연결을 확인한 후 다시 시도해 주세요",
    ),
    "networkSpeed": MessageLookupByLibrary.simpleMessage("네트워크 속도"),
    "networkType": MessageLookupByLibrary.simpleMessage("네트워크 유형"),
    "neutralScheme": MessageLookupByLibrary.simpleMessage("중립"),
    "noData": MessageLookupByLibrary.simpleMessage("데이터 없음"),
    "noHotKey": MessageLookupByLibrary.simpleMessage("단축키 없음"),
    "noInfo": MessageLookupByLibrary.simpleMessage("정보 없음"),
    "noLongerRemind": MessageLookupByLibrary.simpleMessage("다시 알리지 않기"),
    "noNetwork": MessageLookupByLibrary.simpleMessage("네트워크 없음"),
    "noNetworkApp": MessageLookupByLibrary.simpleMessage("네트워크 없는 앱"),
    "noRecords": MessageLookupByLibrary.simpleMessage("기록 없음"),
    "noResolve": MessageLookupByLibrary.simpleMessage("IP 확인 안 함"),
    "noResolveHostname": MessageLookupByLibrary.simpleMessage("호스트 이름 확인 안 함"),
    "none": MessageLookupByLibrary.simpleMessage("없음"),
    "notSelectedTip": MessageLookupByLibrary.simpleMessage(
      "현재 프록시 그룹은 선택할 수 없습니다.",
    ),
    "nullProfileDesc": MessageLookupByLibrary.simpleMessage(
      "프로필이 없습니다. 프로필을 추가해 주세요",
    ),
    "nullTip": m19,
    "numberTip": m20,
    "onDemand": MessageLookupByLibrary.simpleMessage("온디맨드"),
    "onDemandDesc": MessageLookupByLibrary.simpleMessage(
      "특정 상황에 대한 프로그램 실행 상태를 설정합니다",
    ),
    "onlyIcon": MessageLookupByLibrary.simpleMessage("아이콘"),
    "onlyStatisticsProxy": MessageLookupByLibrary.simpleMessage("프록시만 통계"),
    "onlyStatisticsProxyDesc": MessageLookupByLibrary.simpleMessage(
      "활성화하면 프록시 트래픽만 통계에 반영합니다",
    ),
    "optional": MessageLookupByLibrary.simpleMessage("선택 사항"),
    "options": MessageLookupByLibrary.simpleMessage("옵션"),
    "other": MessageLookupByLibrary.simpleMessage("기타"),
    "otherContributors": MessageLookupByLibrary.simpleMessage("기타 기여자"),
    "outboundMode": MessageLookupByLibrary.simpleMessage("아웃바운드 모드"),
    "override": MessageLookupByLibrary.simpleMessage("재정의"),
    "overrideDns": MessageLookupByLibrary.simpleMessage("DNS 재정의"),
    "overrideDnsDesc": MessageLookupByLibrary.simpleMessage(
      "활성화하면 프로필의 DNS 옵션을 재정의합니다",
    ),
    "overrideMode": MessageLookupByLibrary.simpleMessage("재정의 모드"),
    "overrideScript": MessageLookupByLibrary.simpleMessage("재정의 스크립트"),
    "overwriteTypeCustom": MessageLookupByLibrary.simpleMessage("사용자 지정"),
    "overwriteTypeCustomDesc": MessageLookupByLibrary.simpleMessage(
      "사용자 지정 모드로, 프록시 그룹과 규칙을 완전히 직접 구성합니다",
    ),
    "palette": MessageLookupByLibrary.simpleMessage("팔레트"),
    "password": MessageLookupByLibrary.simpleMessage("비밀번호"),
    "paste": MessageLookupByLibrary.simpleMessage("붙여넣기"),
    "pleaseBindWebDAV": MessageLookupByLibrary.simpleMessage("WebDAV를 연결해 주세요"),
    "pleaseEnterScriptName": MessageLookupByLibrary.simpleMessage(
      "스크립트 이름을 입력해 주세요",
    ),
    "pleaseInputAdminPassword": MessageLookupByLibrary.simpleMessage(
      "관리자 비밀번호를 입력해 주세요",
    ),
    "pleaseUploadValidQrcode": MessageLookupByLibrary.simpleMessage(
      "올바른 QR 코드를 업로드해 주세요",
    ),
    "port": MessageLookupByLibrary.simpleMessage("포트"),
    "portConflictTip": MessageLookupByLibrary.simpleMessage("다른 포트를 입력해 주세요"),
    "portTip": m21,
    "preferH3Desc": MessageLookupByLibrary.simpleMessage(
      "DOH의 http/3 사용을 우선합니다",
    ),
    "prerequisites": MessageLookupByLibrary.simpleMessage("사전 요구 사항"),
    "pressKeyboard": MessageLookupByLibrary.simpleMessage("키보드를 눌러 주세요."),
    "preview": MessageLookupByLibrary.simpleMessage("미리보기"),
    "process": MessageLookupByLibrary.simpleMessage("프로세스"),
    "profile": MessageLookupByLibrary.simpleMessage("프로필"),
    "profileAutoUpdateIntervalInvalidValidationDesc":
        MessageLookupByLibrary.simpleMessage("올바른 간격 시간 형식을 입력해 주세요"),
    "profileAutoUpdateIntervalNullValidationDesc":
        MessageLookupByLibrary.simpleMessage("자동 업데이트 간격 시간을 입력해 주세요"),
    "profileHasUpdate": MessageLookupByLibrary.simpleMessage(
      "프로필이 수정되었습니다. 자동 업데이트를 비활성화하시겠습니까?",
    ),
    "profileNameNullValidationDesc": MessageLookupByLibrary.simpleMessage(
      "프로필 이름을 입력해 주세요",
    ),
    "profileUrlInvalidValidationDesc": MessageLookupByLibrary.simpleMessage(
      "올바른 프로필 URL을 입력해 주세요",
    ),
    "profileUrlNullValidationDesc": MessageLookupByLibrary.simpleMessage(
      "프로필 URL을 입력해 주세요",
    ),
    "profiles": MessageLookupByLibrary.simpleMessage("프로필"),
    "profilesSort": MessageLookupByLibrary.simpleMessage("프로필 정렬"),
    "project": MessageLookupByLibrary.simpleMessage("프로젝트"),
    "providers": MessageLookupByLibrary.simpleMessage("제공자"),
    "proxies": MessageLookupByLibrary.simpleMessage("프록시"),
    "proxiesEmpty": MessageLookupByLibrary.simpleMessage("프록시가 비어 있습니다"),
    "proxyChains": MessageLookupByLibrary.simpleMessage("프록시 체인"),
    "proxyDetectedAbnormal": MessageLookupByLibrary.simpleMessage(
      "선택한 프록시가 비정상적인 것으로 감지되었습니다",
    ),
    "proxyFilter": MessageLookupByLibrary.simpleMessage("프록시 필터"),
    "proxyGroup": MessageLookupByLibrary.simpleMessage("프록시 그룹"),
    "proxyGroupDetectedAbnormal": MessageLookupByLibrary.simpleMessage(
      "현재 프록시 그룹이 비정상적인 것으로 감지되었습니다",
    ),
    "proxyGroupEmpty": MessageLookupByLibrary.simpleMessage("프록시 그룹이 비어 있습니다"),
    "proxyGroupNameDuplicate": MessageLookupByLibrary.simpleMessage(
      "프록시 그룹 이름이 중복되었습니다",
    ),
    "proxyGroupNameEmpty": MessageLookupByLibrary.simpleMessage(
      "프록시 그룹 이름은 비워둘 수 없습니다",
    ),
    "proxyNameserver": MessageLookupByLibrary.simpleMessage("프록시 네임서버"),
    "proxyNameserverDesc": MessageLookupByLibrary.simpleMessage(
      "프록시 노드를 확인하기 위한 도메인",
    ),
    "proxyPort": MessageLookupByLibrary.simpleMessage("프록시 포트"),
    "proxyProviderDetectedAbnormal": MessageLookupByLibrary.simpleMessage(
      "선택한 프록시 제공자가 비정상적인 것으로 감지되었습니다",
    ),
    "proxyProviders": MessageLookupByLibrary.simpleMessage("프록시 제공자"),
    "proxyProvidersEmpty": MessageLookupByLibrary.simpleMessage(
      "프록시 제공자가 비어 있습니다",
    ),
    "proxyProvidersNotEmpty": MessageLookupByLibrary.simpleMessage(
      "프록시 제공자는 비워둘 수 없습니다",
    ),
    "proxyType": MessageLookupByLibrary.simpleMessage("프록시 유형"),
    "pruneCache": MessageLookupByLibrary.simpleMessage("캐시 정리"),
    "pureBlackMode": MessageLookupByLibrary.simpleMessage("완전 검정 모드"),
    "qrcode": MessageLookupByLibrary.simpleMessage("QR 코드"),
    "qrcodeDesc": MessageLookupByLibrary.simpleMessage(
      "QR 코드를 스캔하여 프로필을 가져옵니다",
    ),
    "quickFill": MessageLookupByLibrary.simpleMessage("빠른 채우기"),
    "rainbowScheme": MessageLookupByLibrary.simpleMessage("레인보우"),
    "redirPort": MessageLookupByLibrary.simpleMessage("Redir 포트"),
    "redo": MessageLookupByLibrary.simpleMessage("다시 실행"),
    "remote": MessageLookupByLibrary.simpleMessage("원격"),
    "remoteBackupDesc": MessageLookupByLibrary.simpleMessage(
      "로컬 데이터를 WebDAV에 백업합니다",
    ),
    "remoteDestination": MessageLookupByLibrary.simpleMessage("원격 대상"),
    "remove": MessageLookupByLibrary.simpleMessage("제거"),
    "rename": MessageLookupByLibrary.simpleMessage("이름 변경"),
    "request": MessageLookupByLibrary.simpleMessage("요청"),
    "requests": MessageLookupByLibrary.simpleMessage("요청"),
    "requestsDesc": MessageLookupByLibrary.simpleMessage("최근 요청 기록을 확인합니다"),
    "reset": MessageLookupByLibrary.simpleMessage("초기화"),
    "resetPageChangesTip": MessageLookupByLibrary.simpleMessage(
      "현재 페이지에 변경 사항이 있습니다. 초기화하시겠습니까?",
    ),
    "resetTip": MessageLookupByLibrary.simpleMessage("초기화하시겠습니까"),
    "resources": MessageLookupByLibrary.simpleMessage("리소스"),
    "resourcesDesc": MessageLookupByLibrary.simpleMessage("외부 리소스 관련 정보"),
    "respectRules": MessageLookupByLibrary.simpleMessage("규칙 준수"),
    "respectRulesDesc": MessageLookupByLibrary.simpleMessage(
      "규칙에 따라 DNS 연결을 수행하며, proxy-server-nameserver 설정이 필요합니다",
    ),
    "restart": MessageLookupByLibrary.simpleMessage("재시작"),
    "restartCoreTip": MessageLookupByLibrary.simpleMessage("코어를 재시작하시겠습니까?"),
    "restore": MessageLookupByLibrary.simpleMessage("복원"),
    "restoreAllData": MessageLookupByLibrary.simpleMessage("모든 데이터 복원"),
    "restoreException": MessageLookupByLibrary.simpleMessage("복원 예외"),
    "restoreFromFileDesc": MessageLookupByLibrary.simpleMessage(
      "파일을 통해 데이터를 복원합니다",
    ),
    "restoreFromWebDAVDesc": MessageLookupByLibrary.simpleMessage(
      "WebDAV를 통해 데이터를 복원합니다",
    ),
    "restoreOnlyConfig": MessageLookupByLibrary.simpleMessage("설정 파일만 복원"),
    "restoreStrategy": MessageLookupByLibrary.simpleMessage("복원 전략"),
    "restoreStrategy_compatible": MessageLookupByLibrary.simpleMessage("호환"),
    "restoreStrategy_override": MessageLookupByLibrary.simpleMessage("덮어쓰기"),
    "restoreSuccess": MessageLookupByLibrary.simpleMessage("복원 성공"),
    "routeAddress": MessageLookupByLibrary.simpleMessage("라우트 주소"),
    "routeAddressDesc": MessageLookupByLibrary.simpleMessage(
      "리스닝 라우트 주소를 설정합니다",
    ),
    "routeMode": MessageLookupByLibrary.simpleMessage("라우트 모드"),
    "routeMode_bypassPrivate": MessageLookupByLibrary.simpleMessage(
      "사설 라우트 주소 우회",
    ),
    "routeMode_config": MessageLookupByLibrary.simpleMessage("설정 사용"),
    "ru": MessageLookupByLibrary.simpleMessage("러시아어"),
    "rule": MessageLookupByLibrary.simpleMessage("규칙"),
    "ruleActionAndDesc": MessageLookupByLibrary.simpleMessage("논리 규칙 AND"),
    "ruleActionDomainDesc": MessageLookupByLibrary.simpleMessage("전체 도메인 일치"),
    "ruleActionDomainKeywordDesc": MessageLookupByLibrary.simpleMessage(
      "도메인 키워드 일치",
    ),
    "ruleActionDomainRegexDesc": MessageLookupByLibrary.simpleMessage(
      "와일드카드 일치, * 및 ? 와일드카드만 지원합니다",
    ),
    "ruleActionDomainSuffixDesc": MessageLookupByLibrary.simpleMessage(
      "도메인 접미사 일치",
    ),
    "ruleActionDscpDesc": MessageLookupByLibrary.simpleMessage(
      "DSCP 마크 일치(Tproxy UDP 인바운드 전용)",
    ),
    "ruleActionDstPortDesc": MessageLookupByLibrary.simpleMessage(
      "요청 대상 포트 범위 일치",
    ),
    "ruleActionGeoipDesc": MessageLookupByLibrary.simpleMessage("IP의 국가 코드 일치"),
    "ruleActionGeositeDesc": MessageLookupByLibrary.simpleMessage(
      "Geosite 내 도메인 일치",
    ),
    "ruleActionInNameDesc": MessageLookupByLibrary.simpleMessage("인바운드 이름 일치"),
    "ruleActionInPortDesc": MessageLookupByLibrary.simpleMessage("인바운드 포트 일치"),
    "ruleActionInTypeDesc": MessageLookupByLibrary.simpleMessage("인바운드 유형 일치"),
    "ruleActionInUserDesc": MessageLookupByLibrary.simpleMessage(
      "인바운드 사용자 이름 일치, /로 구분된 여러 사용자 이름을 지원합니다",
    ),
    "ruleActionIpAsnDesc": MessageLookupByLibrary.simpleMessage("IP의 ASN 일치"),
    "ruleActionIpCidr6Desc": MessageLookupByLibrary.simpleMessage(
      "IP 주소 범위 일치, IP-CIDR6은 별칭일 뿐입니다",
    ),
    "ruleActionIpCidrDesc": MessageLookupByLibrary.simpleMessage("IP 주소 범위 일치"),
    "ruleActionIpSuffixDesc": MessageLookupByLibrary.simpleMessage(
      "IP 접미사 범위 일치",
    ),
    "ruleActionMatchDesc": MessageLookupByLibrary.simpleMessage(
      "모든 요청과 일치, 조건이 필요 없습니다",
    ),
    "ruleActionNetworkDesc": MessageLookupByLibrary.simpleMessage(
      "TCP 또는 UDP 일치",
    ),
    "ruleActionNotDesc": MessageLookupByLibrary.simpleMessage("논리 규칙 NOT"),
    "ruleActionOrDesc": MessageLookupByLibrary.simpleMessage("논리 규칙 OR"),
    "ruleActionProcessNameDesc": MessageLookupByLibrary.simpleMessage(
      "프로세스 이름으로 일치, Android에서는 패키지 이름과 일치합니다",
    ),
    "ruleActionProcessNameRegexDesc": MessageLookupByLibrary.simpleMessage(
      "프로세스 이름 정규식으로 일치, Android에서는 패키지 이름과 일치합니다",
    ),
    "ruleActionProcessPathDesc": MessageLookupByLibrary.simpleMessage(
      "전체 프로세스 경로로 일치",
    ),
    "ruleActionProcessPathRegexDesc": MessageLookupByLibrary.simpleMessage(
      "프로세스 경로 정규식으로 일치",
    ),
    "ruleActionRuleSetDesc": MessageLookupByLibrary.simpleMessage(
      "규칙 세트 참조, rule-providers 설정이 필요합니다",
    ),
    "ruleActionSrcGeoipDesc": MessageLookupByLibrary.simpleMessage(
      "소스 IP의 국가 코드 일치",
    ),
    "ruleActionSrcIpAsnDesc": MessageLookupByLibrary.simpleMessage(
      "소스 IP의 ASN 일치",
    ),
    "ruleActionSrcIpCidrDesc": MessageLookupByLibrary.simpleMessage(
      "소스 IP 주소 범위 일치",
    ),
    "ruleActionSrcIpSuffixDesc": MessageLookupByLibrary.simpleMessage(
      "소스 IP 접미사 범위 일치",
    ),
    "ruleActionSrcPortDesc": MessageLookupByLibrary.simpleMessage(
      "요청 소스 포트 범위 일치",
    ),
    "ruleActionSubRuleDesc": MessageLookupByLibrary.simpleMessage(
      "하위 규칙 일치, 괄호 사용에 주의하세요",
    ),
    "ruleActionUidDesc": MessageLookupByLibrary.simpleMessage(
      "Linux USER ID 일치",
    ),
    "ruleEmpty": MessageLookupByLibrary.simpleMessage("규칙이 비어 있습니다"),
    "ruleName": MessageLookupByLibrary.simpleMessage("규칙 이름"),
    "ruleProviders": MessageLookupByLibrary.simpleMessage("규칙 제공자"),
    "ruleSet": MessageLookupByLibrary.simpleMessage("규칙 세트"),
    "ruleTarget": MessageLookupByLibrary.simpleMessage("규칙 대상"),
    "save": MessageLookupByLibrary.simpleMessage("저장"),
    "saveChanges": MessageLookupByLibrary.simpleMessage("변경 사항을 저장하시겠습니까?"),
    "script": MessageLookupByLibrary.simpleMessage("스크립트"),
    "scriptModeDesc": MessageLookupByLibrary.simpleMessage(
      "스크립트 모드로, 외부 확장 스크립트를 사용하여 원클릭 설정 재정의 기능을 제공합니다",
    ),
    "search": MessageLookupByLibrary.simpleMessage("검색"),
    "seconds": MessageLookupByLibrary.simpleMessage("초"),
    "secondsCount": m22,
    "selectAll": MessageLookupByLibrary.simpleMessage("전체 선택"),
    "selectProxies": MessageLookupByLibrary.simpleMessage("프록시 선택"),
    "selectProxyProviders": MessageLookupByLibrary.simpleMessage("프록시 제공자 선택"),
    "selectRuleSet": MessageLookupByLibrary.simpleMessage("규칙 세트를 선택해 주세요"),
    "selectSplitStrategy": MessageLookupByLibrary.simpleMessage(
      "분할 전략을 선택해 주세요",
    ),
    "selectSubRule": MessageLookupByLibrary.simpleMessage("하위 규칙을 선택해 주세요"),
    "selected": MessageLookupByLibrary.simpleMessage("선택됨"),
    "selectedCountTitle": m23,
    "settings": MessageLookupByLibrary.simpleMessage("설정"),
    "show": MessageLookupByLibrary.simpleMessage("표시"),
    "shrink": MessageLookupByLibrary.simpleMessage("축소"),
    "silentLaunch": MessageLookupByLibrary.simpleMessage("조용히 시작"),
    "silentLaunchDesc": MessageLookupByLibrary.simpleMessage("백그라운드에서 시작합니다"),
    "size": MessageLookupByLibrary.simpleMessage("크기"),
    "socksPort": MessageLookupByLibrary.simpleMessage("Socks 포트"),
    "sort": MessageLookupByLibrary.simpleMessage("정렬"),
    "source": MessageLookupByLibrary.simpleMessage("소스"),
    "sourceIp": MessageLookupByLibrary.simpleMessage("소스 IP"),
    "specialProxy": MessageLookupByLibrary.simpleMessage("특수 프록시"),
    "specialRules": MessageLookupByLibrary.simpleMessage("특수 규칙"),
    "speedStatistics": MessageLookupByLibrary.simpleMessage("속도 통계"),
    "splitStrategy": MessageLookupByLibrary.simpleMessage("분할 전략"),
    "splitStrategyNotEmpty": MessageLookupByLibrary.simpleMessage(
      "분할 전략은 비워둘 수 없습니다",
    ),
    "ssidsEmpty": MessageLookupByLibrary.simpleMessage("SSID가 비어 있습니다"),
    "stackMode": MessageLookupByLibrary.simpleMessage("스택 모드"),
    "standard": MessageLookupByLibrary.simpleMessage("표준"),
    "standardModeDesc": MessageLookupByLibrary.simpleMessage(
      "표준 모드로, 기본 설정을 재정의하고 간단한 규칙 추가 기능을 제공합니다",
    ),
    "start": MessageLookupByLibrary.simpleMessage("시작"),
    "startVpn": MessageLookupByLibrary.simpleMessage("VPN 시작 중..."),
    "status": MessageLookupByLibrary.simpleMessage("상태"),
    "statusDesc": MessageLookupByLibrary.simpleMessage("비활성화하면 시스템 DNS를 사용합니다"),
    "stop": MessageLookupByLibrary.simpleMessage("중지"),
    "stopVpn": MessageLookupByLibrary.simpleMessage("VPN 중지 중..."),
    "style": MessageLookupByLibrary.simpleMessage("스타일"),
    "subRule": MessageLookupByLibrary.simpleMessage("하위 규칙"),
    "subRuleEmpty": MessageLookupByLibrary.simpleMessage("하위 규칙이 비어 있습니다"),
    "subRuleNotEmpty": MessageLookupByLibrary.simpleMessage(
      "하위 규칙은 비워둘 수 없습니다",
    ),
    "submit": MessageLookupByLibrary.simpleMessage("제출"),
    "suspended": MessageLookupByLibrary.simpleMessage("일시 중단됨..."),
    "sync": MessageLookupByLibrary.simpleMessage("동기화"),
    "system": MessageLookupByLibrary.simpleMessage("시스템"),
    "systemApp": MessageLookupByLibrary.simpleMessage("시스템 앱"),
    "systemProxy": MessageLookupByLibrary.simpleMessage("시스템 프록시"),
    "systemProxyDesc": MessageLookupByLibrary.simpleMessage(
      "VpnService에 HTTP 프록시를 연결합니다",
    ),
    "tab": MessageLookupByLibrary.simpleMessage("탭"),
    "tabAnimation": MessageLookupByLibrary.simpleMessage("탭 애니메이션"),
    "tabAnimationDesc": MessageLookupByLibrary.simpleMessage("모바일 화면에서만 적용됩니다"),
    "tapToAuthorize": MessageLookupByLibrary.simpleMessage("탭하여 승인"),
    "tcpConcurrent": MessageLookupByLibrary.simpleMessage("TCP 동시 연결"),
    "tcpConcurrentDesc": MessageLookupByLibrary.simpleMessage(
      "활성화하면 TCP 동시 연결을 허용합니다",
    ),
    "testInterval": MessageLookupByLibrary.simpleMessage("테스트 간격"),
    "testUrl": MessageLookupByLibrary.simpleMessage("테스트 URL"),
    "testWhenUsed": MessageLookupByLibrary.simpleMessage("사용 시 테스트"),
    "textScale": MessageLookupByLibrary.simpleMessage("글자 크기"),
    "theme": MessageLookupByLibrary.simpleMessage("테마"),
    "themeColor": MessageLookupByLibrary.simpleMessage("테마 색상"),
    "themeDesc": MessageLookupByLibrary.simpleMessage("다크 모드 설정, 색상 조정"),
    "themeMode": MessageLookupByLibrary.simpleMessage("테마 모드"),
    "tight": MessageLookupByLibrary.simpleMessage("좁게"),
    "time": MessageLookupByLibrary.simpleMessage("시간"),
    "timeout": MessageLookupByLibrary.simpleMessage("제한 시간"),
    "tip": MessageLookupByLibrary.simpleMessage("알림"),
    "toggle": MessageLookupByLibrary.simpleMessage("전환"),
    "tonalSpotScheme": MessageLookupByLibrary.simpleMessage("토널 스팟"),
    "tools": MessageLookupByLibrary.simpleMessage("도구"),
    "tproxyPort": MessageLookupByLibrary.simpleMessage("Tproxy 포트"),
    "trafficUsage": MessageLookupByLibrary.simpleMessage("트래픽 사용량"),
    "tun": MessageLookupByLibrary.simpleMessage("TUN"),
    "tunDesc": MessageLookupByLibrary.simpleMessage("관리자 모드에서만 유효합니다"),
    "turnOff": MessageLookupByLibrary.simpleMessage("끄기"),
    "turnOn": MessageLookupByLibrary.simpleMessage("켜기"),
    "undo": MessageLookupByLibrary.simpleMessage("실행 취소"),
    "unifiedDelay": MessageLookupByLibrary.simpleMessage("통합 지연 시간"),
    "unifiedDelayDesc": MessageLookupByLibrary.simpleMessage(
      "핸드셰이크 등 추가 지연 시간을 제거합니다",
    ),
    "unknown": MessageLookupByLibrary.simpleMessage("알 수 없음"),
    "unknownNetworkError": MessageLookupByLibrary.simpleMessage(
      "알 수 없는 네트워크 오류",
    ),
    "unnamed": MessageLookupByLibrary.simpleMessage("이름 없음"),
    "update": MessageLookupByLibrary.simpleMessage("업데이트"),
    "upload": MessageLookupByLibrary.simpleMessage("업로드"),
    "url": MessageLookupByLibrary.simpleMessage("URL"),
    "urlDesc": MessageLookupByLibrary.simpleMessage("URL을 통해 프로필을 가져옵니다"),
    "urlTip": m24,
    "useHosts": MessageLookupByLibrary.simpleMessage("Hosts 사용"),
    "useSystemHosts": MessageLookupByLibrary.simpleMessage("시스템 Hosts 사용"),
    "userAgent": MessageLookupByLibrary.simpleMessage("User-Agent"),
    "value": MessageLookupByLibrary.simpleMessage("값"),
    "vibrantScheme": MessageLookupByLibrary.simpleMessage("선명함"),
    "view": MessageLookupByLibrary.simpleMessage("보기"),
    "vpnConfigChangeDetected": MessageLookupByLibrary.simpleMessage(
      "VPN 설정 변경이 감지되었습니다",
    ),
    "vpnEnableDesc": MessageLookupByLibrary.simpleMessage(
      "VpnService를 통해 모든 시스템 트래픽을 자동으로 라우팅합니다",
    ),
    "vpnTip": MessageLookupByLibrary.simpleMessage("VPN을 재시작해야 변경 사항이 적용됩니다"),
    "webDAVConfiguration": MessageLookupByLibrary.simpleMessage("WebDAV 설정"),
    "whitelistMode": MessageLookupByLibrary.simpleMessage("화이트리스트 모드"),
    "yearsAgo": m25,
    "zh_CN": MessageLookupByLibrary.simpleMessage("중국어 간체"),
    "zh_TW": MessageLookupByLibrary.simpleMessage("중국어 번체"),
  };
}
