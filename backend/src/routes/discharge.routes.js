const express = require('express');
const prisma = require('../config/database');
const { authenticate } = require('../middleware/auth');
const { generateDischargeSummary } = require('../services/discharge.service');

const router = express.Router();
router.use(authenticate);

router.get('/:id/discharge-summary', async (req, res, next) => {
  try {
    const summary = await generateDischargeSummary(req.params.id);
    res.json(summary);
  } catch (err) {
    next(err);
  }
});

router.post('/:id/discharge-summary', async (req, res, next) => {
  try {
    const { dischargeDate, finalSummary } = req.body;

    await prisma.baby.update({
      where: { id: req.params.id },
      data: {
        status: 'discharged',
        dischargeDate: new Date(dischargeDate || Date.now()),
      },
    });

    res.json({ message: 'Discharge summary saved', summary: finalSummary });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
