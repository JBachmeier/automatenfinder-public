// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:geometry_kit/geometry_kit.dart';

import 'package:automatenfinder/app_state.dart';
import 'package:automatenfinder/routingdetail.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:google_maps_webservice/directions.dart' as d;
import 'package:google_maps_webservice/geocoding.dart';
import 'package:location/location.dart' as loc;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart' as poly;
import 'package:provider/provider.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as tk;

import 'list_view.dart';
import 'markerdetail.dart';
import 'vendingmachine.dart';

import 'package:geolocator/geolocator.dart';

class MapView extends StatefulWidget {
  const MapView({
    super.key,
    required this.verifiedmachines,
    required this.unverifiedmachines,
    required this.validateThis,
    required this.applyUpdates,
    required this.deleteMachine,
  });

  final List<VendingMachine> verifiedmachines;
  final List<VendingMachine> unverifiedmachines;
  final Future<void> Function(VendingMachine machine) validateThis;
  final Future<void> Function(VendingMachine machine) applyUpdates;
  final Future<void> Function(VendingMachine machine) deleteMachine;

  @override
  State<MapView> createState() => MapViewState();
}

String apikey = "[KEY]";

// Die Einstellungen für die Routenplanung
const LocationSettings locationSettings = LocationSettings(
  accuracy: LocationAccuracy.bestForNavigation,
  distanceFilter: 0,
);

BitmapDescriptor locationMarkerIcon = BitmapDescriptor.defaultMarker;
BitmapDescriptor foodMarkerIcon = BitmapDescriptor.defaultMarker;
BitmapDescriptor bevMarkerIcon = BitmapDescriptor.defaultMarker;
BitmapDescriptor cigMarkerIcon = BitmapDescriptor.defaultMarker;
BitmapDescriptor coffeeMarkerIcon = BitmapDescriptor.defaultMarker;
BitmapDescriptor tobacMarkerIcon = BitmapDescriptor.defaultMarker;
BitmapDescriptor candyMarkerIcon = BitmapDescriptor.defaultMarker;
BitmapDescriptor miscMarkerIcon = BitmapDescriptor.defaultMarker;
BitmapDescriptor valfoodMarkerIcon = BitmapDescriptor.defaultMarker;
BitmapDescriptor valbevMarkerIcon = BitmapDescriptor.defaultMarker;
BitmapDescriptor valcigMarkerIcon = BitmapDescriptor.defaultMarker;
BitmapDescriptor valcoffeeMarkerIcon = BitmapDescriptor.defaultMarker;
BitmapDescriptor valtobacMarkerIcon = BitmapDescriptor.defaultMarker;
BitmapDescriptor valcandyMarkerIcon = BitmapDescriptor.defaultMarker;
BitmapDescriptor valmiscMarkerIcon = BitmapDescriptor.defaultMarker;

class MapViewState extends State<MapView> {
  StreamSubscription<loc.LocationData>? locationSubscription;
  StreamSubscription<Position>? positionStream;

  late GoogleMapController mapController;

  String? currlocAsAddress;
  LatLng showLocation = const LatLng(0, 0);
  Set<Marker> markers = {};
  bool loaded = false;
  d.GoogleMapsDirections directionsAPI = d.GoogleMapsDirections(apiKey: apikey);
  GoogleMapsGeocoding gmg = GoogleMapsGeocoding(apiKey: apikey);
  Map<PolylineId, Polyline> polylines = {}; //polylines to show direction
  poly.PolylinePoints polylinePoints = poly.PolylinePoints();

  String startingAddress = "";
  String destinationAddress = "";
  String travelTime = "";
  String travelDistance = "";

  Position? currloc;
  poly.PointLatLng? closestPoint;

  ListDialogState listView = ListDialogState();

  Set<Polyline> directionlinesnull = {};

  bool routingStarted = false;
  bool locationTracking = false;
  bool cameraMovedByUser = false;

  @override
  void initState() {
    super.initState();
    addCustomIcon();
    markers = Set<Marker>.from(getAllMarker());
  }

  /// Holt sich aus den jeweiligen VendingMachine-Listen die Werte und erzeugt dem entsprechende Marker
  Set<Marker> getAllMarker() {
    Set<Marker> allmarkers = {};
    Marker? user;

    // Da sich die Marker neu generieren, wenn sie verändert werden muss, bevor die alten gelöscht werden, der momentane User Marker gespeichert werden.
    // Dies ist nur nötig, wenn im moment eine Routenführung im gange ist, denn wenn nicht, sollte der Marker sowieso nicht angezeigt werden
    if (markers.any((element) => element.markerId.value == "User")) {
      user = markers.firstWhere((element) => element.markerId.value == "User");
    }
    if (user != null) {
      allmarkers.add(user);
    }
    for (var machine in widget.verifiedmachines) {
      // Zur sicherheit wird anfangs das Icon blau gemacht
      BitmapDescriptor icon = BitmapDescriptor.defaultMarkerWithHue(213);

      // Abhängig des Automatentypen wird ein anderer Marker verwendet
      switch (machine.type.name) {
        case "Food":
          icon = valfoodMarkerIcon;
          break;
        case "Beverages":
          icon = valbevMarkerIcon;
          break;
        case "Cigarettes":
          icon = valcigMarkerIcon;
          break;
        case "Coffee":
          icon = valcoffeeMarkerIcon;
          break;
        case "Snacks":
          icon = valcandyMarkerIcon;
          break;
        case "Miscellaneous":
          icon = valmiscMarkerIcon;
          break;
        default:
          // Falls aus irgendeinem Grund kein Typ zugewiesen werden konnte, wird der Marker Blau gefärbt
          icon = BitmapDescriptor.defaultMarkerWithHue(213);
      }

      // Hier zeichnet sich schon das erste große Problem ab. Die GeoDaten der verschiedenen Pakete müssen immer umgewandelt werden, so dass sie von anderen Paketen akzeptiert werden.
      double lat = machine.geodata.latitude;
      double lon = machine.geodata.longitude;
      allmarkers.add(Marker(
        markerId: MarkerId(machine.id!),
        icon: icon,
        position: LatLng(lat, lon),
        onTap: () => {showMarkerInfo(machine)},
      ));
    }

    for (var machine in widget.unverifiedmachines) {
      BitmapDescriptor icon = BitmapDescriptor.defaultMarkerWithHue(213);

      /// Abhängig des Typen wird das korrekte Icon gesetzt
      switch (machine.type.name) {
        case "Food":
          icon = foodMarkerIcon;
          break;
        case "Beverages":
          icon = bevMarkerIcon;
          break;
        case "Cigarettes":
          icon = cigMarkerIcon;
          break;
        case "Coffee":
          icon = coffeeMarkerIcon;
          break;
        case "Snacks":
          icon = candyMarkerIcon;
          break;
        case "Miscellaneous":
          icon = miscMarkerIcon;
          break;
        default:
          // Falls aus irgendeinem Grund kein Typ zugewiesen werden konnte, wird der Marker Blau gefärbt
          icon = BitmapDescriptor.defaultMarkerWithHue(213);
      }

      double lat = machine.geodata.latitude;
      double lon = machine.geodata.longitude;
      allmarkers.add(Marker(
        markerId: MarkerId(machine.id!),
        position: LatLng(lat, lon),
        icon: icon,
        onTap: () => {showMarkerInfo(machine)},
      ));
    }

    return allmarkers;
  }

  /// Zeigt einen Dialog mit allen Daten zum Automaten, und Buttons um den automaten zu validieren, oder anzupassen
  void showMarkerInfo(VendingMachine machine) {
    GlobalKey<State<StatefulWidget>> dialogKey = GlobalKey();
    showDialog(
        barrierDismissible: true,
        context: context,
        builder: (BuildContext context) {
          return MarkerDetail(
            key: dialogKey,
            machine: machine,
            validateThis: (machine) {
              return widget.validateThis(machine);
            },
            startRouting: (machine, travelMode) {
              return startRouting(machine, travelMode);
            },
            applyUpdates: (machine) {
              return widget.applyUpdates(machine);
            },
            deleteMachine: (machine) {
              return widget.deleteMachine(machine);
            },
          );
        });
  }

  /// Starten eine Subscription mit der aktuellen Position des Nutzers. Diese wird jedes mal abgefragt, wenn sich der Nutzer eine bestimmte Distanz bewegt.
  Future<Position?> getCurrentLocationAsPosition() async {
    await Geolocator.checkPermission();
    await Geolocator.requestPermission();
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  /// Wandelt die mit getCurrentLocationAsPosition() geholte Position, in ein LatLng-Objekt um.
  LatLng getCurrentPositionAsLatLng() {
    return LatLng(currloc!.latitude, currloc!.longitude);
  }

  Future<String?> getCurrentAddress() async {

    Location currentLocation = Location(lat: currloc!.latitude, lng: currloc!.longitude);
    GeocodingResponse response = await gmg.searchByLocation(currentLocation);
    if (response.results.isNotEmpty) {
      return response.results.first.formattedAddress ?? "";
    } else {
      String latitude = currloc!.latitude.toString();
      String longitude = currloc!.longitude.toString();
      return "$latitude; $longitude";
    }
  }

  /// Dieses promise wird benötigt, um zu versichern dass die Karte erst geladen wird, wenn der Standort des Nutzers und alle Marker geladen sind
  Future<Set<Marker>> makePromise() async {
    currloc = await getCurrentLocationAsPosition();
    showLocation = getCurrentPositionAsLatLng();
    loaded = true;
    markers = Set<Marker>.from(getAllMarker());
    return markers;
  }

  /// Fügt alle Marker-Bilder als Bitmap-Icons hinzu
  Future<void> addCustomIcon() async {
    ByteData locationMarker = await rootBundle.load('lib/assets/Marker.png');
    Uint8List locationMarkerData = locationMarker.buffer.asUint8List();
    locationMarkerIcon = BitmapDescriptor.fromBytes(locationMarkerData);

    ByteData foodMarker = await rootBundle.load('lib/assets/FoodMarker.png');
    Uint8List foodMarkerData = foodMarker.buffer.asUint8List();
    foodMarkerIcon = BitmapDescriptor.fromBytes(foodMarkerData);

    ByteData bevMarker = await rootBundle.load('lib/assets/BeverageMarker.png');
    Uint8List bevMarkerData = bevMarker.buffer.asUint8List();
    bevMarkerIcon = BitmapDescriptor.fromBytes(bevMarkerData);

    ByteData cigMarker =
        await rootBundle.load('lib/assets/CigaretteMarker.png');
    Uint8List cigMarkerData = cigMarker.buffer.asUint8List();
    cigMarkerIcon = BitmapDescriptor.fromBytes(cigMarkerData);

    ByteData coffeeMarker =
        await rootBundle.load('lib/assets/CoffeeMarker.png');
    Uint8List coffeeMarkerData = coffeeMarker.buffer.asUint8List();
    coffeeMarkerIcon = BitmapDescriptor.fromBytes(coffeeMarkerData);

    ByteData candyMarker = await rootBundle.load('lib/assets/CandyMarker.png');
    Uint8List candyMarkerData = candyMarker.buffer.asUint8List();
    candyMarkerIcon = BitmapDescriptor.fromBytes(candyMarkerData);

    ByteData miscMarker = await rootBundle.load('lib/assets/MiscMarker.png');
    Uint8List miscMarkerData = miscMarker.buffer.asUint8List();
    miscMarkerIcon = BitmapDescriptor.fromBytes(miscMarkerData);

    ByteData valfoodMarker =
        await rootBundle.load('lib/assets/FoodMarkerVal.png');
    Uint8List valfoodMarkerData = valfoodMarker.buffer.asUint8List();
    valfoodMarkerIcon = BitmapDescriptor.fromBytes(valfoodMarkerData);

    ByteData valbevMarker =
        await rootBundle.load('lib/assets/BeverageMarkerVal.png');
    Uint8List valbevMarkerData = valbevMarker.buffer.asUint8List();
    valbevMarkerIcon = BitmapDescriptor.fromBytes(valbevMarkerData);

    ByteData valcigMarker =
        await rootBundle.load('lib/assets/CigaretteMarkerVal.png');
    Uint8List valcigMarkerData = valcigMarker.buffer.asUint8List();
    valcigMarkerIcon = BitmapDescriptor.fromBytes(valcigMarkerData);

    ByteData valcoffeeMarker =
        await rootBundle.load('lib/assets/CoffeeMarkerVal.png');
    Uint8List valcoffeeMarkerData = valcoffeeMarker.buffer.asUint8List();
    valcoffeeMarkerIcon = BitmapDescriptor.fromBytes(valcoffeeMarkerData);

    ByteData valcandyMarker =
        await rootBundle.load('lib/assets/CandyMarkerVal.png');
    Uint8List valcandyMarkerData = valcandyMarker.buffer.asUint8List();
    valcandyMarkerIcon = BitmapDescriptor.fromBytes(valcandyMarkerData);

    ByteData valmiscMarker =
        await rootBundle.load('lib/assets/MiscMarkerVal.png');
    Uint8List valmiscMarkerData = valmiscMarker.buffer.asUint8List();
    valmiscMarkerIcon = BitmapDescriptor.fromBytes(valmiscMarkerData);
  }

  /// Fügt die Polyline in die Polyline-Map ein, welche in die Karte eingefügt wird.
  addPolyLine(
      String idString, List<LatLng> polylineCoordinates, Color linecolor) {
    PolylineId id = PolylineId(idString);
    Polyline polyline = Polyline(
      polylineId: id,
      color: linecolor,
      points: polylineCoordinates,
      width: 8,
    );
    polylines[id] = polyline;
    setState(() {});
  }

  /// Berechnet die linien zwischen Startpunk zu momentanen Standort und momentaner Standort zu Endpunkt.
  /// Diese werden dann in eine Jeweilige Polyline-Liste hinzugefügt, welche in der Karte angezeigt wird.
  ///
  /// Um den Fortschritt auf der Route zu berechnen wird der näheste Punkt zum momentanen Standort berechnet, und die Liste aller Punkte dann an dieser Stelle geteilt.
  Future<void> calculatePolyline(poly.PolylineResult startToDestination) async {
    // Initialisierung von drei leeren Listen, die später für die Koordinaten der Polylines verwendet werden
    List<LatLng> startToEndPolylineCoordinates = [];
    List<LatLng> startToCurrentPolylineCoordinates = [];
    List<LatLng> currentToEndPolylineCoordinates = [];

    num smallestDistanceToPoint = double.infinity;
    int index = 0;

    // Zunächst wird geprüft, ob die Polyline-Liste nicht leer ist
    if (startToDestination.points.isNotEmpty) {
      // Dann wird durch alle Punkte in der Liste iteriert
      for (int i = 0; i < startToDestination.points.length; i++) {
        // Für jeden Punkt wird eine neue Koordinate zur startToEndPolylineCoordinates-Liste hinzugefügt. Dies ist nötig, da das Polyline Objekt für die Google Map nicht das gleiche Polyline Objekt wie in der PolylineResult-Liste
        startToEndPolylineCoordinates.add(LatLng(
            startToDestination.points[i].latitude,
            startToDestination.points[i].longitude));

        // Dann wird der Abstand zwischen dem momentante Punkt und dem Standort des Nutzers berechnet. Diese wird ebenfalls durch die vom maps_toolkit Paket bereitgestellte computeDistanceBetween Funktion berechnet.
        // Obwohl im späteren verlauf es dennoch nötig ist, mit der getCurrLocOnRoute-Funktion den momentane Standort auf der Route zu berechnen, muss hier der nächste Punkt zum Nutzer berechnet werden,
        // um den spätere berechneten momentanen Punkt auf der Route, auch an die richtige stelle in der Liste zu setzen.
        num distance = tk.SphericalUtil.computeDistanceBetween(
            tk.LatLng(currloc!.latitude, currloc!.longitude),
            tk.LatLng(startToDestination.points[i].latitude,
                startToDestination.points[i].longitude));

        // Wenn der Abstand kleiner ist als der aktuell gespeicherte Wert in smallestDistanceToPoint, wird der Abstand und der Index des Punktes gespeichert.
        if (distance < smallestDistanceToPoint) {
          smallestDistanceToPoint = distance;
          index = i;
        }
      }
    } else {
      print(startToDestination.errorMessage);
    }

    // Nach der Berechnung der startToEndPolylineCoordinates-Liste wird eine Teilmenge dieser Liste als startToCurrentPolylineCoordinates gespeichert. Dies erfolgt durch die sublist()-Funktion, die den Teil der Liste zwischen den Indizes 0 und index zurückgibt.
    startToCurrentPolylineCoordinates =
        startToEndPolylineCoordinates.sublist(0, index);

    // Anschließend wird die Koordinate des aktuellen Standorts auf der Route mithilfe der getCurrLocOnRoute()-Funktion berechnet und der startToCurrentPolylineCoordinates-Liste hinzugefügt.
    LatLng currentPointOnRoute = getCurrLocOnRoute(startToDestination.points);
    startToCurrentPolylineCoordinates.add(currentPointOnRoute);

    // Die berechnete Koordinate wird dann auch als erster Punkt der currentToEndPolylineCoordinates-Liste hinzugefügt.
    currentToEndPolylineCoordinates.add(currentPointOnRoute);

    // Dann werden die Restlichen Punkte zu der currentToEndPolylineCoordinates-Liste hinzugefügt.
    currentToEndPolylineCoordinates
        .addAll(startToEndPolylineCoordinates.sublist(index + 1));

    // Zuletzt werden die beiden Listen als Polylines mit unterschiedlichen Farben in die Karte eingefügt.
    addPolyLine("start", startToCurrentPolylineCoordinates, Colors.grey);
    addPolyLine("end", currentToEndPolylineCoordinates, Colors.blue);
  }

  poly.PointLatLng getClosestPointOnLine(poly.PointLatLng location,
      poly.PointLatLng point1, poly.PointLatLng point2) {
    // Zunächst werden die Koordinaten der Punkte in Variablen x, y, x1, y1, x2 und y2 gespeichert.
    double x = location.longitude;
    double y = location.latitude;
    double x1 = point1.longitude;
    double y1 = point1.latitude;
    double x2 = point2.longitude;
    double y2 = point2.latitude;

    // Dann werden die Parameter A, B, C und D berechnet. A und B sind die Koordinaten-Abstände zwischen location und point1, C und D sind die Koordinaten-Abstände zwischen point1 und point2.
    double A = x - x1;
    double B = y - y1;
    double C = x2 - x1;
    double D = y2 - y1;

    // Das Skalarprodukt und die Länge des Vektors lensq werden berechnet.
    double skalar = A * C + B * D;
    double lensq = C * C + D * D;

    // Der Parameter projFak wird berechnet, indem das Skalarprodukt durch die Länge des Vektors geteilt wird.
    double projFak = skalar / lensq;

    double xx, yy;

    // Wenn projFak kleiner als 0 ist oder point1 und point2 den gleichen Punkt darstellen, wird der Punkt point1 als der nächstgelegene Punkt zurückgegeben.
    if (projFak < 0 || (x1 == x2 && y1 == y2)) {
      xx = x1;
      yy = y1;
    }
    // Wenn projFak größer als 1 ist, wird der Punkt point2 als der nächstgelegene Punkt zurückgegeben.
    else if (projFak > 1) {
      xx = x2;
      yy = y2;
    }
    // Andernfalls wird der Hoehenfusspunkt xx und yy berechnet, indem x1 und y1 zu projFak multipliziert mit C und D addiert werden, indem zu den Koordinaten von point1 der Abstand zum Hoehenfusspunkt addiert wird. Dieser Abstand wird durch das Produkt aus dem Projektionsfaktor und der Distanz der Punkte point1 und point2
    else {
      xx = x1 + projFak * C;
      yy = y1 + projFak * D;
    }

// Schließlich wird der Punkt xx und yy als der nächstgelegene Punkt auf der Linie zurückgegeben.
    return poly.PointLatLng(yy, xx);
  }

  LatLng getCurrLocOnRoute(List<poly.PointLatLng> points) {
    num closest = double.infinity;
    closestPoint = points.first;
    // Iteriert durch jedes Paar von aufeinanderfolgenden Punkten in der Liste ''points''.
    // In jeder Iteration wird getClosestPointOnLine aufgerufen, um den nächsten Punkt auf der Linie zwischen den beiden Punkten und dem gegebenen Standort currloc zu finden. Dazu werden die Punkte point1 und point2 in poly.PointLatLng Objekten gespeichert.
    for (var i = 0; i < points.length - 1; i++) {
      poly.PointLatLng point1 = points[i];
      poly.PointLatLng point2 = points[i + 1];
      poly.PointLatLng pointOnRoute = getClosestPointOnLine(
          poly.PointLatLng(currloc!.latitude, currloc!.longitude),
          point1,
          point2);
      // Die Entfernung d zwischen dem gefundenen Punkt auf der Route und dem gegebenen Standort currloc wird mit der Funktion tk.SphericalUtil.computeDistanceBetween berechnet.
      // Diese Funktion wird durch das maps_toolkit Paket bereitgestellt und berechnet die Distanz zweier Punkte auf der Erd-Kugel
      num d = tk.SphericalUtil.computeDistanceBetween(
          tk.LatLng(currloc!.latitude, currloc!.longitude),
          tk.LatLng(pointOnRoute.latitude, pointOnRoute.longitude));
      // Wenn die Entfernung d kleiner als die Variable closest ist, wird closest auf den Wert von d aktualisiert, und closestPoint wird auf den gefundenen Punkt auf der Route gesetzt.
      if (d < closest) {
        closest = d;
        closestPoint = pointOnRoute;
      }
    }

    /// Die setState-Funktion löst ein erneutes Laden der UI aus
    setState(() {
      // Erst wird der User-Marker entfernt
      markers.removeWhere((marker) => marker.markerId.value == "User");

      // Dann wird der neue User-Marker hinzugefügt. Hierfür werden die Koordniaten des Punktes verwendet, der in relation zum Nutzer, am nächsten auf der Route liegt
      Marker userMarker = Marker(
        markerId: const MarkerId("User"),
        icon: locationMarkerIcon,
        position: LatLng(closestPoint!.latitude, closestPoint!.longitude),
      );
      markers.add(userMarker);

      // Falls locationTracking an ist, wird die Kamera immer auf den neuesten Nutzer-Punkt auf der Route gesetzt
      // Dies ist dafür da, damit der Nutzer immer seinen momentanen Standort im Fokus hat.
      if (locationTracking) {
        mapController.animateCamera(CameraUpdate.newCameraPosition(
            CameraPosition(
                target: LatLng(userMarker.position.latitude,
                    userMarker.position.longitude),
                zoom: 18)));
      }
    });

    // Am Ende wird das LatLng Objekt des gefundenen Punkts zurückgegeben.
    return LatLng(closestPoint!.latitude, closestPoint!.longitude);
  }

  /// Berechnet den kürzesten Abstand des Standorts zu allen Polylinien. Falls dieser zu hoch ist, wird false wiedergegeben
  bool checkDistanceToRoute(List<poly.PointLatLng> points) {
    double closestPoint = 1000;
    for (var i = 0; i < points.length - 1; i++) {
      double distance = calculateDistanceToLine(
          points[i].latitude,
          points[i].longitude,
          points[i + 1].latitude,
          points[i + 1].longitude,
          currloc?.latitude,
          currloc?.longitude);
      if (closestPoint > distance) {
        closestPoint = distance;
      }
    }
    return (closestPoint < 1000);
  }

  /// Berechnet den kürzesten Abstand eines Punktes zu einer Linie anhand von Koodinaten
  double calculateDistanceToLine(lat1, lon1, lat2, lon2, lat3, lon3) {
    Line line = Line(Point<num>(lat1, lon1), Point<num>(lat2, lon2));
    Point<num> point = Point(lat3, lon3);
    return LineUtils.pointToLineDistance(point, line);
  }

  /// Ruft die RoutingAPI auf und gibt eine Liste an Punkten entlang der Route wieder
  /// Die Punkte werden entsprechend des verwendeten TravelModes geladen
  Future<poly.PolylineResult> calculateRoute(
      VendingMachine machine, poly.TravelMode travelMode) async {
    poly.PolylineResult startToDestination =
        await polylinePoints.getRouteBetweenCoordinates(
      apikey,
      poly.PointLatLng(currloc?.latitude ?? 0, currloc?.longitude ?? 0),
      poly.PointLatLng(machine.geodata.latitude, machine.geodata.longitude),
      travelMode: travelMode,
    );
    return startToDestination;
  }

  /// Startet das Routing zu einem Zielpunkt.
  /// der momentane Standpunkt wird per subscription bei jeder änderung neu aufgerufen und die Route wird dann mithilfe der calculatePolylines-Funktion berechnet.
  /// Die einzelnen Schritte werden ebenfalls gespeichert, so dass diese später wieder abgerufen werden können.
  /// Ebenso wird die gesamte Reisedauer und Reisestrecke gespeichert.
  ///
  /// Diese Daten werden später in der RoutingDetail Klasse wiedergegeben.
  Future<void> startRouting(
      VendingMachine machine, poly.TravelMode travelMode) async {
    if (positionStream != null) {
      positionStream?.cancel();
    }
    polylines = {};
    routingStarted = true;
    trackLocation();

    // Der Notifier wird verwendet, um bei der Routenführung die korrekten Knöpfe anzeigen zu können.
    // Dies wird mit dem ApplicationState Provider durchgeführt. Der Provider bietet eine einfache Möglichkeit kleine änderungen im AppState durchzuführen, ohne diese als Properties an das Widget weiter geben zu müssen
    final myNotifier = Provider.of<ApplicationState>(context, listen: false);
    myNotifier.routingStarted = true;

    // Da das PolyLine-Paket und das google_maps_webservice paket verschiedene TravelMode Objekte verwenden, müssen diese erst umgewandelt werden
    TravelMode dirAPITravelMode = TravelMode.values
        .firstWhere((element) => element.name == travelMode.name);

    currlocAsAddress = await getCurrentAddress();

    d.DirectionsResponse response = await directionsAPI.directionsWithAddress(
        currlocAsAddress ?? "", 
        machine.address,
        travelMode: dirAPITravelMode);

    // Geht durch die Route und holt sich die Start- und End-Adresse sowie Reisezeit und -distanz
    for (d.Route step in response.routes) {
      for (d.Leg leg in step.legs) {
        startingAddress = leg.startAddress;
        destinationAddress = leg.endAddress;
        travelTime = leg.duration.text;
        travelDistance = leg.distance.text;
        for (d.Step stepinleg in leg.steps) {
          print(stepinleg.maneuver);
        }
      }
    }

    poly.PolylineResult startToDestination =
        await calculateRoute(machine, travelMode);

    calculatePolyline(startToDestination);

    // wird jedes mal bei änderung des Standortes aufgerufen
    positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position position) async {
      // Wenn der Standort zu weit vom Weg weg ist, wird die Strecke neu berechnet
      if (!checkDistanceToRoute(startToDestination.points)) {
        startToDestination = await calculateRoute(machine, travelMode);
      }
      calculatePolyline(startToDestination);

      // Hier werden die Koordinaten des momentanen Standortes und der Machine gerundet und verglichen.
      // Falls diese gleich sind, wid die Routenführung abgebrochen, da das Ziel erreicht wurde
      String? currLocLat = currloc?.latitude.toStringAsFixed(3);
      String? currLocLon = currloc?.longitude.toStringAsFixed(3);
      String machineLocLat = machine.geodata.latitude.toStringAsFixed(3);
      String machineLocLon = machine.geodata.longitude.toStringAsFixed(3);

      if (currLocLon == machineLocLon && currLocLat == machineLocLat) {
        cancelRouting();
      }
    });

    setState(() {});
  }

  /// Bricht die Routenführung ab und setzt alle verwendeten Variablen wieder auf ihren Anfangspunkt zurück, um für die nächste Routenführung bereit zu sein
  void cancelRouting() {
    // Positions-Subsciption wird getrennt
    if (positionStream != null) {
      positionStream?.cancel();
    }
    // Die Polylinie wird gelöscht
    polylines = {};
    routingStarted = false;
    final myNotifier = Provider.of<ApplicationState>(context, listen: false);
    myNotifier.routingStarted = false;
    Set<Marker> tmpmarkers = Set<Marker>.from(markers);
    //Iterable<Marker> userMarker = markers.where((element) => element.markerId.value == "User");
    for (Marker test in tmpmarkers) {
      if (test.markerId.value == "User") {
        markers.remove(test);
      }
    }
    //tmpmarkers.removeAll(userMarker);
    //markers = tmpmarkers;
    setState(() {});
  }

  void trackLocation() {
    locationTracking = true;
  }

  void stopTrackLocation() {
    locationTracking = false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: makePromise(),
      builder: (BuildContext context, AsyncSnapshot<Set<Marker>> snapshot) {
        if (snapshot.connectionState == ConnectionState.done || loaded) {
          return SizedBox.fromSize(
            child: Stack(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height,
                  child: GestureDetector(
                    onPanDown: (details) => {
                      if (routingStarted)
                        {
                          setState(() {
                            stopTrackLocation();
                          })
                        }
                    },
                    child: GoogleMap(
                      onMapCreated: (controller) {
                        setState(() {
                          mapController = controller;
                        });
                      },
                      zoomGesturesEnabled: true,
                      initialCameraPosition: CameraPosition(
                        target: showLocation,
                        zoom: 15.0,
                      ),
                      gestureRecognizers: <
                          Factory<OneSequenceGestureRecognizer>>{
                        Factory<OneSequenceGestureRecognizer>(
                            () => EagerGestureRecognizer())
                      },
                      mapType: MapType.normal,
                      myLocationEnabled: routingStarted ? false : true,
                      mapToolbarEnabled: false,
                      markers: markers,
                      zoomControlsEnabled: false,
                      myLocationButtonEnabled: false,
                      // Da polylines nicht mit null deklariert werden darf, muss, falls keine Route vorhanden ist, ein leeres Polyline Set eingefügt werden
                      polylines: routingStarted
                          ? Set<Polyline>.of(polylines.values)
                          : directionlinesnull,
                    ),
                  ),
                ),
                if (routingStarted)
                  Positioned(
                    top: 20,
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      child: RoutingDetail(
                        startingAddress: startingAddress,
                        destinationAddress: destinationAddress,
                        travelTime: travelTime,
                        travelDistance: travelDistance,
                      ),
                    ),
                  ),
                if (routingStarted)
                  Positioned(
                      bottom: 30,
                      left: 20,
                      child: Container(
                          margin: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.3),
                                  spreadRadius: 0.2,
                                  blurRadius: 3,
                                  offset: const Offset(
                                      2, 2), // changes position of shadow
                                ),
                              ],
                              color: const Color.fromARGB(255, 255, 255, 255),
                              border: Border.all(
                                  color:
                                      const Color.fromARGB(74, 134, 133, 133)),
                              borderRadius: BorderRadius.circular(50)),
                          child: IconButton(
                              onPressed: () {
                                cancelRouting();
                              },
                              icon: const Icon(Icons.cancel_outlined)))),
                if (routingStarted)
                  Positioned(
                      bottom: 30,
                      right: 20,
                      child: Container(
                          margin: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.3),
                                  spreadRadius: 0.2,
                                  blurRadius: 3,
                                  offset: const Offset(
                                      2, 2), // changes position of shadow
                                ),
                              ],
                              color: const Color.fromARGB(255, 255, 255, 255),
                              border: Border.all(
                                  color:
                                      const Color.fromARGB(74, 134, 133, 133)),
                              borderRadius: BorderRadius.circular(50)),
                          child: IconButton(
                              onPressed: () {
                                trackLocation();
                              },
                              icon: const Icon(Icons.my_location)))),
                if (!routingStarted)
                  Positioned(
                      top: 30,
                      right: 20,
                      child: Container(
                          margin: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.3),
                                  spreadRadius: 0.2,
                                  blurRadius: 3,
                                  offset: const Offset(
                                      2, 2), // changes position of shadow
                                ),
                              ],
                              color: const Color.fromARGB(255, 255, 255, 255),
                              border: Border.all(
                                  color:
                                      const Color.fromARGB(74, 134, 133, 133)),
                              borderRadius: BorderRadius.circular(50)),
                          child: IconButton(
                              onPressed: () {
                                mapController.animateCamera(
                                    CameraUpdate.newCameraPosition(
                                        CameraPosition(
                                            target: LatLng(
                                                currloc?.latitude ?? 0,
                                                currloc?.longitude ?? 0),
                                            zoom: 15)));
                              },
                              icon: const Icon(Icons.my_location)))),
              ],
            ),
          );
        } else {
          return SizedBox(
              height: MediaQuery.of(context).size.height,
              child: const Center(child: CircularProgressIndicator()));
        }
      },
    );
  }
}
