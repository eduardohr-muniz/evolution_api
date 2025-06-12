import 'package:evolution_api/src/exceptions/evolution_error.dart';

class InstanceNotFound extends EvolutionError {
  InstanceNotFound({required super.message, super.code, super.details});
}
