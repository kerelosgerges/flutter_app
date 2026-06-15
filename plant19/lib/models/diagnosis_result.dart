class DiagnosisResult {
  final bool isPlant;
  final double plantConfidence;
  final String? diseaseClass;
  final double? diseaseConfidence;
  final bool isHealthy;
  final String? plantName;
  final String? diseaseName;

  DiagnosisResult({
    required this.isPlant,
    required this.plantConfidence,
    this.diseaseClass,
    this.diseaseConfidence,
    this.isHealthy = false,
    this.plantName,
    this.diseaseName,
  });
}
