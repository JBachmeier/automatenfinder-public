import 'dart:async';

import 'package:automatenfinder/routing_start_dialog.dart';
import 'package:automatenfinder/vendingmachine.dart';
import 'package:firebase_auth/firebase_auth.dart'
    hide EmailAuthProvider, PhoneAuthProvider;
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

import 'edit_dialog.dart';

class MarkerDetail extends StatefulWidget {
  const MarkerDetail({
    super.key,
    required this.machine,
    required this.validateThis,
    required this.startRouting,
    required this.applyUpdates,
    required this.deleteMachine,
    //required this.adress,                 Für die Adresse muss ich die eingegebene Adresse noch zusätzlich in der Datenbank speichern
  });

  final VendingMachine machine;
  final Future<void> Function(VendingMachine machine) validateThis;
  final Future<void> Function(VendingMachine machine, TravelMode travelMode) startRouting;
  final Future<void> Function(VendingMachine machine) applyUpdates;
  final Future<void> Function(VendingMachine machine) deleteMachine;

  @override
  State<MarkerDetail> createState() => MarkerView();
}

class MarkerView extends State<MarkerDetail> {
  void startRouting(TravelMode travelMode) {
    widget.startRouting(widget.machine, travelMode);
  }

  @override
  Widget build(BuildContext context) {
    int cardTrue = 0;
    int cardFalse = 0;
    int cardMaybe = 0;
    int cashTrue = 0;
    int cashFalse = 0;
    int cashMaybe = 0;
    int wheelTrue = 0;
    int wheelFalse = 0;
    int wheelMaybe = 0;
    int soundTrue = 0;
    int soundFalse = 0;
    int soundMaybe = 0;
    List<String> allContents = [];

    /// Es wird durch jedes Detail gegangen, und mitgezählt, wie oft diese vorkommt
    for (final value in widget.machine.details.values) {
      final cardValue = value['Card'];
      final cashValue = value['Cash'];
      final wheelValue = value['Wheelchair'];
      final soundValue = value['Sound'];
      for (String content in value['Content']) {
        allContents.add(content);
      }

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

    int cardAll = cardTrue + cardFalse + cardMaybe;
    int cashAll = cashTrue + cashFalse + cashMaybe;
    int wheelAll = wheelTrue + wheelFalse + wheelMaybe;
    int soundAll = soundTrue + soundFalse + soundMaybe;

    /// Sortiert die angegebenen Inhalte nach häufigkeit
    Map<String, List<String>> groups = groupBy(allContents, (str) => str);
    List<MapEntry<String, List<String>>> entries = groups.entries.toList();

    entries.sort((a, b) => b.value.length.compareTo(a.value.length));

    List<String> sortedStrings = entries.map((entry) => entry.key).toList();

    String validationStatus = "";
    widget.machine.verified!
        ? validationStatus = "validated"
        : validationStatus = "not validated";

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 0, maxHeight: double.infinity),
        child: SingleChildScrollView(
          child: Wrap(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      widget.machine.address,
                      style: const TextStyle(fontSize: 13),
                    ),
                    const Divider(),
                    Text(
                      widget.machine.type.name,
                      style: const TextStyle(fontSize: 20),
                    ),
                    Text(
                      validationStatus,
                      style: const TextStyle(fontSize: 10),
                    ),
                    const Divider(),
                    SizedBox(
                      height: 40,
                      width: 400,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Content"),
                          const VerticalDivider(thickness: 2),
                          Expanded(
                            child: SizedBox(
                              height: 40,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: [
                                  ...sortedStrings.map((e) {
                                    return SizedBox(
                                      height: 40,
                                      child: Row(
                                        children: [
                                          Text(e),
                                          const VerticalDivider(),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    const Text("Paying with Card available"),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      width: 500,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Visibility(
                              visible: cardTrue != 0,
                              child: Expanded(
                                flex: ((cardTrue / cardAll) * 100).toInt(),
                                child: Container(
                                  decoration:
                                      const BoxDecoration(color: Colors.green),
                                  child: Center(child: Text(cardTrue.toString())),
                                ),
                              ),
                            ),
                            Visibility(
                              visible: cardMaybe != 0,
                              child: Expanded(
                                flex: ((cardMaybe / cardAll) * 100).toInt(),
                                child: Container(
                                  decoration: const BoxDecoration(color: Colors.grey),
                                  child: Center(child: Text(cardMaybe.toString())),
                                ),
                              ),
                            ),
                            Visibility(
                              visible: cardFalse != 0,
                              child: Expanded(
                                flex: ((cardFalse / cardAll) * 100).toInt(),
                                child: Container(
                                  decoration: const BoxDecoration(color: Colors.red),
                                  child: Center(child: Text(cardFalse.toString())),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Absatz, der die verschiedenen Abstimmungen der Details anzeigt
                    const Divider(),
                    const Text("Paying with Cash available"),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      width: 500,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Visibility ist nötig, denn selbst wenn das flex 0 ergibt, beinhaltet der Balken dennoch die Farbe, da die Menge als Text abgebildet wird, was dann 0 wäre
                            Visibility(
                              visible: cashTrue != 0,
                              child: Expanded(
                                flex: ((cashTrue / cashAll) * 100).toInt(),
                                child: Container(
                                  decoration:
                                      const BoxDecoration(color: Colors.green),
                                  child: Center(child: Text(cashTrue.toString())),
                                ),
                              ),
                            ),
                            Visibility(
                              visible: cashMaybe != 0,
                              child: Expanded(
                                flex: ((cashMaybe / cashAll) * 100).toInt(),
                                child: Container(
                                  decoration: const BoxDecoration(color: Colors.grey),
                                  child: Center(child: Text(cashMaybe.toString())),
                                ),
                              ),
                            ),
                            Visibility(
                              visible: cashFalse != 0,
                              child: Expanded(
                                flex: ((cashFalse / cashAll) * 100).toInt(),
                                child: Container(
                                  decoration: const BoxDecoration(color: Colors.red),
                                  child: Center(child: Text(cashFalse.toString())),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(),
                    const Text("Wheelchair accessible"),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      width: 500,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Visibility(
                              visible: wheelTrue != 0,
                              child: Expanded(
                                flex: ((wheelTrue / wheelAll) * 100).toInt(),
                                child: Container(
                                  decoration:
                                      const BoxDecoration(color: Colors.green),
                                  child: Center(child: Text(wheelTrue.toString())),
                                ),
                              ),
                            ),
                            Visibility(
                              visible: wheelMaybe != 0,
                              child: Expanded(
                                flex: ((wheelMaybe / wheelAll) * 100).toInt(),
                                child: Container(
                                  decoration: const BoxDecoration(color: Colors.grey),
                                  child: Center(child: Text(wheelMaybe.toString())),
                                ),
                              ),
                            ),
                            Visibility(
                              visible: wheelFalse != 0,
                              child: Expanded(
                                flex: ((wheelFalse / wheelAll) * 100).toInt(),
                                child: Container(
                                  decoration: const BoxDecoration(color: Colors.red),
                                  child: Center(child: Text(wheelFalse.toString())),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(),
                    const Text("Sound output available"),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      width: 500,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Visibility(
                              visible: soundTrue != 0,
                              child: Expanded(
                                flex: ((soundTrue / soundAll) * 100).toInt(),
                                child: Container(
                                  decoration:
                                      const BoxDecoration(color: Colors.green),
                                  child: Center(child: Text(soundTrue.toString())),
                                ),
                              ),
                            ),
                            Visibility(
                              visible: soundMaybe != 0,
                              child: Expanded(
                                flex: ((soundMaybe / soundAll) * 100).toInt(),
                                child: Container(
                                  decoration: const BoxDecoration(color: Colors.grey),
                                  child: Center(child: Text(soundMaybe.toString())),
                                ),
                              ),
                            ),
                            Visibility(
                              visible: soundFalse != 0,
                              child: Expanded(
                                flex: ((soundFalse / soundAll) * 100).toInt(),
                                child: Container(
                                  decoration: const BoxDecoration(color: Colors.red),
                                  child: Center(child: Text(soundFalse.toString())),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(),
                    // Wenn ein Nutzer nicht angemeldet ist, werden die Knöpfe ausgeblendet
                    FirebaseAuth.instance.currentUser != null ?

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Wenn der Nutzer bereits in der addedBy Liste steht, wird der Knopf ausgegraut und hat keinen Nutzen mehr
                        (widget.machine.addedBy
                                .contains(FirebaseAuth.instance.currentUser!.uid)
                            ? IconButton(
                                onPressed: () => {

                                    },
                                icon: const Icon(
                                  Icons.check,
                                  color: Colors.grey,
                                ))
                            : IconButton(
                                onPressed: () => {
                                  widget.validateThis(widget.machine),
                                  setState(() {})
                                },
                                icon: const Icon(Icons.check))),
                        IconButton(
                            onPressed: () => {
                                  showDialog(
                                    barrierDismissible: false,
                                    context: context,
                                    builder: (BuildContext context) => EditDialog(
                                      machine: widget.machine,
                                      applyUpdates: (machine) async {
                                        widget.applyUpdates(machine);
                                        setState(() {});
                                      },
                                    ),
                                  ),
                                  setState(() {})
                                },
                            icon: const Icon(Icons.edit)),
        
                        /// Wenn der Nutzer in der deletedBy-Liste ist, wird der Löschen-Knopf ausgegraut.
                        /// Falls er dennoch angeclickt wird, öffnet sich ein Info-Dialog
                        widget.machine.deletedBy
                                .contains(FirebaseAuth.instance.currentUser!.uid)
                            ? IconButton(
                                onPressed: () => {
                                      showDialog<void>(
                                        context: context,
                                        barrierDismissible:
                                            false, // user must tap button!
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: const Text(
                                                'You already invalidated this Vendingmachine'),
                                            content: SingleChildScrollView(
                                              child: ListBody(
                                                children: const <Widget>[
                                                  Text(
                                                      'If enough other People invalidate it, it will be deleted'),
                                                ],
                                              ),
                                            ),
                                            actions: <Widget>[
                                              TextButton(
                                                child: const Text('Ok'),
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                              ),
                                            ],
                                          );
                                        },
                                      )
                                    },
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.grey,
                                ))
                            : IconButton(
                                onPressed: () => {
                                      widget.deleteMachine(widget.machine),
                                      setState(
                                        () {},
                                      ),
                                      showDialog<void>(
                                        context: context,
                                        barrierDismissible:
                                            false, // user must tap button!
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: const Text(
                                                'You invalidated this Vendingmachine'),
                                            content: SingleChildScrollView(
                                              child: ListBody(
                                                children: const <Widget>[
                                                  Text(
                                                      'If enough other People invalidate it, it will be deleted'),
                                                ],
                                              ),
                                            ),
                                            actions: <Widget>[
                                              TextButton(
                                                child: const Text('Ok'),
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                              ),
                                            ],
                                          );
                                        },
                                      )
                                    },
                                icon: const Icon(Icons.delete)),
                      ],
                    ) : SizedBox(),
        
                    FirebaseAuth.instance.currentUser != null ?

                    /// Der Routing Knopf, der die im  widget mitgegebene startRouting-Methode ausführt
                    OutlinedButton(
                      style: ButtonStyle(
                          side: MaterialStateProperty.all<BorderSide>(
                            const BorderSide(
                                color: Colors.black), // Set the border color
                          ),
                          foregroundColor:
                              MaterialStateProperty.all<Color>(Colors.black),
                          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                              RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50)))),
                      onPressed: () {
                        showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return RoutingStartDialog(
                                startRouting: (travelMode) { startRouting(travelMode);},
                                );
                            });
                      },
                      child: SizedBox(
                        width: 150,
                        height: 50,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text("Route"),
                            SizedBox(width: 10),
                            Icon(Icons.directions),
                          ],
                        ),
                      ),
                    ): SizedBox(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
