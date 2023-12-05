import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:google_maps_webservice/geocoding.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

import 'vendingmachine.dart';

class AddDialog extends StatefulWidget {
  const AddDialog({
    super.key,
    required this.verifiedmachines,
    required this.unverifiedmachines,
    required this.addNew,
    required this.checkMachineExistance,
  });

  final FutureOr<void> Function(VendingMachine machine) addNew;
  final bool Function(VendingMachine machine) checkMachineExistance;

  final List<VendingMachine> verifiedmachines;
  final List<VendingMachine> unverifiedmachines;
  
  @override
  State<AddDialog> createState() => AddDialogState();
}

String apikey = "[KEY]";

class AddDialogState extends State<AddDialog> {
  final TextEditingController searchController = TextEditingController();
  TextEditingController contentController = TextEditingController();

  // ermöglicht die verwendung der von google zu verfügung gestellten Funktionen. Der API-Key wird für die "Abrechnung" benötigt.
  // Die meisten dieser Funktionen kosten nach mehrfacher benutzung einen kleinen Geldbeitrag
  GoogleMapsPlaces gmp = GoogleMapsPlaces(apiKey: apikey);
  GoogleMapsGeocoding gmg = GoogleMapsGeocoding(apiKey: apikey);

  var res;
  var selectedType;
  final List<bool> _isSelected = [false];
  bool? wheelchair;
  bool? card;
  bool? cash;
  bool? sound;

  Map<String, List<String>> content = {};

  String errorMessage = "";

  @override
  void initState() {
    super.initState();
    searchController.addListener(onSearchChanged);
  }

  void onSearchChanged() {
    final query = searchController.text;
    if (query.trim().isEmpty) {
      return;
    }
  }

  final formKey = GlobalKey<FormState>(debugLabel: 'AddState');

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 0, maxHeight: double.infinity),
        child: SingleChildScrollView(
          child: Wrap(
            children: [
              Padding(
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
                            "Adding new Machine",
                            style: TextStyle(fontSize: 17),
                          )),
                        ),
                        const Divider(),
                        Form(
                          key: formKey,
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    // Das TypeAheadFormField holt sich die vorschläge von der GoogleMapsPlaces-API, indem der eingegebene String, jedes mal wenn sich dieser ändert, an die API gesendet wird.
                                    // Diese werden dann unter der Eingabe als vorschläge angezeigt
                                    child: TypeAheadFormField(
                                      textFieldConfiguration: TextFieldConfiguration(
                                        controller: searchController,
                                        decoration: const InputDecoration(
                                          hintText: 'Address',
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'input an Address';
                                        }
                                        return null;
                                      },
                                      suggestionsCallback: (pattern) {
                                        return gmp
                                            .autocomplete(pattern)
                                            .then((results) {
                                          return res = results.predictions;
                                        });
                                      },
                                      itemBuilder: (context, suggestion) {
                                        return ListTile(
                                          leading: const Icon(Icons.location_pin),
                                          title: Text(suggestion.description ?? ""),
                                        );
                                      },
                                      // Wenn einer der Vorschläge angetippt wird, wird dieser als momentaner Eingabestring gesetzt.
                                      onSuggestionSelected: (suggestion) {
                                        searchController.text =
                                            suggestion.description.toString();
                                      },
                                    ),
                                  ),
                                  // Hier wird der momentane Standort des Nutzers zur Adresse umgewandelt und in den Adressen-String eingefügt
                                  IconButton(onPressed: () async {
                                    String currlocAsAddress = "";
                                    var currloc = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
                                    Location currentLocation = Location(lat: currloc.latitude, lng: currloc.longitude);
                                    GeocodingResponse response = await gmg.searchByLocation(currentLocation);
                                    if (response.results.isNotEmpty) {
                                      currlocAsAddress = response.results.first.formattedAddress ?? "";
                                    }
                                    searchController.text = currlocAsAddress;
                                  }, icon:  const Icon(Icons.my_location))
                                ],
                              ),
                              const SizedBox(
                                width: 8,
                                height: 20,
                              ),
                              DropdownButtonFormField(
                                decoration: const InputDecoration(
                                  hintText: 'Type',
                                ),
                                items:
                                    MachineType.values.map((MachineType items) {
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
                                            color: Color.fromARGB(
                                                255, 98, 98, 98),
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
                              Container(
                                margin: const EdgeInsets.only(top: 10),
                                decoration: const BoxDecoration(
                                    color: Color.fromARGB(255, 255, 255, 255),
                                    border: Border(
                                        bottom: BorderSide(
                                            color: Colors.grey, width: 1))),
                                // Das ExpansionPanelList wird verwendet, um die auswählbaren Details zu verstecken, um den Add-Dialog etwas kompackter zu halten
                                child: ExpansionPanelList(
                                  elevation: 0,
                                  expansionCallback:
                                      (int index, bool isExpanded) {
                                    setState(() {
                                      _isSelected[index] = !isExpanded;
                                    });
                                  },
                                  children: [
                                    ExpansionPanel(
                                      headerBuilder: (BuildContext context,
                                          bool isExpanded) {
                                        return const Center(
                                            child: Text("Details"));
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
                                                  margin:
                                                      const EdgeInsets.all(10),
                                                  child: Row(
                                                    children: const [
                                                      SizedBox(
                                                        width: 102,
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
                                                  margin:
                                                      const EdgeInsets.all(10),
                                                  child: Row(
                                                    children: [
                                                      const SizedBox(
                                                          width: 70,
                                                          child: Text(
                                                              "Card-payment")),
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
                                                  margin:
                                                      const EdgeInsets.all(10),
                                                  child: Row(
                                                    children: [
                                                      const SizedBox(
                                                          width: 70,
                                                          child: Text(
                                                              "Cash-payment")),
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
                                                  margin:
                                                      const EdgeInsets.all(10),
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
                                                            groupValue:
                                                                wheelchair,
                                                            onChanged:
                                                                (bool? value) {
                                                              setState(() {
                                                                wheelchair =
                                                                    value;
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
                                                            groupValue:
                                                                wheelchair,
                                                            onChanged:
                                                                (bool? value) {
                                                              setState(() {
                                                                wheelchair =
                                                                    value;
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
                                                  margin:
                                                      const EdgeInsets.all(10),
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
                        // ErrorMessage wird nur angezeigt, wenn der String auch nicht leer ist, andernfalls wird nur eine SizedBox um korrektes Padding zu erzeugen, gerendert
                        if (errorMessage.isEmpty)
                          const SizedBox(
                            height: 15,
                          ),
                        if (errorMessage.isNotEmpty)
                          SizedBox(
                            height: 30,
                            child: Center(
                                child: Text(errorMessage,
                                    style: const TextStyle(color: Colors.red))),
                          ),
                        OutlinedButton(
                          style: ButtonStyle(
                              side: MaterialStateProperty.all<BorderSide>(
                                const BorderSide(
                                    color:
                                        Colors.black), // Set the border color
                              ),
                              foregroundColor: MaterialStateProperty.all<Color>(
                                  Colors.black),
                              shape: MaterialStateProperty.all<
                                      RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(50)))),
                          onPressed: () async {
                            if (searchController.text.isNotEmpty) {
                              GeocodingResponse? response;
                              try {
                                // Hier wird die eingegebene Adresse in Geokoordinaten umgewandelt
                                response = await gmg
                                    .searchByAddress(searchController.text);
                                GeoPoint location = GeoPoint(
                                    response
                                        .results.first.geometry.location.lat,
                                    response
                                        .results.first.geometry.location.lng);

                                MachineType selectedMachineType =
                                    selectedType as MachineType;
                                List<String> addedByList = [];
                                addedByList.add(
                                    FirebaseAuth.instance.currentUser!.uid);
                                List<String> addedContent = contentController
                                    .text
                                    .replaceAll(" ", "")
                                    .split(",");

                                addedContent.toSet().toList();

                                Map<String, Map<String, dynamic>> details = {
                                  FirebaseAuth.instance.currentUser!.uid: {
                                    'Card': card,
                                    'Cash': cash,
                                    'Wheelchair': wheelchair,
                                    'Sound': sound,
                                    'Content': addedContent,
                                    'Type': selectedMachineType.name
                                  }
                                };

                                VendingMachine newMachine = VendingMachine(
                                    type: selectedMachineType,
                                    geodata: location,
                                    address: searchController.text,
                                    addedBy: addedByList,
                                    deletedBy: [],
                                    verified: false,
                                    details: details);

                                // Zuletzt wird die Existenz der neuen Machine geprüft, also ob hier bereits eine Machine existiert oder nicht
                                if (!widget.checkMachineExistance(newMachine)) {
                                  widget.addNew(newMachine);
                                  Navigator.of(context).pop();
                                }
                                
                              } catch (e) {
                                setState(() {
                                  errorMessage = "Not a valid address!";
                                });
                              }
                            } else {
                              setState(() {
                                errorMessage = "Please input an address!";
                              });
                            }
                          },
                          child: SizedBox(
                            //margin: const EdgeInsets.only(top: 10),
                            width: 150,
                            height: 50,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Text("Add"),
                                SizedBox(width: 10),
                                Icon(Icons.add_location),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
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
