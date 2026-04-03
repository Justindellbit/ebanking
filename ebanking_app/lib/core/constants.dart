class AppConstants {
  // Base URL SANS /api à la fin — chaque service ajoute son propre chemin
  static const String baseUrl = "http://172.20.116.173:8081";
  //17172.20.116.173
  // Raccourcis par domaine
  static const String authUrl = "$baseUrl/auth";
  static const String accountsUrl = "$baseUrl/api/accounts";
  static const String transactionsUrl = "$baseUrl/api/transactions";
}