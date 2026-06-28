const express = require('express');
const prisma = require('../config/database');
const { authenticate } = require('../middleware/auth');

const router = express.Router();
router.use(authenticate);

router.get('/', async (req, res, next) => {
  try {
    const { status, search, sortBy = 'createdAt', order = 'desc' } = req.query;

    const where = {};
    if (status) where.status = status;
    if (search) {
      where.OR = [
        { firstName: { contains: search, mode: 'insensitive' } },
        { lastName: { contains: search, mode: 'insensitive' } },
        { mrn: { contains: search, mode: 'insensitive' } },
      ];
    }

    const babies = await prisma.baby.findMany({
      where,
      orderBy: { [sortBy]: order },
    });

    res.json(babies);
  } catch (err) {
    next(err);
  }
});

router.post('/', async (req, res, next) => {
  try {
    const baby = await prisma.baby.create({
      data: {
        ...req.body,
        dateOfBirth: new Date(req.body.dateOfBirth),
        admissionDate: new Date(req.body.admissionDate),
        dischargeDate: req.body.dischargeDate ? new Date(req.body.dischargeDate) : null,
        createdBy: req.userId,
      },
    });
    res.status(201).json(baby);
  } catch (err) {
    next(err);
  }
});

router.get('/:id', async (req, res, next) => {
  try {
    const baby = await prisma.baby.findUnique({
      where: { id: req.params.id },
      include: {
        dailyLogs: { orderBy: { logDate: 'desc' }, take: 5 },
        growthMeasurements: { orderBy: { measurementDate: 'desc' }, take: 5 },
        medications: { orderBy: { startDate: 'desc' } },
      },
    });
    if (!baby) return res.status(404).json({ error: 'Baby not found' });
    res.json(baby);
  } catch (err) {
    next(err);
  }
});

router.put('/:id', async (req, res, next) => {
  try {
    const data = { ...req.body };
    if (data.dateOfBirth) data.dateOfBirth = new Date(data.dateOfBirth);
    if (data.admissionDate) data.admissionDate = new Date(data.admissionDate);
    if (data.dischargeDate) data.dischargeDate = new Date(data.dischargeDate);

    const baby = await prisma.baby.update({
      where: { id: req.params.id },
      data,
    });
    res.json(baby);
  } catch (err) {
    next(err);
  }
});

router.delete('/:id', async (req, res, next) => {
  try {
    await prisma.baby.update({
      where: { id: req.params.id },
      data: { status: 'deleted' },
    });
    res.json({ message: 'Baby record soft-deleted' });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
