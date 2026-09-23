import 'dart:async';
import 'dart:io';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/common/dav_client.dart';
import 'package:fl_clash/design/colors/panorama_colors.dart';
import 'package:fl_clash/design/icons/panorama_icons.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/action.dart';
import 'package:fl_clash/providers/app.dart';
import 'package:fl_clash/providers/config.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/widgets/builder.dart';
import 'package:fl_clash/widgets/dialog.dart';
import 'package:fl_clash/widgets/fade_box.dart';
import 'package:fl_clash/widgets/glass.dart';
import 'package:fl_clash/widgets/input.dart';
import 'package:fl_clash/widgets/list.dart';
import 'package:fl_clash/widgets/scaffold.dart';
import 'package:fl_clash/widgets/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class BackupAndRestore extends ConsumerStatefulWidget {
  const BackupAndRestore({super.key});

  @override
  ConsumerState<BackupAndRestore> createState() => _BackupAndRestoreState();
}

class _BackupAndRestoreState extends ConsumerState<BackupAndRestore>
    with UniqueKeyStateMixin {
  final _davConnection = DAVConnectionController();

  @override
  void initState() {
    super.initState();
    ref.listenManual(davSettingProvider, (_, _) {
      _updateDAVClient();
    }, fireImmediately: true);
  }

  void _updateDAVClient() {
    unawaited(_davConnection.update(ref.read(davSettingProvider)));
  }

  @override
  void dispose() {
    _davConnection.dispose();
    super.dispose();
  }

  Future<void> _showAddWebDAV(DAVProps? dav) async {
    await globalState.showCommonDialog<String>(
      child: WebDAVFormDialog(dav: dav?.copyWith()),
    );
  }

  Future<void> _backupOnWebDAV() async {
    final appLocalizations = context.appLocalizations;
    final res = await globalState.loadingRun<bool>(
      () async {
        final client = _davConnection.client;
        if (client == null) {
          return false;
        }
        final path = await globalState.container
            .read(backupActionProvider.notifier)
            .backup();
        if (path.isEmpty) {
          return false;
        }
        final history = ref.read(backupHistorySettingProvider.notifier);
        try {
          final ok = await client.backup(path);
          if (ok) history.recordSuccess(BackupEvent.remoteBackup);
          return ok;
        } catch (e) {
          history.recordRemoteError(e);
          rethrow;
        }
      },
      tag: LoadingTag.backup_restore,
      title: appLocalizations.backup,
    );
    if (res != true) return;
    globalState.showMessage(
      title: appLocalizations.backup,
      message: TextSpan(text: appLocalizations.backupSuccess),
    );
  }

  Future<void> _restoreOnWebDAV(RestoreOption option) async {
    final appLocalizations = context.appLocalizations;
    final res = await globalState.loadingRun<bool>(
      () async {
        final client = _davConnection.client;
        if (client == null) {
          return false;
        }
        final history = ref.read(backupHistorySettingProvider.notifier);
        try {
          await client.restore();
        } catch (e) {
          history.recordRemoteError(e);
          rethrow;
        }
        await globalState.container
            .read(backupActionProvider.notifier)
            .restore(option);
        history.recordSuccess(BackupEvent.remoteRestore);
        return true;
      },
      tag: LoadingTag.backup_restore,
      title: appLocalizations.restore,
    );
    if (res != true) return;
    globalState.showMessage(
      title: appLocalizations.restore,
      message: TextSpan(text: appLocalizations.restoreSuccess),
    );
  }

  Future<void> _handleRestoreOnWebDAV() async {
    final restoreOption = await globalState.showCommonDialog<RestoreOption>(
      child: const RestoreOptionsDialog(),
    );
    if (restoreOption == null || !context.mounted) return;
    _restoreOnWebDAV(restoreOption);
  }

  Future<void> _backupOnLocal() async {
    final appLocalizations = context.appLocalizations;
    final res = await globalState.loadingRun<bool>(
      () async {
        final path = await globalState.container
            .read(backupActionProvider.notifier)
            .backup();
        if (path.isEmpty) {
          return false;
        }
        final value = await picker.saveFileWithPath(
          utils.getBackupFileName(),
          path,
        );
        if (value == null) return false;
        ref
            .read(backupHistorySettingProvider.notifier)
            .recordSuccess(BackupEvent.localBackup);
        return true;
      },
      title: appLocalizations.backup,
      tag: LoadingTag.backup_restore,
    );
    if (res != true) return;
    globalState.showMessage(
      title: appLocalizations.backup,
      message: TextSpan(text: appLocalizations.backupSuccess),
    );
  }

  Future<void> _restoreOnLocal(RestoreOption option) async {
    final appLocalizations = context.appLocalizations;
    final file = await picker.pickerFile();
    final path = file?.path;
    if (path == null) return;
    await File(path).safeCopy(await appPath.backupFilePath);
    final res = await globalState.loadingRun<bool>(
      () async {
        await globalState.container
            .read(backupActionProvider.notifier)
            .restore(option);
        ref
            .read(backupHistorySettingProvider.notifier)
            .recordSuccess(BackupEvent.localRestore);
        return true;
      },
      tag: LoadingTag.backup_restore,
      title: appLocalizations.restore,
    );
    if (res != true) return;
    globalState.showMessage(
      title: appLocalizations.restore,
      message: TextSpan(text: appLocalizations.restoreSuccess),
    );
  }

  Future<void> _handleRestoreOnLocal() async {
    final option = await globalState.showCommonDialog<RestoreOption>(
      child: const RestoreOptionsDialog(),
    );
    if (option == null || !mounted) return;
    _restoreOnLocal(option);
  }

  void _handleChange(String? value, WidgetRef ref) {
    if (value == null) {
      return;
    }
    ref
        .read(davSettingProvider.notifier)
        .update((state) => state?.copyWith(fileName: value));
  }

  Future<void> _handleUpdateRestoreStrategy() async {
    final restoreStrategy = ref.read(
      appSettingProvider.select((state) => state.restoreStrategy),
    );
    final res = await globalState.showCommonDialog(
      child: OptionsDialog<RestoreStrategy>(
        title: currentAppLocalizations.restoreStrategy,
        options: RestoreStrategy.values,
        textBuilder: (mode) => Intl.message('restoreStrategy_${mode.name}'),
        value: restoreStrategy,
      ),
    );
    if (res == null) {
      return;
    }
    ref
        .read(appSettingProvider.notifier)
        .update((state) => state.copyWith(restoreStrategy: res));
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final dav = ref.watch(davSettingProvider);
    final isLoading = ref.watch(loadingProvider(LoadingTag.backup_restore));
    final history = ref.watch(backupHistorySettingProvider);
    return CommonScaffold(
      isLoading: isLoading,
      title: appLocalizations.backupAndRestore,
      body: ListView(
        children: [
          ListHeader(title: appLocalizations.remote),
          if (dav == null)
            ListItem(
              leading: Icon(PanoramaIcons.settings.webdavAccount),
              title: Text(appLocalizations.noInfo),
              subtitle: Text(appLocalizations.pleaseBindWebDAV),
              trailing: FilledButton.tonal(
                onPressed: () {
                  _showAddWebDAV(dav);
                },
                child: Text(appLocalizations.bind),
              ),
            )
          else ...[
            ListItem(
              leading: Icon(PanoramaIcons.settings.webdavAccount),
              title: TooltipText(
                text: Text(
                  dav.user,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        appLocalizations.connectivity,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    ValueListenableBuilder(
                      valueListenable: _davConnection,
                      builder: (_, isCompleter, _) {
                        return Center(
                          child: FadeThroughBox(
                            child: isCompleter == null
                                ? const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1,
                                    ),
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: !isCompleter
                                          ? context.colorScheme.error
                                          : context.colorScheme.statusConnected,
                                    ),
                                    width: 12,
                                    height: 12,
                                  ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 6),
                    // The dot alone relies on colour (brief §100).
                    Flexible(
                      child: ValueListenableBuilder(
                        valueListenable: _davConnection,
                        builder: (_, isReachable, _) =>
                            Text(switch (isReachable) {
                              null => appLocalizations.davChecking,
                              true => appLocalizations.davReachable,
                              false => appLocalizations.davUnreachable,
                            }),
                      ),
                    ),
                  ],
                ),
              ),
              trailing: FilledButton.tonal(
                onPressed: () {
                  _showAddWebDAV(dav);
                },
                child: Text(appLocalizations.edit),
              ),
            ),
            if (history.hasRemoteError)
              _RemoteErrorItem(
                kind: history.remoteError!,
                at: history.remoteErrorAt!,
              ),
            const SizedBox(height: 4),
            ListItem.input(
              title: Text(appLocalizations.file),
              subtitle: Text(dav.fileName),
              delegate: InputDelegate(
                title: appLocalizations.file,
                value: dav.fileName,
                resetValue: defaultDavFileName,
                maxLength: TextInputLimits.fileName,
                onChanged: (value) {
                  _handleChange(value, ref);
                },
              ),
            ),
            ListItem(
              onTap: () {
                _backupOnWebDAV();
              },
              title: Text(appLocalizations.backup),
              subtitle: Text(appLocalizations.remoteBackupDesc),
              trailing: _LastDone(history.remoteBackupAt),
            ),
            ListItem(
              onTap: () {
                _handleRestoreOnWebDAV();
              },
              title: Text(appLocalizations.restore),
              subtitle: Text(appLocalizations.restoreFromWebDAVDesc),
              trailing: _LastDone(history.remoteRestoreAt),
            ),
          ],
          ListHeader(title: appLocalizations.local),
          ListItem(
            onTap: () {
              _backupOnLocal();
            },
            title: Text(appLocalizations.backup),
            subtitle: Text(appLocalizations.localBackupDesc),
            trailing: _LastDone(history.localBackupAt),
          ),
          ListItem(
            onTap: () {
              _handleRestoreOnLocal();
            },
            title: Text(appLocalizations.restore),
            subtitle: Text(appLocalizations.restoreFromFileDesc),
            trailing: _LastDone(history.localRestoreAt),
          ),
          ListHeader(title: appLocalizations.options),
          Consumer(
            builder: (_, ref, _) {
              final restoreStrategy = ref.watch(
                appSettingProvider.select((state) => state.restoreStrategy),
              );
              return ListItem(
                onTap: () {
                  _handleUpdateRestoreStrategy();
                },
                title: Text(appLocalizations.restoreStrategy),
                trailing: FilledButton(
                  onPressed: () {
                    _handleUpdateRestoreStrategy();
                  },
                  child: Text(
                    Intl.message('restoreStrategy_${restoreStrategy.name}'),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// When an action last succeeded on this device (brief §76).
class _LastDone extends StatelessWidget {
  final DateTime? at;

  const _LastDone(this.at);

  @override
  Widget build(BuildContext context) {
    final l = context.appLocalizations;
    final style = context.textTheme.bodySmall?.copyWith(
      color: context.colorScheme.labelSecondary,
    );
    final at = this.at;
    if (at == null) return Text(l.notYet, style: style);
    return Tooltip(
      message: at.showFull,
      child: TickBuilder(
        duration: const Duration(minutes: 1),
        builder: (context, _) =>
            Text(l.lastDone(at.getLastUpdateTimeDesc(context)), style: style),
      ),
    );
  }
}

class _RemoteErrorItem extends StatelessWidget {
  final BackupErrorKind kind;
  final DateTime at;

  const _RemoteErrorItem({required this.kind, required this.at});

  @override
  Widget build(BuildContext context) {
    final l = context.appLocalizations;
    final reason = switch (kind) {
      BackupErrorKind.unreachable => l.backupErrorUnreachable,
      BackupErrorKind.unauthorized => l.backupErrorUnauthorized,
      BackupErrorKind.notFound => l.backupErrorNotFound,
      BackupErrorKind.server => l.backupErrorServer,
      BackupErrorKind.failed => l.backupErrorFailed,
    };
    return ListItem(
      leading: Icon(
        PanoramaIcons.status.failed,
        color: context.colorScheme.error,
      ),
      title: Text(l.lastAttemptFailed(reason)),
      subtitle: Text(at.getLastUpdateTimeDesc(context)),
    );
  }
}

class RestoreOptionsDialog extends StatefulWidget {
  const RestoreOptionsDialog({super.key});

  @override
  State<RestoreOptionsDialog> createState() => _RestoreOptionsDialogState();
}

class _RestoreOptionsDialogState extends State<RestoreOptionsDialog> {
  void _handleOnTab(RestoreOption? option) {
    if (option == null) return;
    Navigator.of(context).pop(option);
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    return CommonDialog(
      title: appLocalizations.restore,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      child: Wrap(
        children: [
          ListItem(
            onTap: () {
              _handleOnTab(RestoreOption.onlyProfiles);
            },
            title: Text(appLocalizations.restoreOnlyConfig),
          ),
          ListItem(
            onTap: () {
              _handleOnTab(RestoreOption.all);
            },
            title: Text(appLocalizations.restoreAllData),
          ),
        ],
      ),
    );
  }
}

class WebDAVFormDialog extends ConsumerStatefulWidget {
  final DAVProps? dav;

  const WebDAVFormDialog({super.key, this.dav});

  @override
  ConsumerState<WebDAVFormDialog> createState() => _WebDAVFormDialogState();
}

class _WebDAVFormDialogState extends ConsumerState<WebDAVFormDialog> {
  late TextEditingController _uriController;
  late TextEditingController _userController;
  late TextEditingController _passwordController;
  final _obscureController = ValueNotifier<bool>(true);
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _uriController = TextEditingController(text: widget.dav?.uri);
    _userController = TextEditingController(text: widget.dav?.user);
    _passwordController = TextEditingController(text: widget.dav?.password);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(davSettingProvider.notifier).value = DAVProps(
      uri: _uriController.text,
      user: _userController.text,
      password: _passwordController.text,
    );
    Navigator.pop(context);
  }

  void _delete() {
    ref.read(davSettingProvider.notifier).value = null;
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _obscureController.dispose();
    _uriController.dispose();
    _userController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    return CommonDialog(
      title: appLocalizations.webDAVConfiguration,
      actions: [
        if (widget.dav != null)
          TextButton(onPressed: _delete, child: Text(appLocalizations.delete)),
        TextButton(onPressed: _submit, child: Text(appLocalizations.save)),
      ],
      child: Form(
        key: _formKey,
        child: Wrap(
          runSpacing: 16,
          children: [
            TextFormField(
              controller: _uriController,
              inputFormatters: TextInputLimits.limit(TextInputLimits.uri),
              maxLines: 5,
              minLines: 1,
              decoration: glassInputDecoration(
                context,
                prefixIcon: Icon(PanoramaIcons.settings.address),
                labelText: appLocalizations.address,
                helperText: appLocalizations.addressHelp,
              ),
              validator: (String? value) {
                if (value == null || value.isEmpty || !value.isUrl) {
                  return appLocalizations.addressTip;
                }
                return null;
              },
            ),
            TextFormField(
              controller: _userController,
              inputFormatters: TextInputLimits.limit(TextInputLimits.userName),
              decoration: glassInputDecoration(
                context,
                prefixIcon: Icon(PanoramaIcons.settings.account),
                labelText: appLocalizations.account,
              ),
              validator: (String? value) {
                if (value == null || value.isEmpty) {
                  return appLocalizations.emptyTip(appLocalizations.account);
                }
                return null;
              },
            ),
            ValueListenableBuilder(
              valueListenable: _obscureController,
              builder: (_, obscure, _) {
                return TextFormField(
                  controller: _passwordController,
                  inputFormatters: TextInputLimits.limit(
                    TextInputLimits.password,
                  ),
                  obscureText: obscure,
                  decoration: glassInputDecoration(
                    context,
                    prefixIcon: Icon(PanoramaIcons.settings.password),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscure
                            ? PanoramaIcons.actions.show
                            : PanoramaIcons.actions.hide,
                      ),
                      onPressed: () {
                        _obscureController.value = !obscure;
                      },
                    ),
                    labelText: appLocalizations.password,
                  ),
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return appLocalizations.emptyTip(
                        appLocalizations.password,
                      );
                    }
                    return null;
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
