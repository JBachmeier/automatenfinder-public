import 'package:cloud_firestore/cloud_firestore.dart';

class VendingMachine{
  VendingMachine({this.id, required this.type, required this.geodata, required this.address, required this.addedBy, required this.deletedBy, required this.verified, required this.details});

  final String? id;
  MachineType type;
  final GeoPoint geodata;
  final String address;
  final List<String> addedBy;
  final List<String> deletedBy;
  bool? verified;

  Map<String,Map<String,dynamic>> details;

}

enum MachineType {
  Food,
  Beverages,
  Cigarettes,
  Coffee,
  Snacks,
  Miscellaneous,
  
}