const express = require('express');
const dotenv = require('dotenv');
const cors = require('cors');
const connectDB = require('./config/database');
const allRoutes = require('./routes/index');
const { initializeCashfree } = require('./config/cashfree');

dotenv.config();
initializeCashfree();
const app = express();
const PORT = process.env.PORT || 5000;

connectDB();

app.use(cors());

app.use(express.json());

app.get('/', (req, res) => {
    res.send('CarPooling Clone API is running!');
});

app.use('/api', allRoutes);

app.listen(PORT, () => {
});