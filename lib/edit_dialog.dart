import 'dart:async';

import 'package:automatenfinder/vendingmachine.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EditDialog extends StatefulWidget {
  EditDialog({
    super.key,
    required this.machine,
    required this.applyUpdates,
  });

  VendingMachine machine;
  final Future<void> Function(VendingMachine machine) applyUpdates;

  @override
  State<EditDialog> createState() => EditDialogState();
}

class EditDialogState extends State<EditDialog> {
  TextEditingController contentController = TextEditingController();

  final List<bool> _isSelected = [false];
  bool? prewheelchair;
  bool? precard;
  bool? precash;
  bool? presound;

  var selectedType;
  bool? wheelchair;
  bool? card;
  bool? cash;
  bool? sound;

  final _formKey = GlobalKey<FormState>(debugLabel: 'EditState');

  /// Bereitet alle eingegebenen Werte vor und ruft dann die ApplyUpdate-Funktion im AppState auf.
  VendingMachine editMachine() {
    MachineType selectedTypeAsMachineType;
    // Wenn kein Machinentyp ausgewählt wurde, wird der meist gewählte verwendet
    if(selectedType != null){
         selectedTypeAsMachineType  = selectedType as MachineType;
    }
    else{
      selectedTypeAsMachineType = widget.machine.type;
    }

    if (contentController.text.isNotEmpty) {
      // der AddedContent wird bei jedem Komma getrennt und es werden alle Leerzeichen entfernt. Dann wird daraus eine Liste gebildet
      List<String> addedContent =
          contentController.text.replaceAll(" ", "").split(",");
      addedContent.toSet().toList();
      //widget.machine.details[FirebaseAuth.instance.currentUser!.uid]!["Content"] = addedContent;
    }

    /// Bereitet den hinzugefügten Conten so vor, dass dieser als Liste gespeichert werden kann.
    List<String> addedContent =
        contentController.text.replaceAll(" ", "").split(",");
    addedContent.toSet().toList();
    widget.machine.details.addAll({
      FirebaseAuth.instance.currentUser!.uid: {
        'Card': card,
        'Cash': cash,
        'Wheelchair': wheelchair,
        'Sound': sound,
        'Content': addedContent,
        'Type': selectedTypeAsMachineType.name,
      }
    });
    widget.applyUpdates(widget.machine);


    /// Dieser Teil ist nötig, damit falls sich der meistgewertete Typ bei der editierung ändert, der offene MarkerDetails Dialog sich ebenfalls ändert
    /// Ansonsten würde dieser erst beim nächsten mal öffnen korrekt sein.
    Map<String, int> typeList = {};
    widget.machine.details.forEach((key1, value1) {
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

    String keyWithHighestValue = "";
    if (!typeList.values.any((element) => element > 1)) {
      keyWithHighestValue = widget.machine.details.entries.first.value['Type'];
    } else {
      keyWithHighestValue =
          typeList.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    }

    widget.machine.type = MachineType.values
        .firstWhere((element) => element.name == keyWithHighestValue);

    Navigator.of(context).pop();
    setState(() {});
    return widget.machine;
  }

  /// Entfernt alle Details und den addedBy eintrag des momentanen Nutzers aus dem jeweiligen Automaten 
  void removeValidation(){
    widget.machine.details.removeWhere((key, value) => key == FirebaseAuth.instance.currentUser!.uid);
    widget.machine.addedBy.removeWhere((element) => element == FirebaseAuth.instance.currentUser!.uid);
    Navigator.of(context).pop();
    setState(() {});
  }

  @override
  /// Falls der Nutzer den Automaten bereits validiert hat, werden seine bisher eingegebenen Daten hier automatisch ausgewählt
  void initState() {
    setState(() {
      if (widget.machine.addedBy
        .contains(FirebaseAuth.instance.currentUser!.uid)) {
      selectedType = MachineType.values
        .firstWhere((element) => element.name == widget
          .machine.details[FirebaseAuth.instance.currentUser!.uid]!["Type"]);
      cash = widget
          .machine.details[FirebaseAuth.instance.currentUser!.uid]!["Cash"];
      card = widget
          .machine.details[FirebaseAuth.instance.currentUser!.uid]!["Card"];
      wheelchair = widget
          .machine.details[FirebaseAuth.instance.currentUser!.uid]!["Wheelchair"];
      sound = widget
          .machine.details[FirebaseAuth.instance.currentUser!.uid]!["Sound"];
      List<dynamic> contentDynamic = widget.machine.details[FirebaseAuth.instance.currentUser!.uid]!["Content"];
      List<String> contentText = contentDynamic.map((e) => e.toString()).toList();
      contentController.text = contentText.join(", ");
    }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      child: SingleChildScrollView(
        child: Wrap(children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Stack(
                children: [
                  const Positioned(
                    top: 0,
                    right: 0,
                    child: CloseButton(),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        height: 50,
                        child: Center(
                            child: Text(
                          "Edit Machine",
                          style: TextStyle(fontSize: 17),
                        )),
                      ),
                      const Divider(),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            DropdownButtonFormField(
                              decoration: const InputDecoration(
                                hintText: 'Typ',
                              ),
                              value: selectedType,
                              items: MachineType.values.map((MachineType items) {
                                return DropdownMenuItem(
                                  value: items,
                                  child: Text(items.name),
                                );
                              }).toList(),
                              onChanged: (value) => {selectedType = value},
                            ),
                            const SizedBox(
                              width: 8,
                              height: 20,
                            ),
                            Row(
                              children: [
                                const Flexible(
                                    flex: 1,
                                    child: Text(
                                        style: TextStyle(
                                          color: Color.fromARGB(255, 98, 98, 98),
                                          fontSize: 15,
                                        ),
                                        "Content:")),
                                Flexible(
                                  flex: 3,
                                  child: Container(
                                    padding: const EdgeInsets.only(left: 20),
                                    child: TextFormField(
                                      controller: contentController,
                                      decoration: const InputDecoration(
                                          hintText:
                                              'Meat, Sausage, Beer, Wine, ...'),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(
                              width: 8,
                              height: 20,
                            ),
                            Container(
                              decoration: const BoxDecoration(
                                  color: Color.fromARGB(255, 255, 255, 255),
                                  border: Border(
                                      bottom: BorderSide(
                                          color: Colors.grey, width: 1))),
                              child: ExpansionPanelList(
                                elevation: 0,
                                expansionCallback: (int index, bool isExpanded) {
                                  setState(() {
                                    _isSelected[index] = !isExpanded;
                                  });
                                },
                                children: [
                                  ExpansionPanel(
                                    headerBuilder:
                                        (BuildContext context, bool isExpanded) {
                                      return const Center(child: Text("Details"));
                                    },
                                    isExpanded: _isSelected[0],
                                    body: Column(
                                      children: [
                                        const Divider(
                                          thickness: 1,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(
                                          height: 200,
                                          child: ListView(
                                            children: [
                                              Container(
                                                margin: const EdgeInsets.all(10),
                                                child: Row(
                                                  children: const [
                                                    SizedBox(
                                                      width: 100,
                                                    ),
                                                    Text("Yes"),
                                                    SizedBox(
                                                      width: 61,
                                                    ),
                                                    Text("No"),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                margin: const EdgeInsets.all(10),
                                                child: Row(
                                                  children: [
                                                    const SizedBox(
                                                        width: 70,
                                                        child:
                                                            Text("Card-payment")),
                                                    Expanded(
                                                      flex: 2,
                                                      child: ListTile(
                                                        leading: Radio<bool>(
                                                          value: true,
                                                          toggleable: true,
                                                          groupValue: card,
                                                          onChanged:
                                                              (bool? value) {
                                                            setState(() {
                                                              card = value;
                                                            });
                                                          },
                                                        ),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      flex: 2,
                                                      child: ListTile(
                                                        leading: Radio<bool>(
                                                          value: false,
                                                          toggleable: true,
                                                          groupValue: card,
                                                          onChanged:
                                                              (bool? value) {
                                                            setState(() {
                                                              card = value;
                                                            });
                                                          },
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const Divider(),
                                              Container(
                                                margin: const EdgeInsets.all(10),
                                                child: Row(
                                                  children: [
                                                    const SizedBox(
                                                        width: 70,
                                                        child:
                                                            Text("Cash-payment")),
                                                    Flexible(
                                                      flex: 2,
                                                      child: ListTile(
                                                        leading: Radio<bool>(
                                                          value: true,
                                                          toggleable: true,
                                                          groupValue: cash,
                                                          onChanged:
                                                              (bool? value) {
                                                            setState(() {
                                                              cash = value;
                                                            });
                                                          },
                                                        ),
                                                      ),
                                                    ),
                                                    Flexible(
                                                      flex: 2,
                                                      child: ListTile(
                                                        leading: Radio<bool>(
                                                          value: false,
                                                          toggleable: true,
                                                          groupValue: cash,
                                                          onChanged:
                                                              (bool? value) {
                                                            setState(() {
                                                              cash = value;
                                                            });
                                                          },
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const Divider(),
                                              Container(
                                                margin: const EdgeInsets.all(10),
                                                child: Row(
                                                  children: [
                                                    const SizedBox(
                                                        width: 70,
                                                        child: Text(
                                                            "Wheelchair accessible")),
                                                    Flexible(
                                                      flex: 2,
                                                      child: ListTile(
                                                        leading: Radio<bool>(
                                                          value: true,
                                                          toggleable: true,
                                                          groupValue: wheelchair,
                                                          onChanged:
                                                              (bool? value) {
                                                            setState(() {
                                                              wheelchair = value;
                                                            });
                                                          },
                                                        ),
                                                      ),
                                                    ),
                                                    Flexible(
                                                      flex: 2,
                                                      child: ListTile(
                                                        leading: Radio<bool>(
                                                          value: false,
                                                          toggleable: true,
                                                          groupValue: wheelchair,
                                                          onChanged:
                                                              (bool? value) {
                                                            setState(() {
                                                              wheelchair = value;
                                                            });
                                                          },
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const Divider(),
                                              Container(
                                                margin: const EdgeInsets.all(10),
                                                child: Row(
                                                  children: [
                                                    const SizedBox(
                                                        width: 70,
                                                        child: Text(
                                                            "Speech output")),
                                                    Flexible(
                                                      flex: 2,
                                                      child: ListTile(
                                                        leading: Radio<bool>(
                                                          value: true,
                                                          toggleable: true,
                                                          groupValue: sound,
                                                          onChanged:
                                                              (bool? value) {
                                                            setState(() {
                                                              sound = value;
                                                            });
                                                          },
                                                        ),
                                                      ),
                                                    ),
                                                    Flexible(
                                                      flex: 2,
                                                      child: ListTile(
                                                        leading: Radio<bool>(
                                                          value: false,
                                                          toggleable: true,
                                                          groupValue: sound,
                                                          onChanged:
                                                              (bool? value) {
                                                            setState(() {
                                                              sound = value;
                                                            });
                                                          },
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      Container(
                        margin: const EdgeInsets.all(15),
                        child: OutlinedButton(
                          style: ButtonStyle(
                              side: MaterialStateProperty.all<BorderSide>(
                                const BorderSide(
                                    color: Colors.black),
                              ),
                              foregroundColor:
                                  MaterialStateProperty.all<Color>(Colors.black),
                              shape:
                                  MaterialStateProperty.all<RoundedRectangleBorder>(
                                      RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(50)))),
                          onPressed: () {
                            try {
                              editMachine();
                            } catch (e) {
                              print(e);
                            }
                          },
                          child: SizedBox(
                            width: 150,
                            height: 50,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Text("Edit"),
                                SizedBox(width: 10),
                                Icon(Icons.edit),
                              ],
                            ),
                          ),
                        ),
                      ),
                      OutlinedButton(
                        style: ButtonStyle(
                            side: MaterialStateProperty.all<BorderSide>(
                              const BorderSide(
                                  color: Colors.black),
                            ),
                            foregroundColor:
                                MaterialStateProperty.all<Color>(Colors.black),
                            shape:
                                MaterialStateProperty.all<RoundedRectangleBorder>(
                                    RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(50)))),
                        onPressed: () {
                          try {
                            removeValidation();
                          } catch (e) {
                            print(e);
                          }
                        },
                        child: SizedBox(
                          width: 150,
                          height: 50,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text("Revoke Validation"),
                              SizedBox(width: 10),
                              Icon(Icons.delete),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
