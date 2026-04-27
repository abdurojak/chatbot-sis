import 'package:chatbot/models/convocation_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Convocation status flow', () {
    test('marks only yudisium as current when student is not yet yudisium', () {
      final data = ConvocationData(
        infoWisuda: '',
        yudisiumStatus: 'Belum Yudisium',
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
      final data = ConvocationData(
        infoWisuda: 'Info periode wisuda tersedia',
        yudisiumStatus: 'Sudah Yudisium',
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
  });
}
