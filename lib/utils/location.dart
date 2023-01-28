import 'package:geolocator/geolocator.dart' as geo;
import 'package:flutter/material.dart';
import 'package:loc/utils/states.dart';
import 'package:provider/provider.dart';

Future<geo.Position> getCurrentLocation() async {
  bool isServiceEnabled = await geo.Geolocator.isLocationServiceEnabled();
  if (isServiceEnabled == false) {
    return Future.error('Location services are disabled.');
  }

  geo.LocationPermission permission = await geo.Geolocator.checkPermission();
  if (permission == geo.LocationPermission.denied) {
    permission = await geo.Geolocator.requestPermission();
  }

  if (permission == geo.LocationPermission.denied) {
    return Future.error('Location permission is denied');
  }

  if (permission == geo.LocationPermission.deniedForever) {
    return Future.error('Location permission is permanently denied');
  }

  return await geo.Geolocator.getCurrentPosition();
}

void listenToLocationUpdate(BuildContext context) {
  final provider = Provider.of<AppStates>(context, listen: false);

  geo.LocationSettings settings = geo.LocationSettings(
    accuracy: geo.LocationAccuracy.high,
    distanceFilter: double.parse(provider.radiusText.text).toInt(),
  );

  final subscription =
      geo.Geolocator.getPositionStream(locationSettings: settings)
          .listen((position) {
    provider.setCurrLatitude(position.latitude);
    provider.setCurrLongitude(position.longitude);
  });
  provider.setPositionStream(subscription);
  provider.setListening(true);
}

void cancelLocationUpdate(BuildContext context) {
  final provider = Provider.of<AppStates>(context, listen: false);
  provider.positionStream.cancel();
  provider.setListening(false);
  provider.setCurrLatitude(null);
  provider.setCurrLongitude(null);
}

double calcDistance(BuildContext context) {
  final provider = Provider.of<AppStates>(context, listen: false);
  if (provider.isLocValid() == false) return 0.0;

  final currentLatitude = provider.currLatitude!;
  final currentLongitude = provider.currLongitude!;
  final destLatitude = double.parse(provider.destLatitudeText.text);
  final destLongitude = double.parse(provider.destLongitudeText.text);

  final inMeters = geo.Geolocator.distanceBetween(
      destLatitude, destLongitude, currentLatitude, currentLongitude);

  return toKiloMeter(inMeters);
}

double toKiloMeter(double distanceInMeters) {
  distanceInMeters /= 1000;
  return double.parse(distanceInMeters.toStringAsFixed(2));
}