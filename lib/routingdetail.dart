import 'package:flutter/material.dart';

class RoutingDetail extends StatefulWidget {
  const RoutingDetail({
    super.key,
    required this.startingAddress,
    required this.destinationAddress,
    required this.travelTime,
    required this.travelDistance,
  });

  final String startingAddress;
  final String destinationAddress;
  final String travelTime;
  final String travelDistance;

  @override
  State<RoutingDetail> createState() => _RoutingDetail();
}

class _RoutingDetail extends State<RoutingDetail> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 0.2,
              blurRadius: 3,
              offset: const Offset(2, 2), // changes position of shadow
            ),
          ],
          color: const Color.fromARGB(255, 255, 255, 255),
          border: Border.all(color: const Color.fromARGB(74, 134, 133, 133)),
          borderRadius: BorderRadius.circular(20)),
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.all(10),
      child: Column(
        children: [
          Row(
            children: [
              const Text("Start: "),
              const Padding(
                padding: EdgeInsets.only(left: 50),
              ),
              Expanded(child: Text(widget.startingAddress)),
            ],
          ),
          const Divider(),
          Row(
            children: [
              const Text("Destination: "),
              const Padding(
                padding: EdgeInsets.only(left: 10),
              ),
              Expanded(child: Text(widget.destinationAddress)),
            ],
          ),
          const Divider(),
          Row(
            children: [
              const Text("Duration: "),
              const Padding(
                padding: EdgeInsets.only(left: 28),
              ),
              Expanded(child: Text(widget.travelTime)),
            ],
          ),
          const Divider(),
          Row(
            children: [
              const Text("Distance: "),
              const Padding(
                padding: EdgeInsets.only(left: 28),
              ),
              Expanded(child: Text(widget.travelDistance)),
            ],
          ),
        ],
      ),
    );
  }
}
