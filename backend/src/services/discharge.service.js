const prisma = require('../config/database');

async function generateDischargeSummary(babyId) {
  const baby = await prisma.baby.findUnique({ where: { id: babyId } });
  if (!baby) throw Object.assign(new Error('Baby not found'), { statusCode: 404 });

  const [logs, events, medications, growth, rop, ivh, echo, hearing, nbs] = await Promise.all([
    prisma.dailyLog.findMany({ where: { babyId }, orderBy: { logDate: 'desc' } }),
    prisma.clinicalEvent.findMany({ where: { babyId }, orderBy: { eventDate: 'asc' } }),
    prisma.medication.findMany({ where: { babyId }, orderBy: { startDate: 'desc' } }),
    prisma.growthMeasurement.findMany({ where: { babyId }, orderBy: { measurementDate: 'asc' } }),
    prisma.rOPScreening.findMany({ where: { babyId }, orderBy: { screeningDate: 'desc' } }),
    prisma.iVHScreening.findMany({ where: { babyId }, orderBy: { screeningDate: 'desc' } }),
    prisma.echoReport.findMany({ where: { babyId }, orderBy: { reportDate: 'desc' } }),
    prisma.hearingScreen.findMany({ where: { babyId }, orderBy: { screenDate: 'desc' } }),
    prisma.newbornBloodSpot.findMany({ where: { babyId }, orderBy: { collectionDate: 'desc' } }),
  ]);

  const dischargeDate = baby.dischargeDate || new Date();
  const stayDays = Math.ceil((dischargeDate - baby.admissionDate) / (1000 * 60 * 60 * 24));

  // Diagnoses from events
  const diagnoses = events
    .filter(e => e.category === 'diagnosis')
    .map(e => e.title);

  // Active problems from latest log
  if (logs.length > 0 && logs[0].activeProblemsList) {
    const problems = Array.isArray(logs[0].activeProblemsList) ? logs[0].activeProblemsList : [];
    for (const p of problems) {
      if (!diagnoses.includes(p)) diagnoses.push(p);
    }
  }

  // Clinical course by week
  const courseSummary = events.map(e => {
    return `DOL ${e.dayOfLife || '?'}: ${e.title}${e.description ? ` - ${e.description}` : ''}`;
  }).join('\n');

  // Growth velocity
  let growthVelocity = null;
  if (growth.length >= 2) {
    const first = growth[0];
    const last = growth[growth.length - 1];
    if (first.weight && last.weight) {
      const days = Math.ceil((last.measurementDate - first.measurementDate) / (1000 * 60 * 60 * 24));
      if (days > 0) {
        growthVelocity = ((last.weight - first.weight) / days).toFixed(1);
      }
    }
  }

  // Latest measurements
  const latestGrowth = growth.length > 0 ? growth[growth.length - 1] : null;

  // Medications at discharge (not stopped)
  const activeMeds = medications.filter(m => !m.stopDate);
  const allMedsWithDuration = medications.map(m => ({
    drugName: m.drugName,
    dose: m.dose,
    unit: m.unit,
    frequency: m.frequency,
    route: m.route,
    startDate: m.startDate,
    stopDate: m.stopDate,
  }));

  return {
    baby: {
      id: baby.id,
      mrn: baby.mrn,
      name: `${baby.firstName} ${baby.lastName}`,
      dateOfBirth: baby.dateOfBirth,
      sex: baby.sex,
      gaAtBirth: `${baby.gaWeeks}+${baby.gaDays}`,
      birthWeight: baby.birthWeightGrams,
      modeOfDelivery: baby.modeOfDelivery,
      apgar: baby.apgarScore1min ? `${baby.apgarScore1min}/${baby.apgarScore5min}` : null,
      motherName: baby.motherName,
      fatherName: baby.fatherName,
      admissionDate: baby.admissionDate,
      admissionReason: baby.admissionReason,
      antenatalSteroids: baby.antenatalSteroids,
      antenatalHistory: baby.antenatalHistory,
    },
    stay: {
      totalDays: stayDays,
      dischargeDate,
    },
    diagnoses,
    clinicalCourse: courseSummary || 'Uneventful NICU course.',
    medications: {
      atDischarge: activeMeds,
      all: allMedsWithDuration,
    },
    growth: {
      birthWeight: baby.birthWeightGrams,
      dischargeWeight: latestGrowth?.weight || null,
      dischargeHC: latestGrowth?.headCircumference || null,
      dischargeLength: latestGrowth?.length || null,
      velocity: growthVelocity ? `${growthVelocity} g/day` : null,
    },
    screenings: {
      rop: rop.length > 0 ? {
        lastExam: rop[0].screeningDate,
        rightEye: `Zone ${rop[0].rightEyeZone} Stage ${rop[0].rightEyeStage}`,
        leftEye: `Zone ${rop[0].leftEyeZone} Stage ${rop[0].leftEyeStage}`,
        plusDisease: rop[0].plusDisease,
        treatment: rop[0].treatment,
        nextExam: rop[0].nextExamDate,
      } : null,
      ivh: ivh.length > 0 ? {
        lastScan: ivh[0].screeningDate,
        right: ivh[0].rightSideGrade,
        left: ivh[0].leftSideGrade,
        pvl: ivh[0].periventricularLeukomalacia,
      } : null,
      echo: echo.length > 0 ? {
        lastReport: echo[0].reportDate,
        pda: echo[0].pda,
        pht: echo[0].pulmonaryHypertension,
        lvef: echo[0].lvef,
      } : null,
      hearing: hearing.length > 0 ? {
        method: hearing[0].method,
        rightEar: hearing[0].rightEar,
        leftEar: hearing[0].leftEar,
      } : null,
      nbs: nbs.length > 0 ? {
        status: nbs[0].status,
        results: nbs[0].results,
      } : null,
    },
    followUp: [
      'Pediatrician follow-up in 1 week',
      rop.length > 0 && rop[0].nextExamDate
        ? `ROP follow-up: ${rop[0].nextExamDate.toISOString().split('T')[0]}`
        : null,
      echo.length > 0 ? 'Echo follow-up as advised' : null,
      'Neurodevelopmental follow-up at 3, 6, 12 months corrected age',
      'Immunizations as per schedule',
    ].filter(Boolean),
  };
}

module.exports = { generateDischargeSummary };
