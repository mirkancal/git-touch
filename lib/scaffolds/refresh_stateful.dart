import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:git_touch/scaffolds/common.dart';
import 'package:git_touch/scaffolds/utils.dart';

class RefreshStatefulScaffold<T> extends StatefulWidget {
  final Widget title;
  final Widget Function(T data, void Function(VoidCallback fn) setState)
      bodyBuilder;
  final Future<T> Function() fetchData;
  final Widget Function(T data, void Function(VoidCallback fn) setState)
      actionBuilder;
  final canRefresh;

  RefreshStatefulScaffold({
    @required this.title,
    @required this.bodyBuilder,
    @required this.fetchData,
    this.actionBuilder,
    this.canRefresh = true,
  });

  @override
  _RefreshStatefulScaffoldState<T> createState() =>
      _RefreshStatefulScaffoldState();
}

class _RefreshStatefulScaffoldState<T>
    extends State<RefreshStatefulScaffold<T>> {
  bool _loading;
  T _data;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _refresh();
    setState(() {});
  }

  Future<void> _refresh() async {
    try {
      setState(() {
        _error = '';
        _loading = true;
      });
      _data = await widget.fetchData();
    } catch (err) {
      _error = err.toString();
      throw err;
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Widget get _action {
    if (widget.actionBuilder == null) return null;
    return widget.actionBuilder(_data, setState);
  }

  @override
  Widget build(BuildContext context) {
    Widget child = ErrorLoadingWrapper(
      bodyBuilder: () => widget.bodyBuilder(_data, setState),
      error: _error,
      loading: _data == null,
      reload: _refresh,
    );
    if (widget.canRefresh) {
      child = RefreshWrapper(
        onRefresh: _refresh,
        body: child,
      );
    }

    return CommonScaffold(
      title: widget.title,
      body: child,
      action: _action,
    );
  }
}
