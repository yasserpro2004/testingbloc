import 'package:bloc/bloc.dart';
import 'package:testingbloc/main.dart';

List<String> names = ['yasser', 'ahmed', 'sayed', 'ali', 'mohab', 'mohamed'];

class NamesCubit extends Cubit<String?> {
  NamesCubit() : super(null);

  void getRandomName() {
    emit(names.getRandomElement());
  }
}
