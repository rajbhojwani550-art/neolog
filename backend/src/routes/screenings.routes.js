const express = require('express');
const prisma = require('../config/database');
const { authenticate } = require('../middleware/auth');

const router = express.Router();
router.use(authenticate);

// ROP
router.get('/:id/rop', async (req, res, next) => {
  try {
    const screenings = await prisma.rOPScreening.findMany({
      where: { babyId: req.params.id },
      orderBy: { screeningDate: 'desc' },
    });
    res.json(screenings);
  } catch (err) {
    next(err);
  }
});

router.post('/:id/rop', async (req, res, next) => {
  try {
    const screening = await prisma.rOPScreening.create({
      data: {
        ...req.body,
        babyId: req.params.id,
        screeningDate: new Date(req.body.screeningDate),
        nextExamDate: req.body.nextExamDate ? new Date(req.body.nextExamDate) : null,
      },
    });
    res.status(201).json(screening);
  } catch (err) {
    next(err);
  }
});

// IVH
router.get('/:id/ivh', async (req, res, next) => {
  try {
    const screenings = await prisma.iVHScreening.findMany({
      where: { babyId: req.params.id },
      orderBy: { screeningDate: 'desc' },
    });
    res.json(screenings);
  } catch (err) {
    next(err);
  }
});

router.post('/:id/ivh', async (req, res, next) => {
  try {
    const screening = await prisma.iVHScreening.create({
      data: {
        ...req.body,
        babyId: req.params.id,
        screeningDate: new Date(req.body.screeningDate),
        nextScanDate: req.body.nextScanDate ? new Date(req.body.nextScanDate) : null,
      },
    });
    res.status(201).json(screening);
  } catch (err) {
    next(err);
  }
});

// Echo
router.get('/:id/echo', async (req, res, next) => {
  try {
    const reports = await prisma.echoReport.findMany({
      where: { babyId: req.params.id },
      orderBy: { reportDate: 'desc' },
    });
    res.json(reports);
  } catch (err) {
    next(err);
  }
});

router.post('/:id/echo', async (req, res, next) => {
  try {
    const report = await prisma.echoReport.create({
      data: {
        ...req.body,
        babyId: req.params.id,
        reportDate: new Date(req.body.reportDate),
        nextEchoDate: req.body.nextEchoDate ? new Date(req.body.nextEchoDate) : null,
      },
    });
    res.status(201).json(report);
  } catch (err) {
    next(err);
  }
});

// Hearing
router.get('/:id/hearing', async (req, res, next) => {
  try {
    const screens = await prisma.hearingScreen.findMany({
      where: { babyId: req.params.id },
      orderBy: { screenDate: 'desc' },
    });
    res.json(screens);
  } catch (err) {
    next(err);
  }
});

router.post('/:id/hearing', async (req, res, next) => {
  try {
    const screen = await prisma.hearingScreen.create({
      data: {
        ...req.body,
        babyId: req.params.id,
        screenDate: new Date(req.body.screenDate),
        repeatedOn: req.body.repeatedOn ? new Date(req.body.repeatedOn) : null,
      },
    });
    res.status(201).json(screen);
  } catch (err) {
    next(err);
  }
});

// NBS
router.get('/:id/nbs', async (req, res, next) => {
  try {
    const spots = await prisma.newbornBloodSpot.findMany({
      where: { babyId: req.params.id },
      orderBy: { collectionDate: 'desc' },
    });
    res.json(spots);
  } catch (err) {
    next(err);
  }
});

router.post('/:id/nbs', async (req, res, next) => {
  try {
    const spot = await prisma.newbornBloodSpot.create({
      data: {
        ...req.body,
        babyId: req.params.id,
        collectionDate: new Date(req.body.collectionDate),
      },
    });
    res.status(201).json(spot);
  } catch (err) {
    next(err);
  }
});

module.exports = router;
