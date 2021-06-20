import '../../get_navigation.dart';
import '../routes/get_route.dart';

class RouteDecoder {
  final List<GetPage> treeBranch;
  GetPage? get route => treeBranch.isEmpty ? null : treeBranch.last;
  final Map<String, String> parameters;
  const RouteDecoder(
    this.treeBranch,
    this.parameters,
  );
}

class ParseRouteTree {
  ParseRouteTree({
    required this.routes,
  });

  final List<GetPage> routes;

  RouteDecoder matchRoute(String name) {
    final uri = Uri.parse(name);
    // /home/profile/123 => home,profile,123 => /,/home,/home/profile,/home/profile/123
    final split = uri.path.split('/').where((element) => element.isNotEmpty);
    var curPath = '/';
    final cumulativePaths = <String>[
      '/',
    ];
    for (var item in split) {
      if (curPath.endsWith('/')) {
        curPath += '$item';
      } else {
        curPath += '/$item';
      }
      cumulativePaths.add(curPath);
    }

    final treeBranch = cumulativePaths
        .map((e) => MapEntry(e, _findRoute(e)))
        .where((element) => element.value != null)
        .map((e) => MapEntry(e.key, e.value!))
        .toList();

    final params = Map<String, String>.from(uri.queryParameters);

    /*treeBranch key 是path value 是找到的router*/
    if (treeBranch.isNotEmpty) {
      //route is found, do further parsing to get nested query params
      final lastRoute = treeBranch.last;
      final parsedParams = _parseParams(name, lastRoute.value.path);
      if (parsedParams.isNotEmpty) {
        params.addAll(parsedParams);
      }
      //copy parameters to all pages.
      final mappedTreeBranch = treeBranch
          .map(
            (e) => e.value.copy(
              parameter: {
                if (e.value.parameter != null) ...e.value.parameter!,
                ...params,
              },
              name: e.key,
            ),
          )
          .toList();
      return RouteDecoder(
        mappedTreeBranch,
        params,
      );
    }

    //route not found
    return RouteDecoder(
      treeBranch.map((e) => e.value).toList(),
      params,
    );
  }

  void addRoutes(List<GetPage> getPages) {
    for (final route in getPages) {
      addRoute(route);
    }
  }

  void addRoute(GetPage route) {
    routes.add(route);

    // Add Page children.
    for (var page in _flattenPage(route)) {
      addRoute(page);
    }
  }

  List<GetPage> _flattenPage(GetPage route) {
    final result = <GetPage>[];
    if (route.children == null || route.children!.isEmpty) {
      return result;
    }

    final parentPath = route.name;
    for (var page in route.children!) {
      // Add Parent middlewares to children
      final pageMiddlewares = page.middlewares ?? <GetMiddleware>[];
      /*todo GetMiddleware 是干什么用的*/
      /*pageMiddlewares 包含 父page的pageMiddlewares与自己的pageMiddlewares*/
      pageMiddlewares.addAll(route.middlewares ?? <GetMiddleware>[]);
      /*这个添加的是第一级children*/
      result.add(_addChild(page, parentPath, pageMiddlewares));

      /*继续向下遍历 这里返回的是第二级的children*/
      final children = _flattenPage(page);

      /*todo 这里为什么要添加第二级的children*/
      for (var child in children) {
        pageMiddlewares.addAll(child.middlewares ?? <GetMiddleware>[]);
        result.add(_addChild(child, parentPath, pageMiddlewares));
      }
    }
    return result;
  }

  /// Change the Path for a [GetPage]
  /// 主要只是做了把父page的name 与 自己的name 进行了拼接
  GetPage _addChild(
          GetPage origin, String parentPath, List<GetMiddleware> middlewares) =>
      GetPage(
        name: (parentPath + origin.name).replaceAll(r'//', '/'),
        page: origin.page,
        title: origin.title,
        alignment: origin.alignment,
        transition: origin.transition,
        binding: origin.binding,
        bindings: origin.bindings,
        curve: origin.curve,
        customTransition: origin.customTransition,
        fullscreenDialog: origin.fullscreenDialog,
        maintainState: origin.maintainState,
        opaque: origin.opaque,
        parameter: origin.parameter,
        popGesture: origin.popGesture,
        preventDuplicates: origin.preventDuplicates,
        transitionDuration: origin.transitionDuration,
        middlewares: middlewares,
      );

  GetPage? _findRoute(String name) {
    return routes.firstWhereOrNull(
      (route) => route.path.regex.hasMatch(name),
    );
  }

  /*path 是现在要跳转的路径*/
  Map<String, String> _parseParams(String path, PathDecoded routePath) {
    final params = <String, String>{};
    var idx = path.indexOf('?');
    if (idx > -1) {
      path = path.substring(0, idx);
      final uri = Uri.tryParse(path);
      if (uri != null) {
        params.addAll(uri.queryParameters);
      }
    }
    var paramsMatch = routePath.regex.firstMatch(path);

    for (var i = 0; i < routePath.keys.length; i++) {
      var param = Uri.decodeQueryComponent(paramsMatch![i + 1]!);
      params[routePath.keys[i]!] = param;
    }
    return params;
  }
}

extension FirstWhereExt<T> on List<T> {
  /// The first element satisfying [test], or `null` if there are none.
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
