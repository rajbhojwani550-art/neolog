const express = require('express');
const prisma = require('../config/database');
const { authenticate } = require('../middleware/auth');

const router = express.Router();
router.use(authenticate);

router.get('/:id/growth', async (req, res, next) => {
  try {
    const measurements = await prisma.growthMeasurement.findMany({
      where: { babyId: req.params.id },
      orderBy: { measurementDate: 'asc' },
    });
    res.json(measurements);
  } catch (err) {
    next(err);
  }
});

router.post('/:id/growth', async (req, res, next) => {
  try {
    const measurement = await prisma.growthMeasurement.create({
      data: {
        ...req.body,
        babyId: req.params.id,
        measurementDate: new Date(req.body.measurementDate),
      },
    });
    res.status(201).json(measurement);
  } catch (err) {
    next(err);
  }
});

module.exports = router;
