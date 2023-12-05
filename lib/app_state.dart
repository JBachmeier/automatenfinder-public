// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'
    hide EmailAuthProvider, PhoneAuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'vendingmachine.dart';

class ApplicationState extends ChangeNotifier {
  ApplicationState() {
    init();
  }

  bool _loggedIn = false;
  bool get loggedIn => _loggedIn;

  bool _routingStarted = false;
  bool get routingStarted => _routingStarted;

  set routingStarted(bool value) {
    _routingStarted = value;
    notifyListeners();
  }

  StreamSubscription<QuerySnapshot>? _verifiedmachineSubscription;
  StreamSubscription<QuerySnapshot>? _unverifiedmachineSubscription;

  /// Liste aller verifizierten Automaten
  List<VendingMachine> _verifiedmachines = [];
  List<VendingMachine> get verifiedmachines => _verifiedmachines;

  /// Liste aller nicht verifizierten Automaten
  List<VendingMachine> _unverifiedmachines = [];
  List<VendingMachine> get unverifiedmachines => _unverifiedmachines;

  /// Bricht die momentane Subscription ab und startet sie mit entsprechenden Filtern neu
  void updateVerifiedSubscription(
      MachineType? filteredtype, 
      bool? filteredcard,
      bool? filteredcash, 
      bool? filteredwheel, 
      bool? filteredsound) {

    _verifiedmachineSubscription?.cancel();

    // Da der meistgewertete Type als ein extra Parameter gespeichert wird, kann dieser mit der .where-Funktion gefiltert werden
    _verifiedmachineSubscription = FirebaseFirestore.instance
        .collection('Verified-Machines')
        .where('Type', isEqualTo: filteredtype?.name)
        .snapshots()
        .listen((snapshot) {
      _verifiedmachines = [];
      _verifiedmachines = prepareMachines(snapshot, filteredtype, filteredcard,
          filteredcash, filteredwheel, filteredsound);
      notifyListeners();
    });
  }

  /// Bricht die momentane Subscription ab und startet sie mit entsprechenden Filtern neu
  void updateUnverifiedSubscription(
      MachineType? filteredtype,
      bool? filteredcard,
      bool? filteredcash,
      bool? filteredwheel,
      bool? filteredsound) {
    _unverifiedmachineSubscription?.cancel();

    _unverifiedmachineSubscription = FirebaseFirestore.instance
        .collection('Unverified-Machines')
        .where('Type', isEqualTo: filteredtype?.name)
        .snapshots()
        .listen((snapshot) {
      _unverifiedmachines = [];
      _unverifiedmachines = prepareMachines(snapshot, filteredtype,
          filteredcard, filteredcash, filteredwheel, filteredsound);
      notifyListeners();
    });
  }

  /// Bereitet die von Firestore geholten Daten auf und gibt diese als eine Liste an VendingMachine-Objekten zurück
  List<VendingMachine> prepareMachines(
      QuerySnapshot<Map<String, dynamic>> snapshot,
      MachineType? filteredtype,
      bool? filteredcard,
      bool? filteredcash,
      bool? filteredwheel,
      bool? filteredsound) {
    List<VendingMachine> list = [];
    for (final document in snapshot.docs) {

      var enumType = MachineType.values.firstWhere((element) => element.name == document.data()['Type']);

      /// Listen in der Firestore Datenbank werden mit nicht-spezifischen Datentyp List<dynamic> gespeichert.
      /// Die addedBy variable in der VendingMachine Klasse besitzt aber den Objekt-Typ List<String>, alson eine Liste an Strings
      /// Da aber alle einträge in der Spalte AddedBy bekannterweise Strings sind, können diese problemlos in eine Liste aus Strings eingefügt werden.
      List<String> addedByList = [];
      for (String user in document.data()['AddedBy']) {
        addedByList.add(user);
      }

      List<String> deletedByList = [];
      for (String user in document.data()['DeletedBy']) {
        deletedByList.add(user);
      }

      /// Konvetiert die Firestore Details in den richtigen Datentyp, ähnlich der addedByList
      Map<String, Map<String, dynamic>> detailsMap = {};
      document.data()['Details'].forEach((key, value) {
        // Dieser if cast ist mötig, da value sonst Map<dynamic,dynamic> ist
        if (value is Map<String, dynamic>) {
          Map<String, dynamic> castedValue =
              value.map((k, v) => MapEntry(k, v as dynamic));
          detailsMap[key] = castedValue;
        }
      });

      /// Hier werden die Filter angewandt.
      /// Wenn bei dem momentanen Automaten keins dieser filter zutrifft, wird er übersprungen, und somit nicht in die Liste mit aufgenommen
      if (!detailsMap.entries.any((entry) =>
          (filteredcash == null || entry.value['Cash'] == filteredcash) &&
          (filteredcard == null || entry.value['Card'] == filteredcard) &&
          (filteredwheel == null || entry.value['Wheelchair'] == filteredwheel) &&
          (filteredsound == null || entry.value['Sound'] == filteredsound))) {
        continue;
      }

      /// Zuletzt werden die Daten als VendingMachine-Objekt gespeichert und in die gegebene Liste hinzugefügt
      VendingMachine machine = VendingMachine(
        id: document.id,
        type: enumType,
        geodata: document.data()['Coords'],
        address: document.data()['Address'],
        addedBy: addedByList,
        deletedBy: deletedByList,
        verified: document.data()['Verified'],
        details: detailsMap,
      );

      list.add(machine);
    }
    return list;
  }

  
  void cancelVerifiedSubscription() {
    _verifiedmachineSubscription?.cancel();
    _verifiedmachines = [];
    notifyListeners();
  }

  void cancelUnverifiedSubscription() {
    _unverifiedmachineSubscription?.cancel();
    _unverifiedmachines = [];
    notifyListeners();
  }

  /// Wird beim Starten der Anwendung ausgeführt
  Future<void> init() async {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);

    FirebaseUIAuth.configureProviders([
      EmailAuthProvider(),
    ]);

    // Startet die Firebase Subscription für verifizierte Automaten ohne jegliche Filter
    updateVerifiedSubscription(null, null, null, null, null);

    // Wird jedes mal ausgeführt, wenn sich der status des Nutzers ändert
    FirebaseAuth.instance.userChanges().listen((user) {
      // Wenn der Nutzer sich einloggt oder eingeloggt ist, werden die nicht verifizierten Automaten auch geladen
      if (user != null) {
        try {
          FirebaseFirestore.instance.collection('Users').doc(user.uid);
        } catch (err) {
          print("Test");
        }
        _loggedIn = true;
        updateUnverifiedSubscription(null, null, null, null, null);
      } 
      // Falls sich der Nutzer ausloggt oder ausgeloggt ist, wird die Subscription wieder abgebrochen
      else {
        _loggedIn = false;
        _unverifiedmachineSubscription?.cancel();
        _unverifiedmachines = [];
      }
      notifyListeners();
    });
  }

  /// Fügt eine neue Machine in die NichtValidierten-Datenbank hinzu
  Future<void> addNewMachine(VendingMachine machine) {
    if (!_loggedIn) {
      throw Exception('Must be logged in');
    }

    final data = {
      'Coords': machine.geodata,
      'Type': machine.type.name,
      'Address': machine.address,
      'AddedBy': machine.addedBy,
      'DeletedBy': machine.deletedBy,
      'Verified': false,
      'Details': machine.details,
    };
    notifyListeners();
    return FirebaseFirestore.instance
        .collection('Unverified-Machines')
        .add(data);
  }

  /// Verändert den Eintrag in der Datenbank so, dass die Anzahl der Validierungen sich anpasst.
  /// Wenn die Anzahl der Validierungen 5 beträgt, wird die addNewMachineVerified Funktion aufgerufen.
  Future<void> addValidationInstance(VendingMachine machine) {
    if (!_loggedIn) {
      throw Exception('Must be logged in');
    }
    machine.addedBy.add(FirebaseAuth.instance.currentUser!.uid);

    
    machine.details.addAll({FirebaseAuth.instance.currentUser!.uid: getMostVotedDetails(machine)});

    String mostVotedType = getMostVotedType(machine);

    final data = {
      'Coords': machine.geodata,
      'Type': mostVotedType,
      'Address': machine.address,
      'AddedBy': machine.addedBy,
      'DeletedBy': machine.deletedBy,
      'Verified': false,
      'Details': machine.details,
    };
    notifyListeners();


    // Wenn 5 Personen den Automaten validiert haben, wird der Automat aus den nicht validierten gelöscht, und zu den validierten hinzugefügt
    if (machine.addedBy.length >= 5) {
      return addNewMachineVerified(machine);
    }

    return FirebaseFirestore.instance
        .collection('Unverified-Machines')
        .doc(machine.id)
        .set(data);
  }

  /// Geht durch alle Details einer Machine und gibt die meist-abgestimmten Details zurück
  Map<String,dynamic> getMostVotedDetails(VendingMachine machine){
    Map<String,dynamic> mostVotedDetails = {};

    Map<bool?,int> cardVotes = {};
    int cardTrue = 0;
    int cardFalse = 0;
    int cardMaybe = 0;

    Map<bool?,int> cashVotes = {};
    int cashTrue = 0;
    int cashFalse = 0;
    int cashMaybe = 0;

    Map<bool?,int> wheelVotes = {};
    int wheelTrue = 0;
    int wheelFalse = 0;
    int wheelMaybe = 0;

    Map<bool?,int> soundVotes = {};
    int soundTrue = 0;
    int soundFalse = 0;
    int soundMaybe = 0;

    /// Es wird durch jedes Detail gegangen, und mitgezählt, wie oft diese vorkommt
    for (final value in machine.details.values) {
      final cardValue = value['Card'];
      final cashValue = value['Cash'];
      final wheelValue = value['Wheelchair'];
      final soundValue = value['Sound'];

      if (cardValue == true) {
        cardTrue++;
      } else if (cardValue == false) {
        cardFalse++;
      } else {
        cardMaybe++;
      }

      if (cashValue == true) {
        cashTrue++;
      } else if (cashValue == false) {
        cashFalse++;
      } else {
        cashMaybe++;
      }

      if (wheelValue == true) {
        wheelTrue++;
      } else if (wheelValue == false) {
        wheelFalse++;
      } else {
        wheelMaybe++;
      }

      if (soundValue == true) {
        soundTrue++;
      } else if (soundValue == false) {
        soundFalse++;
      } else {
        soundMaybe++;
      }
    }

    // Die  gezählten Details werden dann in eine Map mit ihrem jeweiligen Wert hinzugefügt
    cardVotes.addAll({true:cardTrue,false:cardFalse,null:cardMaybe});
    cashVotes.addAll({true:cashTrue,false:cashFalse,null:cashMaybe});
    wheelVotes.addAll({true:wheelTrue,false:wheelFalse,null:wheelMaybe});
    soundVotes.addAll({true:soundTrue,false:soundFalse,null:soundMaybe});

    List<String> emptyContentList = [];

    // Dann wird der Wert mit der höchsten Zahl ermittelt und als Details angegeben
    mostVotedDetails.addAll({'Card': cardVotes.entries.reduce((a, b) => a.value > b.value ? a : b).key,
    'Cash': cashVotes.entries.reduce((a, b) => a.value > b.value ? a : b).key,
    'Wheelchair': wheelVotes.entries.reduce((a, b) => a.value > b.value ? a : b).key,
    'Sound': soundVotes.entries.reduce((a, b) => a.value > b.value ? a : b).key,
    'Type': machine.type.name,
    'Content': emptyContentList
    });

    return mostVotedDetails;
  }

  /// Löscht den Automaten aus der Nichtvalidierten-Datenbank und fügt ihn in die Validierten-Datenbank hinzu
  Future<void> addNewMachineVerified(VendingMachine machine) {
    if (!_loggedIn) {
      throw Exception('Must be logged in');
    }

    String mostVotedType = getMostVotedType(machine);

    final data = {
      'Coords': machine.geodata,
      'Type': mostVotedType,
      'Address': machine.address,
      'AddedBy': machine.addedBy,
      'DeletedBy': machine.deletedBy,
      'Verified': true,
      'Details': machine.details,
    };
    notifyListeners();
    _unverifiedmachines.removeWhere((item) => item.id == machine.id);
    FirebaseFirestore.instance
        .collection('Unverified-Machines')
        .doc(machine.id)
        .delete();
    // Aus der Backup-Verified-Machines können keine Automaten gelöscht werden
    FirebaseFirestore.instance
        .collection('Backup-Verified-Machines')
        .doc(machine.id)
        .set(data);
    return FirebaseFirestore.instance
        .collection('Verified-Machines')
        .doc(machine.id)
        .set(data);
  }

  /// Überprüft die existenz des im Parameter angegebenen Automaten. Gibt ein bool zurück, abhängig davon, ob die der Automat nah genug an einem anderen ist, und diese den gleichen Typen besitzen
  bool checkMachineExistance(VendingMachine machine) {
    return (((unverifiedmachines.any((element) =>
            calculateDistance(
                element.geodata.latitude,
                element.geodata.longitude,
                machine.geodata.latitude,
                machine.geodata.longitude) <
            0.01)) && unverifiedmachines.any((element) => element.type == machine.type)) ||
        ((verifiedmachines.any((element) =>
            calculateDistance(
                element.geodata.latitude,
                element.geodata.longitude,
                machine.geodata.latitude,
                machine.geodata.longitude) <
            0.01)) && unverifiedmachines.any((element) => element.type == machine.type)));
  }

  /// Berechnet die tatsächliche Distanz zweier Punkte auf der Erdkugel
  double calculateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  /// Fügt eine Validierungsinstanz zum Automaten hinzu, mit den meistbewerteten Angaben
  Future<void> applyVerificationUpdates(VendingMachine machine) {
    if (!machine.addedBy.contains(FirebaseAuth.instance.currentUser!.uid)) {
      machine.addedBy.add(FirebaseAuth.instance.currentUser!.uid);
      if (machine.addedBy.length >= 5) {
        notifyListeners();
        return addNewMachineVerified(machine);
      }
    }

    return applyUpdates(machine);
  }

  /// Fügt eine Löschungsinstanz zum Automate hinzu. Wenn ein Automat 30 mal gelöscht wurde, wird dieser entgültig aus Sammlung gelöscht
  Future<void> addDeletionInstance(VendingMachine machine) {
    if (!machine.deletedBy.contains(FirebaseAuth.instance.currentUser!.uid)) {
      machine.deletedBy.add(FirebaseAuth.instance.currentUser!.uid);
      if (machine.addedBy.length == 1 &&
          machine.addedBy.first == FirebaseAuth.instance.currentUser!.uid) {
        notifyListeners();
        return deleteMachine(machine);
      }
      if (machine.deletedBy.length >= 30) {
        notifyListeners();
        return deleteMachine(machine);
      } else {
        return applyUpdates(machine);
      }
    } else {
      return applyUpdates(machine);
    }
  }

  Future<void> deleteMachine(VendingMachine machine) {
    if (!_loggedIn) {
      throw Exception('Must be logged in');
    }

    if (machine.verified == true) {
      return FirebaseFirestore.instance
          .collection('Verified-Machines')
          .doc(machine.id)
          .delete();
    } else {
      return FirebaseFirestore.instance
          .collection('Unverified-Machines')
          .doc(machine.id)
          .delete();
    }
  }

  Future<void> applyUpdates(VendingMachine machine) {

    String mostVotedType = getMostVotedType(machine);

    final data = {
        'Coords': machine.geodata,
        'Type': mostVotedType,
        'Address': machine.address,
        'AddedBy': machine.addedBy,
        'DeletedBy': machine.deletedBy,
        'Verified': false,
        'Details': machine.details,
      };

    notifyListeners();

    if (machine.verified == true) {
      return FirebaseFirestore.instance
          .collection('Verified-Machines')
          .doc(machine.id)
          .set(data);
    } else {
      return FirebaseFirestore.instance
          .collection('Unverified-Machines')
          .doc(machine.id)
          .set(data);
    }
  }

  /// Geht durch jedes Detail eines Automaten und zählt die Typ angaben. Der meistgezählte Typ wird wiedergegeben
  String getMostVotedType(VendingMachine machine){
    Map<String, int> typeList = {};
    machine.details.forEach((key1, value1) {
      value1.forEach((key2, value2) {
        if (key2 == 'Type') {
          if (typeList.containsKey(value2)) {
            typeList[value2] = typeList[value2]! + 1;
          } else {
            typeList[value2] = 1;
          }
        }
      });
    });

    /// Wenn ein Automat mehrere Typenangaben hat, wird ermittelt ob ein Typ mehr als die anderen genannt wurde
    /// Falls nein, wird der Typ, den der ersteller des Automats angegeben hat gewählt.
    /// Ansonsten wird der meist genannte gewählt
    String keyWithHighestValue = "";
    if (!typeList.values.any((element) => element > 1)) {
      keyWithHighestValue = machine.details.entries.first.value['Type'];
    } else {
      keyWithHighestValue =
          typeList.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    }

    MachineType mostVotedType = MachineType.values.firstWhere((element) => element.name == keyWithHighestValue);
    return mostVotedType.name;
  }
}
