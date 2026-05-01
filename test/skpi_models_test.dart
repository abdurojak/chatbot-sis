import 'package:chatbot/models/skpi_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SkpiResponseData', () {
    test('parses organisasi items from api response', () {
      final response = {
        'status': 200,
        'body': {
          'data': [
            {
              'idOrganisasi': '44652',
              'title_bahasa':
                  'Society of Petroleum Engineers Trisakti University Student Chapter',
              'title':
                  'Society of Petroleum Engineers Trisakti University Student Chapter\r\n\t\t\t',
              'level': 'Jurusan/Program Studi',
              'category': 'Kemahasiswaan',
              'occupacy': 'Wakil Ketua',
              'year_start': '2021',
              'year_stop': '2022',
            },
          ],
        },
      };

      final result = SkpiResponseData<SkpiOrganization>.fromJson(
        response,
        SkpiOrganization.fromJson,
      );

      expect(result.items, hasLength(1));
      expect(
        result.items.first.title,
        'Society of Petroleum Engineers Trisakti University Student Chapter',
      );
      expect(result.items.first.occupation, 'Wakil Ketua');
      expect(result.items.first.periodLabel, '2021 - 2022');
    });

    test('parses language items from api response', () {
      final response = {
        'status': 200,
        'body': {
          'data': [
            {
              'idLanguage': '28877',
              'Language': 'ENGLISH',
              'Bahasa': 'BAHASA INGGRIS',
              'Standart': 'TOEFL',
              'Skore': '463',
              'date_of_taken': '2023-02-09',
            },
          ],
        },
      };

      final result = SkpiResponseData<SkpiLanguage>.fromJson(
        response,
        SkpiLanguage.fromJson,
      );

      expect(result.items, hasLength(1));
      expect(result.items.first.languageName, 'BAHASA INGGRIS');
      expect(result.items.first.standardName, 'TOEFL');
      expect(result.items.first.score, '463');
      expect(result.items.first.takenDateLabel, '2023-02-09');
    });

    test('parses softskill items from api response', () {
      final response = {
        'status': 200,
        'body': {
          'data': [
            {
              'idSoftskill': '213157',
              'title': '12th Indonesia HR Summit in Bali, Indonesia',
              'title_bahasa': '12th Indonesia HR Summit in Bali, Indonesia',
              'given_by': 'Pertamina Hulu Mahakam, SKK Migas',
              'hours': '18.00',
              'datestart': '2022-06-28',
              'datestop': '2022-06-29',
            },
          ],
        },
      };

      final result = SkpiResponseData<SkpiSoftskill>.fromJson(
        response,
        SkpiSoftskill.fromJson,
      );

      expect(result.items, hasLength(1));
      expect(
        result.items.first.title,
        '12th Indonesia HR Summit in Bali, Indonesia',
      );
      expect(result.items.first.givenBy, 'Pertamina Hulu Mahakam, SKK Migas');
      expect(result.items.first.hoursLabel, '18 jam');
      expect(result.items.first.periodLabel, '2022-06-28 - 2022-06-29');
    });

    test('parses honors items from api response', () {
      final response = {
        'status': 200,
        'body': {
          'data': [
            {
              'idHonors': '71708',
              'title':
                  'Elite Eight of PetroBowl World Championship in George R Brown Convention Centre, Houston, Texas, USA',
              'title_bahasa': 'Elite Eight of PetroBowl World Championship',
              'date_of_honor': '2022-10-04',
              'given_by': 'SPE International',
              'field': 'Penelitian',
              'level': 'Internasional',
            },
          ],
        },
      };

      final result = SkpiResponseData<SkpiHonor>.fromJson(
        response,
        SkpiHonor.fromJson,
      );

      expect(result.items, hasLength(1));
      expect(result.items.first.givenBy, 'SPE International');
      expect(result.items.first.field, 'Penelitian');
      expect(result.items.first.level, 'Internasional');
      expect(result.items.first.honorDateLabel, '2022-10-04');
    });

    test('builds evidence file metadata from base64 pdf', () {
      final result = SkpiFetchedEvidence.fromBase64(
        'JVBERi0xLjQK',
        fallbackName: 'Evidence_270928',
      );

      expect(result.isPdf, isTrue);
      expect(result.fileName, 'Evidence_270928.pdf');
      expect(result.bytes, isNotEmpty);
    });

    test('parses honors references for level and field', () {
      final response = {
        'status': 200,
        'body': {
          'data': {
            'level': [
              {
                'key': '803',
                'value': 'Jurusan/Program Studi',
                'idDefType': '117',
              },
            ],
            'field': [
              {'key': '895', 'value': 'Kewirausahaan', 'idDefType': '119'},
            ],
          },
        },
      };

      final result = SkpiHonorReferenceData.fromJson(response);

      expect(result.levels, hasLength(1));
      expect(result.fields, hasLength(1));
      expect(result.levels.first.key, '803');
      expect(result.fields.first.value, 'Kewirausahaan');
    });

    test('parses add honor response message', () {
      final response = {
        'status': 200,
        'body': {
          'data': {'id': '91298', 'pesan': 'data berhasil ditambahkan'},
        },
      };

      final result = SkpiTransactionResult.fromJson(response);

      expect(result.id, '91298');
      expect(result.message, 'data berhasil ditambahkan');
    });
  });
}
