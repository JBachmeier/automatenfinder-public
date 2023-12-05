import 'package:flutter/material.dart';
import 'vendingmachine.dart';

class ListDialog extends StatefulWidget {
  const ListDialog({
    super.key,
    required this.verifiedmachines,
    required this.unverifiedmachines,
  });

  final List<VendingMachine> verifiedmachines;
  final List<VendingMachine> unverifiedmachines;

  @override
  State<ListDialog> createState() => ListDialogState();
}

class ListDialogState extends State<ListDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            iconTheme: const IconThemeData(
              color: Colors.black,
            ),
            backgroundColor: Colors.white,
            bottom: const TabBar(
              tabs: [
                Tab(
                  icon: Icon(Icons.check),
                  text: "Verified",
                ),
                Tab(
                  icon: Icon(Icons.indeterminate_check_box),
                  text: "Unverified",
                ),
              ],
            ),
            title: const Text(
              'Vendinmachines',
              style: TextStyle(color: Colors.black),
            ),
          ),
          body: TabBarView(
            children: [

              // VERIFIED

              SingleChildScrollView(
                child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      // Geht durch jeden Verkaufsautomaten und erstellt einen Listeneintrag mit den entsprechenden Daten des Automaten
                      children: widget.verifiedmachines.map((e) {
                        return GestureDetector(
                          onTap: () {},
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              children: [
                                SizedBox(
                                  height: 50,
                                  child: Row(
                                    children: [
                                      SizedBox(
                                          width: 100,
                                          child: Text(e.type.name)),
                                      const VerticalDivider(),
                                      const SizedBox(width: 10),
                                      Expanded(child: Text(e.address)),
                                    ],
                                  ),
                                ),
                                const Divider(),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    )),
              ),

              // UNVERIFIED

              SingleChildScrollView(
                child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: widget.unverifiedmachines.map((e) {
                        return Container(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            children: [
                              SizedBox(
                                height: 50,
                                child: Row(
                                  children: [
                                    SizedBox(
                                        width: 100,
                                        child: Text(e.type.name)),
                                    const VerticalDivider(),
                                    const SizedBox(width: 10),
                                    Expanded(child: Text(e.address)),
                                  ],
                                ),
                              ),
                              const Divider(),
                            ],
                          ),
                        );
                      }).toList(),
                    )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
