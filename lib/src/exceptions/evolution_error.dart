class EvolutionError extends Error {
  final String message;
  final String? code;
  final String? details;

  EvolutionError({required this.message, this.code, this.details});
}
