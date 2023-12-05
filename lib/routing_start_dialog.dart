import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class RoutingStartDialog extends StatefulWidget {
  const RoutingStartDialog({
    super.key,
    required this.startRouting,
  });

  final void Function(TravelMode travelMode) startRouting;

  @override
  State<RoutingStartDialog> createState() => RoutingStartDialogState();
}

class RoutingStartDialogState extends State<RoutingStartDialog> {
  TravelMode? selectedMode = TravelMode.walking;

  // Eine Liste aller "Reise-Modi", also z.B. zu Fuß oder mit dem Auto
  // hier wird extra der TravelMode.transit (Öffentliche Verkehrsmittel) weggelassen, da dieser zu komplex für die momentane Version des Programmes ist
  List<TravelMode> travelModes = [
    TravelMode.walking,
    TravelMode.driving,
    TravelMode.bicycling
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
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
                        "Select Travel-type",
                        style: TextStyle(fontSize: 17),
                      )),
                    ),
                    const Divider(),
                    DropdownButtonFormField(
                      decoration: const InputDecoration(
                        hintText: 'Typ',
                      ),
                      value: selectedMode,
                      items: travelModes.map((TravelMode items) {
                        //
                        String finalItem = items.name[0].toUpperCase() +
                            items.name.substring(1);
                        return DropdownMenuItem(
                          value: items,
                          child: Text(finalItem),
                        );
                      }).toList(),
                      onChanged: (value) => {selectedMode = value},
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 15),
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
                        onPressed: () {
                          widget.startRouting(selectedMode!);
                          // zweimal, damit das MarkerDetail-Fenster auch verschwindet
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
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
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}
