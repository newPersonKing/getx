import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../../../get_core/src/get_main.dart';
import '../../../get_instance/get_instance.dart';
import '../../get_navigation.dart';
import 'custom_transition.dart';
import 'transitions_type.dart';

@immutable
class PathDecoded {
  const PathDecoded(this.regex, this.keys);
  final RegExp regex;
  final List<String?> keys;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PathDecoded &&
        other.regex == regex; // && listEquals(other.keys, keys);
  }

  @override
  int get hashCode => regex.hashCode;
}

/*在Getx中每一个页面都会嵌套一个GetPage*/
class GetPage<T> extends Page<T> {
  final GetPageBuilder page;
  final bool? popGesture;
  final Map<String, String>? parameter;
  final String? title;
  final Transition? transition;
  final Curve curve;
  final Alignment? alignment;
  final bool maintainState;
  final bool opaque;
  final Bindings? binding;
  final List<Bindings> bindings;
  final CustomTransition? customTransition;
  final Duration? transitionDuration;
  final bool fullscreenDialog;
  final bool preventDuplicates;
  // @override
  // final LocalKey? key;

  // @override
  // RouteSettings get settings => this;

  @override
  Object? get arguments => Get.arguments;

  @override
  final String name;

  final List<GetPage>? children;
  final List<GetMiddleware>? middlewares;
  final PathDecoded path;
  final GetPage? unknownRoute;

  GetPage({
    required this.name,
    required this.page,
    this.title,
    // RouteSettings settings,
    this.maintainState = true,
    this.curve = Curves.linear,
    this.alignment,
    this.parameter,
    this.opaque = true,
    this.transitionDuration,
    this.popGesture,
    this.binding,
    this.bindings = const [],
    this.transition,
    this.customTransition,
    this.fullscreenDialog = false,
    this.children,
    this.middlewares,
    this.unknownRoute,
    this.preventDuplicates = false,
  })  : path = _nameToRegex(name),
        super(
          key: ValueKey(name),
          name: name,
          arguments: Get.arguments,
        );
  // settings = RouteSettings(name: name, arguments: Get.arguments);

  static PathDecoded _nameToRegex(String path) {
    var keys = <String?>[];

    /*把url 中的参数 替换成 匹配 只要不是乱七八糟的就行*/
    String _replace(Match pattern) {
      var buffer = StringBuffer('(?:');
      /* ^(?:\.([\\w%+-._~!\$&\'()*,;=:@]+))?$ */
      if (pattern[1] != null) buffer.write('\.');
      buffer.write('([\\w%+-._~!\$&\'()*,;=:@]+))');
      if (pattern[3] != null) buffer.write('?');

      keys.add(pattern[2]);
      return "$buffer";
    }

    /*\. 匹配. \w 匹配字母数字 下滑线 \？匹配?  + 匹配一次或者多次 ? 匹配0次或者一次*/
    /*这里相当于是要匹配 .:ahdawdghj? 或者.:adadada 或者 :adadsda*/
    var stringPath = '$path/?'
        .replaceAllMapped(RegExp(r'(\.)?:(\w+)(\?)?'), _replace)
        .replaceAll('//', '/');

    return PathDecoded(RegExp('^$stringPath\$'), keys);
  }

  GetPage copy({
    String? name,
    GetPageBuilder? page,
    bool? popGesture,
    Map<String, String>? parameter,
    String? title,
    Transition? transition,
    Curve? curve,
    Alignment? alignment,
    bool? maintainState,
    bool? opaque,
    Bindings? binding,
    List<Bindings>? bindings,
    CustomTransition? customTransition,
    Duration? transitionDuration,
    bool? fullscreenDialog,
    RouteSettings? settings,
    List<GetPage>? children,
    GetPage? unknownRoute,
    List<GetMiddleware>? middlewares,
    bool? preventDuplicates,
  }) {
    return GetPage(
      preventDuplicates: preventDuplicates ?? this.preventDuplicates,
      name: name ?? this.name,
      page: page ?? this.page,
      popGesture: popGesture ?? this.popGesture,
      parameter: parameter ?? this.parameter,
      title: title ?? this.title,
      transition: transition ?? this.transition,
      curve: curve ?? this.curve,
      alignment: alignment ?? this.alignment,
      maintainState: maintainState ?? this.maintainState,
      opaque: opaque ?? this.opaque,
      binding: binding ?? this.binding,
      bindings: bindings ?? this.bindings,
      customTransition: customTransition ?? this.customTransition,
      transitionDuration: transitionDuration ?? this.transitionDuration,
      fullscreenDialog: fullscreenDialog ?? this.fullscreenDialog,
      children: children ?? this.children,
      unknownRoute: unknownRoute ?? this.unknownRoute,
      middlewares: middlewares ?? this.middlewares,
    );
  }

  @override
  Route<T> createRoute(BuildContext context) {
    return PageRedirect(
      this,
      unknownRoute,
    ).page<T>();
  }
}
