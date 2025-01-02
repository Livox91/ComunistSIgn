import 'package:bloc/bloc.dart';
import 'package:mcprj/data/shared_preference.dart';

enum SetupEvent { startSetup, completeSetup }

enum SetupState { initial, inProgress, completed }

class FirstTimeSetupBloc extends Bloc<SetupEvent, SetupState> {
  final sharedPref = SharedPref();
  FirstTimeSetupBloc() : super(SetupState.initial) {
    on<SetupEvent>((event, emit) => mapEventsToState(event, emit));
  }

  void mapEventsToState(SetupEvent e, Emitter<SetupState> emit) async {
    if (e == SetupEvent.startSetup) {
      final isFirstTime = await sharedPref.isFirstTimeUser();
      print("isFirstTime: $isFirstTime");
      if (isFirstTime) {
        emit(SetupState.inProgress);
      } else {
        emit(SetupState.completed);
      }
    }
    if (e == SetupEvent.completeSetup) {
      emit(SetupState.completed);
      await sharedPref.setFirstTimeUser();
    }
  }
}
