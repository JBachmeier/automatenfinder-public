import 'package:automatenfinder/vendingmachine.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';

class FilterDialog extends StatefulWidget {
  const FilterDialog({
    super.key,
  });

  @override
  State<FilterDialog> createState() => FilterDialogState();
}

class FilterDialogState extends State<FilterDialog> {
  var selectedType;
  final List<bool> _isSelected = [false];
  bool? wheelchair;
  bool? card;
  bool? cash;
  bool? sound;
  String? isValidated = "All";
  List<String> validationSelector = [
    "All",
    "Validated only",
    "Nonvalidated only"
  ];

  void applyFilter() {
    
    // Der Notifier wird verwendet, um die Firebase-Subscriptions mit den neue gesetzten Filtern zu starten.
    // Dies wird mit dem ApplicationState Provider durchgeführt. Der Provider bietet eine einfache Möglichkeit kleine änderungen oder Funktionen im AppState durchzuführen, ohne diese als Properties an das Widget weiter geben zu müssen
    final myNotifier = Provider.of<ApplicationState>(context, listen: false);
    if (isValidated != "All") {
      if (isValidated == "Nonvalidated only") {
        myNotifier.updateUnverifiedSubscription(
            selectedType, card, cash, wheelchair, sound);
        myNotifier.cancelVerifiedSubscription();
      } else {
        myNotifier.updateVerifiedSubscription(
            selectedType, card, cash, wheelchair, sound);
        myNotifier.cancelUnverifiedSubscription();
      }
    } else {
      myNotifier.updateUnverifiedSubscription(
          selectedType, card, cash, wheelchair, sound);
      myNotifier.updateVerifiedSubscription(
          selectedType, card, cash, wheelchair, sound);
    }

    setState(() {});
  }

  /// Ruft den AppState-Notifier auf, um die Firestore-Subscriptions abzubrechen
  void removeFilter() {
    final myNotifier = Provider.of<ApplicationState>(context, listen: false);
    myNotifier.updateUnverifiedSubscription(null, null, null, null, null);
    myNotifier.updateVerifiedSubscription(null, null, null, null, null);
    setState(() {});
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
                          "Filter",
                          style: TextStyle(fontSize: 17),
                        )),
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: DropdownButtonFormField(
                              decoration: const InputDecoration(
                                hintText: 'Type',
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('All Types'),
                                ),
                                ...MachineType.values.map((MachineType items) {
                                  return DropdownMenuItem(
                                    value: items,
                                    child: Text(items.name),
                                  );
                                }).toList()
                              ],
                              onChanged: (value) => {selectedType = value},
                            ),
                          )
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: DropdownButtonFormField(
                              decoration: const InputDecoration(
                                hintText: 'Validation status',
                              ),
                              items: validationSelector.map((String item) {
                                return DropdownMenuItem(
                                  value: item,
                                  child: Text(item),
                                );
                              }).toList(),
                              onChanged: (value) => {isValidated = value},
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 10),
                        decoration: const BoxDecoration(
                            color: Color.fromARGB(255, 255, 255, 255),
                            border: Border(
                                bottom:
                                    BorderSide(color: Colors.grey, width: 1))),
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
                                  const Divider(thickness: 1, color: Colors.grey),
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
                                                  child: Text("Card-payment")),
                                              Expanded(
                                                flex: 2,
                                                child: ListTile(
                                                  leading: Radio<bool>(
                                                    value: true,
                                                    toggleable: true,
                                                    groupValue: card,
                                                    onChanged: (bool? value) {
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
                                                    onChanged: (bool? value) {
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
                                                  child: Text("Cash-payment")),
                                              Flexible(
                                                flex: 2,
                                                child: ListTile(
                                                  leading: Radio<bool>(
                                                    value: true,
                                                    toggleable: true,
                                                    groupValue: cash,
                                                    onChanged: (bool? value) {
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
                                                    onChanged: (bool? value) {
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
                                                    onChanged: (bool? value) {
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
                                                    onChanged: (bool? value) {
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
                                                  child: Text("Speech output")),
                                              Flexible(
                                                flex: 2,
                                                child: ListTile(
                                                  leading: Radio<bool>(
                                                    value: true,
                                                    toggleable: true,
                                                    groupValue: sound,
                                                    onChanged: (bool? value) {
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
                                                    onChanged: (bool? value) {
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
                      Container(
                        margin: const EdgeInsets.all(15),
                        child: OutlinedButton(
                          style: ButtonStyle(
                              side: MaterialStateProperty.all<BorderSide>(
                                const BorderSide(
                                    color: Colors.black), // Set the border color
                              ),
                              foregroundColor:
                                  MaterialStateProperty.all<Color>(Colors.black),
                              shape: MaterialStateProperty.all<
                                      RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(50)))),
                          onPressed: () async {
                            applyFilter();
                            Navigator.of(context).pop();
                          },
                          child: SizedBox(
                            width: 150,
                            height: 50,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Text("Apply Filter"),
                                SizedBox(width: 10),
                                Icon(Icons.filter_alt),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Container(
                        margin:const EdgeInsets.only(bottom: 10),
                        child: OutlinedButton(
                          style: ButtonStyle(
                              side: MaterialStateProperty.all<BorderSide>(
                                const BorderSide(
                                    color: Colors.black), // Set the border color
                              ),
                              foregroundColor:
                                  MaterialStateProperty.all<Color>(Colors.black),
                              shape: MaterialStateProperty.all<
                                      RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(50)))),
                          onPressed: () async {
                            removeFilter();
                            Navigator.of(context).pop();
                          },
                          child: SizedBox(
                            //margin: const EdgeInsets.only(top: 10),
                            width: 150,
                            height: 50,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Text("Remove Filter"),
                                SizedBox(width: 10),
                                Icon(Icons.filter_alt_off),
                              ],
                            ),
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
