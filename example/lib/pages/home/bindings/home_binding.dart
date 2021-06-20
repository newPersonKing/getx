import 'package:get/get.dart';
import '../data/home_api_provider.dart';

import '../data/home_repository.dart';
import '../domain/adapters/repository_adapter.dart';
import '../presentation/controllers/home_controller.dart';

/*页面创建之前会执行对应的 bindings 的 dependencies 方法*/
class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<IHomeProvider>(() => HomeProvider());
    Get.lazyPut<IHomeRepository>(() => HomeRepository(provider: Get.find()));
    Get.lazyPut(() => HomeController(homeRepository: Get.find()));
  }
}
