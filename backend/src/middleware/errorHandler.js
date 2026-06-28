const errorHandler = (err, req, res, next) => {
  console.error('Error:', err.message);
  console.error(err.stack);

  if (err.code === 'P2002') {
    return res.status(409).json({
      error: 'A record with this unique field already exists',
      field: err.meta?.target,
    });
  }

  if (err.code === 'P2025') {
    return res.status(404).json({ error: 'Record not found' });
  }

  res.status(err.statusCode || 500).json({
    error: err.message || 'Internal server error',
  });
};

module.exports = { errorHandler };
