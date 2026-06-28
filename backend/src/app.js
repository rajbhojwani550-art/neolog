const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const { errorHandler } = require('./middleware/errorHandler');

const authRoutes = require('./routes/auth.routes');
const babiesRoutes = require('./routes/babies.routes');
const logsRoutes = require('./routes/logs.routes');
const growthRoutes = require('./routes/growth.routes');
const screeningsRoutes = require('./routes/screenings.routes');
const dischargeRoutes = require('./routes/discharge.routes');

const app = express();

app.use(helmet());
app.use(cors());
app.use(morgan('dev'));
app.use(express.json());

app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', service: 'neolog-api', timestamp: new Date().toISOString() });
});

app.use('/api/auth', authRoutes);
app.use('/api/babies', babiesRoutes);
app.use('/api/babies', logsRoutes);
app.use('/api/babies', growthRoutes);
app.use('/api/babies', screeningsRoutes);
app.use('/api/babies', dischargeRoutes);

app.use(errorHandler);

module.exports = app;
