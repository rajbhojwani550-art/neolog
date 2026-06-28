import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../babies/models/baby_model.dart';
import '../../../core/utils/date_utils.dart';

class DischargePdfService {
  static Future<Uint8List> generatePdf({
    required BabyModel baby,
    required Map<String, dynamic> summaryData,
    required String clinicalCourse,
    required String diagnoses,
    required String followUpPlan,
  }) async {
    final pdf = pw.Document();

    final headerStyle = pw.TextStyle(
      fontSize: 14,
      fontWeight: pw.FontWeight.bold,
      color: PdfColor.fromHex('#1565C0'),
    );

    final subHeaderStyle = pw.TextStyle(
      fontSize: 11,
      fontWeight: pw.FontWeight.bold,
    );

    final bodyStyle = const pw.TextStyle(fontSize: 10);
    final labelStyle = pw.TextStyle(
      fontSize: 10,
      fontWeight: pw.FontWeight.bold,
      color: PdfColor.fromHex('#546E7A'),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(context),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          // Title
          pw.Center(
            child: pw.Text(
              'DISCHARGE SUMMARY',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
          pw.SizedBox(height: 20),

          // Demographics
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('PATIENT INFORMATION', style: headerStyle),
                pw.SizedBox(height: 8),
                _row('Name', baby.fullName, labelStyle, bodyStyle),
                _row('MRN', baby.mrn, labelStyle, bodyStyle),
                _row('Date of Birth', AppDateUtils.formatDate(baby.dateOfBirth), labelStyle, bodyStyle),
                _row('Sex', baby.sex[0].toUpperCase() + baby.sex.substring(1), labelStyle, bodyStyle),
                _row('GA at Birth', '${baby.gaWeeks}+${baby.gaDays} weeks', labelStyle, bodyStyle),
                _row('Birth Weight', '${baby.birthWeightGrams} grams', labelStyle, bodyStyle),
                _row('Mode of Delivery', baby.modeOfDelivery, labelStyle, bodyStyle),
                if (baby.apgarScore1min != null)
                  _row('APGAR (1/5 min)', '${baby.apgarScore1min}/${baby.apgarScore5min ?? "-"}', labelStyle, bodyStyle),
                _row('Mother', baby.motherName, labelStyle, bodyStyle),
                _row('Father', baby.fatherName, labelStyle, bodyStyle),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // Admission
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('ADMISSION DETAILS', style: headerStyle),
                pw.SizedBox(height: 8),
                _row('Admission Date', AppDateUtils.formatDate(baby.admissionDate), labelStyle, bodyStyle),
                _row('Admission Reason', baby.admissionReason, labelStyle, bodyStyle),
                _row('Antenatal Steroids', baby.antenatalSteroids, labelStyle, bodyStyle),
                if (baby.antenatalHistory != null && baby.antenatalHistory!.isNotEmpty)
                  _row('Antenatal History', baby.antenatalHistory!, labelStyle, bodyStyle),
                _row('Total NICU Stay', '${summaryData['stayDays']} days', labelStyle, bodyStyle),
                _row('CGA at Discharge', baby.correctedGA, labelStyle, bodyStyle),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // Diagnoses
          pw.Text('DIAGNOSES', style: headerStyle),
          pw.SizedBox(height: 4),
          ...diagnoses.split('\n').where((d) => d.trim().isNotEmpty).map(
                (d) => pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 8, bottom: 2),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('• ', style: bodyStyle),
                      pw.Expanded(child: pw.Text(d.trim(), style: bodyStyle)),
                    ],
                  ),
                ),
              ),
          pw.SizedBox(height: 16),

          // Clinical Course
          pw.Text('CLINICAL COURSE', style: headerStyle),
          pw.SizedBox(height: 4),
          pw.Text(clinicalCourse, style: bodyStyle),
          pw.SizedBox(height: 16),

          // Growth
          if (summaryData['latestWeight'] != null) ...[
            pw.Text('GROWTH', style: headerStyle),
            pw.SizedBox(height: 4),
            _row('Discharge Weight', '${summaryData['latestWeight']}g (Birth: ${baby.birthWeightGrams}g)', labelStyle, bodyStyle),
            if (summaryData['latestHC'] != null)
              _row('Head Circumference', '${summaryData['latestHC']} cm', labelStyle, bodyStyle),
            if (summaryData['latestLength'] != null)
              _row('Length', '${summaryData['latestLength']} cm', labelStyle, bodyStyle),
            if (summaryData['growthVelocity'] != null)
              _row('Growth Velocity', '${(summaryData['growthVelocity'] as double).toStringAsFixed(1)} g/day', labelStyle, bodyStyle),
            pw.SizedBox(height: 16),
          ],

          // Medications at Discharge
          pw.Text('MEDICATIONS AT DISCHARGE', style: headerStyle),
          pw.SizedBox(height: 4),
          ...(summaryData['medications'] as List)
              .where((m) => m['stopDate'] == null)
              .map((m) => pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 8, bottom: 2),
                    child: pw.Text(
                      '• ${m['drugName']} ${m['dose']} ${m['unit']} ${m['frequency']} ${m['route']}',
                      style: bodyStyle,
                    ),
                  )),
          if ((summaryData['medications'] as List).where((m) => m['stopDate'] == null).isEmpty)
            pw.Text('None', style: bodyStyle),
          pw.SizedBox(height: 16),

          // Screening Results
          pw.Text('SCREENING RESULTS', style: headerStyle),
          pw.SizedBox(height: 4),
          _buildScreeningRow('ROP', summaryData['ropScreenings'] as List, labelStyle, bodyStyle),
          _buildScreeningRow('IVH', summaryData['ivhScreenings'] as List, labelStyle, bodyStyle),
          _buildScreeningRow('Echo', summaryData['echoScreenings'] as List, labelStyle, bodyStyle),
          _buildScreeningRow('Hearing', summaryData['hearingScreenings'] as List, labelStyle, bodyStyle),
          _buildScreeningRow('NBS', summaryData['nbsScreenings'] as List, labelStyle, bodyStyle),
          pw.SizedBox(height: 16),

          // Follow-up Plan
          pw.Text('FOLLOW-UP PLAN', style: headerStyle),
          pw.SizedBox(height: 4),
          pw.Text(followUpPlan, style: bodyStyle),
          pw.SizedBox(height: 32),

          // Signature
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(width: 150, height: 1, color: PdfColors.grey400),
                  pw.SizedBox(height: 4),
                  pw.Text('Attending Neonatologist', style: labelStyle),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(width: 120, height: 1, color: PdfColors.grey400),
                  pw.SizedBox(height: 4),
                  pw.Text('Date', style: labelStyle),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(pw.Context context) {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'NeoLog',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#1565C0'),
              ),
            ),
            pw.Text(
              'NICU Discharge Summary',
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColor.fromHex('#546E7A'),
              ),
            ),
          ],
        ),
        pw.Container(
          margin: const pw.EdgeInsets.only(top: 4, bottom: 12),
          height: 2,
          color: PdfColor.fromHex('#1565C0'),
        ),
      ],
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generated by NeoLog',
            style: pw.TextStyle(
              fontSize: 8,
              color: PdfColor.fromHex('#9E9E9E'),
            ),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: pw.TextStyle(
              fontSize: 8,
              color: PdfColor.fromHex('#9E9E9E'),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _row(
    String label,
    String value,
    pw.TextStyle labelStyle,
    pw.TextStyle bodyStyle,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(width: 130, child: pw.Text(label, style: labelStyle)),
          pw.Expanded(child: pw.Text(value, style: bodyStyle)),
        ],
      ),
    );
  }

  static pw.Widget _buildScreeningRow(
    String type,
    List screenings,
    pw.TextStyle labelStyle,
    pw.TextStyle bodyStyle,
  ) {
    String summary;
    if (screenings.isEmpty) {
      summary = 'Not done';
    } else {
      final latest = screenings.first;
      switch (type) {
        case 'ROP':
          summary = 'RE: Zone ${latest['rightEye_zone']} Stage ${latest['rightEye_stage']}, '
              'LE: Zone ${latest['leftEye_zone']} Stage ${latest['leftEye_stage']}';
          if (latest['plusDisease'] == true) summary += ' (Plus disease)';
          break;
        case 'IVH':
          summary = 'Right: ${latest['rightSide_grade']}, Left: ${latest['leftSide_grade']}';
          if (latest['periventricularLeukomalacia'] == true) summary += ' (PVL+)';
          break;
        case 'Echo':
          summary = 'PDA: ${latest['pda']}';
          if (latest['pulmonaryHypertension'] != null && latest['pulmonaryHypertension'] != 'none') {
            summary += ', PHT: ${latest['pulmonaryHypertension']}';
          }
          break;
        case 'Hearing':
          summary = 'RE: ${latest['rightEar']}, LE: ${latest['leftEar']} (${latest['method']})';
          break;
        case 'NBS':
          summary = 'Status: ${latest['status']}';
          break;
        default:
          summary = '${screenings.length} done';
      }
    }
    return _row(type, summary, labelStyle, bodyStyle);
  }
}
