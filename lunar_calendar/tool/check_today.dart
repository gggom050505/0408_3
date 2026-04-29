import "package:lunar/lunar.dart";

void main() {
  final d = DateTime(2026, 4, 29);
  final gz = Solar.fromYmd(d.year, d.month, d.day).getLunar().getDayInGanZhi();
  print("2026-04-29 dayGZ=$gz");
}
