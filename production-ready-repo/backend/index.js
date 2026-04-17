const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet());
app.use(cors());
app.use(morgan('dev'));
app.use(express.json());

// Routes
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date() });
});

/**
 * Endpoint for receiving encrypted intelligence reports from mobile devices
 */
app.post('/api/reports', (req, res) => {
  const { deviceId, reportType, timestamp, data } = req.body;
  
  console.log(`Received ${reportType} report from device ${deviceId}`);
  
  // In a real implementation, you would store this in a database
  res.status(201).json({
    message: 'Report received successfully',
    id: Math.random().toString(36).substr(2, 9)
  });
});

app.listen(PORT, () => {
  console.log(`DevMonitor Backend listening on port ${PORT}`);
});
