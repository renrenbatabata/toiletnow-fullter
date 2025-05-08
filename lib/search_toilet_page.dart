import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_place/google_place.dart';
import 'package:helloword/const.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:helloword/toilet.dart';

class SearchToiletPage extends StatefulWidget {
  const SearchToiletPage({super.key});

  @override
  State<SearchToiletPage> createState() => SearchToiletPageState();
}

class SearchToiletPageState extends State<SearchToiletPage> {
  final apiKey = Const.apiKey;

  Toilet? toilet;
  Uri? mapURL;

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    final currentPosition = await _determinePosition();
    final currentLatitude = currentPosition.latitude;
    final currentLongitude = currentPosition.longitude;

    final googlePlace = GooglePlace(apiKey);

    final response = await googlePlace.search.getNearBySearch(
      Location(lat: currentLatitude, lng: currentLongitude),
      1000,
      language: "ja",
      keyword: "お手洗い",
      rankby: RankBy.Distance,
    );

    final results = response?.results;
    final firstResult = results?.first;
    final toiletLocation = firstResult?.geometry?.location;
    final toiletLatitude = toiletLocation?.lat;
    final toiletLongitude = toiletLocation?.lng;

    String urlString = "";
    if (Platform.isAndroid) {
      urlString =
          'https://www.google.com/maps/dir/$currentLatitude,$currentLongitude/$toiletLatitude,$toiletLongitude';
    } else if (Platform.isIOS) {
      urlString =
          'http://maps.apple.com/?saddr=$currentLatitude,$currentLongitude&daddr=$toiletLatitude,$toiletLongitude';
    }
    mapURL = Uri.parse(urlString);

    if (firstResult != null && mounted) {
      final photoReference = firstResult.photos?.first.photoReference;

      setState(() {
        toilet = Toilet(
          firstResult.name,
          "https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=$photoReference&key=$apiKey",
          toiletLocation,
        );
      });
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('位置情報許可してください');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('位置情報許可してください');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('位置情報許可してください');
    }

    return await Geolocator.getCurrentPosition();
  }

  @override
  Widget build(BuildContext context) {
    if (toilet == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("一番近いトイレは？")),
      body: Column(
        children: [
          if (toilet?.photo != null) Image.network(toilet!.photo!),
          const SizedBox(height: 16),
          Text(
            toilet?.name ?? "トイレの名前が取得できませんでした",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              if (mapURL != null) {
                await launchUrl(mapURL!);
              }
            },
            child: const Text("Google Mapで開く"),
          ),
        ],
      ),
    );
  }
}
