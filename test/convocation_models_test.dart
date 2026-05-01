import 'package:chatbot/models/convocation_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Convocation status flow', () {
    test('marks only yudisium as current when student is not yet yudisium', () {
      const data = ConvocationData(
        infoWisudaText: '',
        infoWisuda: null,
        yudisiumStatus: 'Belum Yudisium',
        yudisiumDate: '',
        yudisiumPredicate: '',
        yudisiumIpk: '',
        applicationSnapshot: null,
        aplikasi: '',
        tagihan: '',
        unggahPendamping: '',
        buatUndangan: '',
      );

      final steps = data.buildSteps();

      expect(steps.map((item) => item.state).toList(), [
        ConvocationStepState.current,
        ConvocationStepState.locked,
        ConvocationStepState.locked,
        ConvocationStepState.locked,
        ConvocationStepState.locked,
      ]);
    });

    test('unlocks next step as each requirement becomes available', () {
      const data = ConvocationData(
        infoWisudaText: 'Info periode wisuda tersedia',
        infoWisuda: null,
        yudisiumStatus: 'Sudah Yudisium',
        yudisiumDate: '',
        yudisiumPredicate: '',
        yudisiumIpk: '',
        applicationSnapshot: null,
        aplikasi: 'Sudah isi pendaftaran',
        tagihan: '',
        unggahPendamping: '',
        buatUndangan: '',
      );

      final steps = data.buildSteps();

      expect(steps[0].state, ConvocationStepState.done);
      expect(steps[1].state, ConvocationStepState.done);
      expect(steps[2].state, ConvocationStepState.current);
      expect(steps[3].state, ConvocationStepState.locked);
      expect(steps[4].state, ConvocationStepState.locked);
    });

    test(
      'marks application as ready when yudisium is done and app is empty',
      () {
        const data = ConvocationData(
          infoWisudaText: '',
          infoWisuda: null,
          yudisiumStatus: 'Sudah Yudisium',
          yudisiumDate: '',
          yudisiumPredicate: '',
          yudisiumIpk: '',
          applicationSnapshot: null,
          aplikasi: '',
          tagihan: '',
          unggahPendamping: '',
          buatUndangan: '',
        );

        expect(data.canApply, isTrue);
        expect(data.hasApplication, isFalse);
        expect(data.buildSteps()[1].state, ConvocationStepState.current);
      },
    );
  });

  group('Convocation photo option payload', () {
    test('serializes selected package and additions for API request', () {
      const request = ConvocationApplicationOptionRequest(
        photoPackage: 'A',
        additions: ['53', '56'],
        paymentDeadline: '25-04-2026',
      );

      expect(request.toJson(), {
        'option': {
          'paketphoto': 'A',
          'addition': ['53', '56'],
        },
        'batas_pembayaran': '25-04-2026',
      });
    });
  });

  group('Convocation yudisium parsing', () {
    test('parses richer payload and unlocks application step', () {
      final response = ConvocationResponse.fromJson({
        'status': 200,
        'body': {
          'data': {
            'Yudisium': {
              'tanggal': '2025-08-05',
              'predikat': 'Sangat Memuaskan',
              'ipk': '3.38',
            },
            'InfoWisuda': {
              'thn_akademik': '2024/2025',
              'semester': 'GENAP',
              'biaya': '2400000.00',
              'batas_pembayaran': '18-10-2025',
              'mulai_pendaftaran': '16-10-2025',
              'batas_pendaftaran': '17-10-2025',
              'ukuran_toga': {'S': 'Small Size', 'M': 'Medium Size'},
              'paket_foto': [
                {
                  'id_additional_detail': '1',
                  'member': [
                    {
                      'member_name': 'PAKET B',
                      'code': 'B',
                      'price': '1500000.00',
                      'items': [
                        {'items_name': 'PROPERTY'},
                      ],
                    },
                  ],
                },
                {
                  'id_additional_detail': '4',
                  'detail_name': 'KANVAS',
                  'price': '195000.00',
                  'code': '53',
                },
              ],
            },
            'Aplikasi': {
              'ukuran_toga': 'M',
              'paket_tambahan': ['53'],
              'kontak': {
                'penerima': 'Aisyah',
                'alamat': 'Jalan Raya Bogor',
                'kota': 'Jakarta Timur',
                'propinsi': 'DKI Jakarta',
                'kode_pos': '13540',
                'telpon': '08123',
              },
              'biaya_wisuda': '2400000.00',
            },
            'Tagihan': [],
            'BuatUndangan': '',
            'UnggahPendamping': '',
            'CetakUndangan': '',
          },
        },
      });

      final data = response.data;
      final steps = data.buildSteps();

      expect(data.isYudisiumDone, isTrue);
      expect(data.yudisiumStatus, 'Sudah Yudisium');
      expect(steps[0].state, ConvocationStepState.done);
      expect(steps[1].state, ConvocationStepState.done);
      expect(data.hasInvoice, isFalse);
      expect(data.infoWisuda?.paymentDeadline, '18-10-2025');
      expect(
        data.infoWisuda?.photoPackages.any((item) => item.code == 'B'),
        isTrue,
      );
      expect(
        data.infoWisuda?.photoAdditions.any((item) => item.id == '53'),
        isTrue,
      );
      expect(data.applicationSnapshot?.togaSize, 'M');
      expect(data.applicationSnapshot?.photoAdditions, ['53']);
    });
  });
}
