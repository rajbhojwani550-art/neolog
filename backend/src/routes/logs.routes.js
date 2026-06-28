const express = require('express');
const prisma = require('../config/database');
const { authenticate } = require('../middleware/auth');

const router = express.Router();
router.use(authenticate);

router.get('/:id/logs', async (req, res, next) => {
  try {
    const logs = await prisma.dailyLog.findMany({
      where: { babyId: req.params.id },
      orderBy: { logDate: 'desc' },
    });
    res.json(logs);
  } catch (err) {
    next(err);
  }
});

router.post('/:id/logs', async (req, res, next) => {
  try {
    const log = await prisma.dailyLog.create({
      data: {
        ...req.body,
        babyId: req.params.id,
        logDate: new Date(req.body.logDate),
      },
    });
    res.status(201).json(log);
  } catch (err) {
    next(err);
  }
});

router.get('/:id/logs/:logId', async (req, res, next) => {
  try {
    const log = await prisma.dailyLog.findUnique({
      where: { id: req.params.logId },
    });
    if (!log || log.babyId !== req.params.id) {
      return res.status(404).json({ error: 'Log not found' });
    }
    res.json(log);
  } catch (err) {
    next(err);
  }
});

router.put('/:id/logs/:logId', async (req, res, next) => {
  try {
    const data = { ...req.body };
    if (data.logDate) data.logDate = new Date(data.logDate);

    const log = await prisma.dailyLog.update({
      where: { id: req.params.logId },
      data,
    });
    res.json(log);
  } catch (err) {
    next(err);
  }
});

// Medications
router.get('/:id/medications', async (req, res, next) => {
  try {
    const meds = await prisma.medication.findMany({
      where: { babyId: req.params.id },
      orderBy: { startDate: 'desc' },
    });
    res.json(meds);
  } catch (err) {
    next(err);
  }
});

router.post('/:id/medications', async (req, res, next) => {
  try {
    const med = await prisma.medication.create({
      data: {
        ...req.body,
        babyId: req.params.id,
        startDate: new Date(req.body.startDate),
        stopDate: req.body.stopDate ? new Date(req.body.stopDate) : null,
      },
    });
    res.status(201).json(med);
  } catch (err) {
    next(err);
  }
});

router.put('/:id/medications/:medId', async (req, res, next) => {
  try {
    const data = { ...req.body };
    if (data.startDate) data.startDate = new Date(data.startDate);
    if (data.stopDate) data.stopDate = new Date(data.stopDate);

    const med = await prisma.medication.update({
      where: { id: req.params.medId },
      data,
    });
    res.json(med);
  } catch (err) {
    next(err);
  }
});

router.delete('/:id/medications/:medId', async (req, res, next) => {
  try {
    await prisma.medication.delete({ where: { id: req.params.medId } });
    res.json({ message: 'Medication deleted' });
  } catch (err) {
    next(err);
  }
});

// Events
router.get('/:id/events', async (req, res, next) => {
  try {
    const events = await prisma.clinicalEvent.findMany({
      where: { babyId: req.params.id },
      orderBy: { eventDate: 'desc' },
    });
    res.json(events);
  } catch (err) {
    next(err);
  }
});

router.post('/:id/events', async (req, res, next) => {
  try {
    const event = await prisma.clinicalEvent.create({
      data: {
        ...req.body,
        babyId: req.params.id,
        eventDate: new Date(req.body.eventDate),
      },
    });
    res.status(201).json(event);
  } catch (err) {
    next(err);
  }
});

router.put('/:id/events/:eventId', async (req, res, next) => {
  try {
    const data = { ...req.body };
    if (data.eventDate) data.eventDate = new Date(data.eventDate);

    const event = await prisma.clinicalEvent.update({
      where: { id: req.params.eventId },
      data,
    });
    res.json(event);
  } catch (err) {
    next(err);
  }
});

// Investigations
router.get('/:id/investigations', async (req, res, next) => {
  try {
    const investigations = await prisma.investigation.findMany({
      where: { babyId: req.params.id },
      orderBy: { collectedDate: 'desc' },
    });
    res.json(investigations);
  } catch (err) {
    next(err);
  }
});

router.post('/:id/investigations', async (req, res, next) => {
  try {
    const inv = await prisma.investigation.create({
      data: {
        ...req.body,
        babyId: req.params.id,
        collectedDate: new Date(req.body.collectedDate),
        reportDate: req.body.reportDate ? new Date(req.body.reportDate) : null,
      },
    });
    res.status(201).json(inv);
  } catch (err) {
    next(err);
  }
});

module.exports = router;
