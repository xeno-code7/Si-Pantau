class RulResult {
  final int sisaKm;
  final int sisaHari;
  final String status;

  RulResult({required this.sisaKm, required this.sisaHari, required this.status});
}

class RulHelper {
  static RulResult hitungRul({
    required String jenisKendaraan,
    required int odoSekarang,
    required int odoTerakhirServis,
    required DateTime tanggalTerakhirServis,
  }) {
    // ATURAN JARAK (KM)
    // Mobil: 8000 KM, Motor: 3000 KM [cite: 612-613]
    final maxKm = jenisKendaraan.toLowerCase() == "mobil" ? 8000 : 3000;
    
    // ATURAN WAKTU (HARI)
    // Mobil: 6 bulan (180 hari), Motor: 2 bulan (60 hari)
    final maxHari = jenisKendaraan.toLowerCase() == "mobil" ? 180 : 60;

    // HITUNG SISA [cite: 614-616]
    final kmTerpakai = odoSekarang - odoTerakhirServis;
    final sisaKm = maxKm - kmTerpakai;

    final hariTerpakai = DateTime.now().difference(tanggalTerakhirServis).inDays;
    final sisaHari = maxHari - hariTerpakai;

    // TENTUKAN STATUS [cite: 617-619]
    String status = "AMAN";
    if (sisaKm <= 0 || sisaHari <= 0) {
      status = "HARUS SERVIS";
    } else if (sisaKm <= 1000 || sisaHari <= 14) {
      status = "MENDEKATI SERVIS";
    }

    return RulResult(sisaKm: sisaKm, sisaHari: sisaHari, status: status);
  }
}