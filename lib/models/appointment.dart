import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class Appointment {
  const Appointment({
    required this.eventId,
    required this.serviceName,
    required this.start,
    required this.end,
    required this.customerName,
    required this.customerEmail,
    this.serviceId = '',
    this.reservationCode = '',
    this.eventUrl,
  });

  final String eventId;
  final String serviceId;
  final String reservationCode;
  final String? eventUrl;
  final String serviceName;
  final DateTime start;
  final DateTime end;
  final String customerName;
  final String customerEmail;

  Map<String, Object?> toJson() => {
    'eventId': eventId,
    'serviceId': serviceId,
    'reservationCode': reservationCode,
    'eventUrl': eventUrl,
    'serviceName': serviceName,
    'start': start.toUtc().toIso8601String(),
    'end': end.toUtc().toIso8601String(),
    'customerName': customerName,
    'customerEmail': customerEmail,
  };

  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
    eventId: json['eventId'] as String,
    serviceId: json['serviceId'] as String? ?? '',
    reservationCode: json['reservationCode'] as String? ?? '',
    eventUrl: json['eventUrl'] as String?,
    serviceName: json['serviceName'] as String,
    start: DateTime.parse(json['start'] as String).toLocal(),
    end: DateTime.parse(json['end'] as String).toLocal(),
    customerName: json['customerName'] as String,
    customerEmail: json['customerEmail'] as String,
  );
}

class AppointmentStore {
  AppointmentStore._();

  static final AppointmentStore instance = AppointmentStore._();
  final http.Client _client = http.Client();

  Uri get _appointmentsUri => Uri.parse(
    '${AppConfig.apiBaseUrl.replaceFirst(RegExp(r'/$'), '')}/appointments',
  );

  Future<List<Appointment>> load({required String customerEmail}) async {
    if (customerEmail.trim().isEmpty) {
      throw const AppointmentStoreException(
        'Inicia sesión para consultar tus citas.',
      );
    }
    try {
      final response = await _client
          .get(
            _appointmentsUri.replace(
              queryParameters: {'email': customerEmail.trim()},
            ),
          )
          .timeout(const Duration(seconds: 10));
      _checkResponse(response);
      final values = jsonDecode(response.body) as List<dynamic>;
      return values
          .map((value) => Appointment.fromJson(value as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.start.compareTo(b.start));
    } on http.ClientException {
      throw const AppointmentStoreException(
        'No pudimos conectar con el servidor de citas.',
      );
    } on TimeoutException {
      throw const AppointmentStoreException(
        'El servidor de citas tardó demasiado en responder.',
      );
    } on FormatException {
      throw const AppointmentStoreException(
        'El servidor devolvió una respuesta inválida.',
      );
    }
  }

  void _checkResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    var message = 'El servidor rechazó la operación (${response.statusCode}).';
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['error'] case final String error when error.isNotEmpty) {
        message = error;
      }
    } on FormatException {
      // Si el servidor no envía JSON, se conserva el mensaje por código HTTP.
    } on TypeError {
      // Si el formato JSON no es un mapa, se conserva el mensaje por código HTTP.
    }
    throw AppointmentStoreException(message);
  }
}

class AppointmentStoreException implements Exception {
  const AppointmentStoreException(this.message);

  final String message;

  @override
  String toString() => message;
}
