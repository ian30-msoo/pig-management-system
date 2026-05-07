// lib/utils/constants.dart
class AppConstants {
  static const appName = 'MkulimaPro';

  // ── All 47 official Kenya counties (no duplicates, no towns) ──────────────
  static const List<String> kenyanCounties = [
    'Nairobi',
    'Mombasa',
    'Kwale',
    'Kilifi',
    'Tana River',
    'Lamu',
    'Taita Taveta',
    'Garissa',
    'Wajir',
    'Mandera',
    'Marsabit',
    'Isiolo',
    'Meru',
    'Tharaka-Nithi',
    'Embu',
    'Kitui',
    'Machakos',
    'Makueni',
    'Nyandarua',
    'Nyeri',
    'Kirinyaga',
    "Murang'a",
    'Kiambu',
    'Turkana',
    'West Pokot',
    'Samburu',
    'Trans Nzoia',
    'Uasin Gishu',
    'Elgeyo Marakwet',
    'Nandi',
    'Baringo',
    'Laikipia',
    'Nakuru',
    'Narok',
    'Kajiado',
    'Kericho',
    'Bomet',
    'Kakamega',
    'Vihiga',
    'Bungoma',
    'Busia',
    'Siaya',
    'Kisumu',
    'Homa Bay',
    'Migori',
    'Kisii',
    'Nyamira',
  ];

  static const List<String> pigBreeds = [
    'Large White', 'Duroc', 'Hampshire', 'Landrace',
    'Berkshire', 'Pietrain', 'Spotted', 'Chester White', 'Local Breed',
  ];

  static const List<String> pigStages = [
    'Piglet (0-8 weeks)', 'Weaner (8-16 weeks)',
    'Grower (4-6 months)', 'Finisher (6-8 months)',
    'Gilt (Young Female)', 'Sow (Breeding Female)',
    'Boar (Breeding Male)', 'Mature (8+ months)',
  ];

  static const List<String> healthConditions = [
    'African Swine Fever (ASF)', 'PRRS', 'Swine Flu', 'Foot & Mouth Disease',
    'Porcine Parvovirus', 'Erysipelas', 'Mange', 'Worms/Parasites',
    'Diarrhea', 'Respiratory Infection', 'Leptospirosis', 'Other',
  ];

  static const List<String> vaccineTypes = [
    'ASF Vaccine', 'FMD Vaccine', 'PRRS Vaccine', 'Erysipelas Vaccine',
    'Parvovirus Vaccine', 'Leptospirosis Vaccine', 'Deworming',
    'Vitamin Supplement',
  ];

  static const List<String> feedTypes = [
    'Starter Feed (Piglets)', 'Grower Feed', 'Finisher Feed',
    'Sow & Weaner', 'Boar Feed', 'Custom Mix', 'Kitchen Waste', 'Pasture',
  ];

  static const List<String> userRoles = [
    'Pig Farmer', 'Veterinarian', 'Livestock Officer',
  ];
}