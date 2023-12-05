import 'package:automatenfinder/filter.dart';
import 'package:automatenfinder/list_view.dart';
import 'package:automatenfinder/login.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'add_dialog.dart';
import 'app_state.dart';
import 'map_view.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(
            child: Consumer<ApplicationState>(builder: (context, appState, _) {
              return Stack(alignment: Alignment.center, children: [
                MapView(
                  verifiedmachines: appState.verifiedmachines,
                  unverifiedmachines: appState.unverifiedmachines,
                  validateThis: (machine) =>
                      appState.addValidationInstance(machine),
                  applyUpdates: (machine) =>
                      appState.applyVerificationUpdates(machine),
                  deleteMachine: (machine) =>
                      appState.addDeletionInstance(machine),
                ),
                Positioned(
                  bottom: 50,
                  child: Container(
                      decoration: BoxDecoration(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(20)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              spreadRadius: 0.2,
                              blurRadius: 3,
                              offset: const Offset(
                                  2, 2), // changes position of shadow
                            ),
                          ],
                          color: Colors.white),
                      width: MediaQuery.of(context).size.width * 0.8,
                      // Abhängig davon, ob eine Routenführung gestartet wurde oder nicht, werden andere Widgets angezeigt.
                      child: !appState.routingStarted
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                  (appState.loggedIn)
                                      ? SizedBox(
                                          height: 65,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              // Dieser Knopf ruft über showDialog() den Add_Dialog auf
                                              IconButton(
                                                  onPressed: () => {
                                                        showDialog(
                                                            barrierDismissible:
                                                                false,
                                                            context: context,
                                                            builder: (BuildContext
                                                                    context) =>
                                                                AddDialog(
                                                                  verifiedmachines:
                                                                      appState
                                                                          .verifiedmachines,
                                                                  unverifiedmachines:
                                                                      appState
                                                                          .unverifiedmachines,
                                                                  addNew: (machine) =>
                                                                      appState.addNewMachine(
                                                                          machine),
                                                                  checkMachineExistance:
                                                                      (machine) =>
                                                                          appState
                                                                              .checkMachineExistance(machine),
                                                                ))
                                                      },
                                                  icon: const Icon(Icons.add)),
                                              IconButton(
                                                  onPressed: () => {
                                                        showDialog(
                                                          barrierDismissible:
                                                              false,
                                                          context: context,
                                                          builder: (BuildContext
                                                                  context) =>
                                                              const FilterDialog(),
                                                        )
                                                      },
                                                  icon: const Icon(
                                                      Icons.filter_alt)),
                                              IconButton(
                                                  onPressed: () => {
                                                        showDialog(
                                                          barrierDismissible:
                                                              false,
                                                          context: context,
                                                          builder: (BuildContext
                                                                  context) =>
                                                              ListDialog(
                                                            verifiedmachines:
                                                                appState
                                                                    .verifiedmachines,
                                                            unverifiedmachines:
                                                                appState
                                                                    .unverifiedmachines,
                                                          ),
                                                        )
                                                      },
                                                  icon: const Icon(Icons.list)),
                                              const VerticalDivider(),
                                              LoginButton(
                                                  loggedIn: appState.loggedIn,
                                                  signOut: () {
                                                    FirebaseAuth.instance
                                                        .signOut();
                                                  }),
                                            ],
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            LoginButton(
                                                loggedIn: appState.loggedIn,
                                                signOut: () {
                                                  FirebaseAuth.instance
                                                      .signOut();
                                                }),
                                          ],
                                        )
                                ])
                          : null),
                )
              ]);
            }),
          ),
        ],
      ),
    );
  }
}
