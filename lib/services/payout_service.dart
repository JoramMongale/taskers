import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/payout_model.dart';

class PayoutService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // Request a payout
  static Future<Map<String, dynamic>> requestPayout({
    required String taskerId,
    required double amount