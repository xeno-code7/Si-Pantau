class RulResult {
  final int sisaKm;
  final int sisaHari;
  final String status;

  RulResult({
    required this.sisaKm,
    required this.sisaHari,
    required this.status,
  });
}

class RulHelper {
  static RulResult hitungRul({
    required String jenisKendaraan,
    required int odoSekarang,
    required int odoTerakhirServis,
    required DateTime tanggalTerakhirServis,
  }) {
    // ===== KONFIGURASI =====
    final maxKm = jenisKendaraan == "mobil" ? 5000 : 2000;
    final warningKm = jenisKendaraan == "mobil" ? 1000 : 200;

    final maxHari = 180;
    final warningHari = 10;

    // ===== HITUNG =====
    final kmTerpakai = odoSekarang - odoTerakhirServis;
    final sisaKm = maxKm - kmTerpakai;

    final hariTerpakai =
        DateTime.now().difference(tanggalTerakhirServis).inDays;
    final sisaHari = maxHari - hariTerpakai;

    // ===== STATUS =====
    String status = "AMAN";

    if (sisaKm <= 0 || sisaHari <= 0) {
      status = "HARUS SERVIS";
    } else if (sisaKm <= warningKm || sisaHari <= warningHari) {
      status = "MENDEKATI SERVIS";
    }

    return RulResult(
      sisaKm: sisaKm,
      sisaHari: sisaHari,
      status: status,
    );
  }
}
