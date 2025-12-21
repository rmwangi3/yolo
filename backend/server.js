const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const multer = require('multer');
const upload = multer();
require('dotenv').config();
const path = require('path');

const productRoute = require('./routes/api/productRoute');

// Connecting to the Database
const DEFAULT_LOCAL_MONGO = 'mongodb://localhost:27017/yolomy'

const MONGODB_URI = process.env.MONGODB_URI || DEFAULT_LOCAL_MONGO

mongoose.connect(MONGODB_URI)
    .then(() => console.log('Database connected successfully'))
    .catch((error) => {
        console.error('Database connection error:', error)
        process.exit(1)
    })

// Initializing express
const app = express()

// Body parser middleware
app.use(express.json())

// 
app.use(upload.array()); 

// Cors 
app.use(cors());

// Serve uploaded images statically from /images
app.use('/images', express.static(path.join(__dirname, 'public', 'images')));

// Use Route
app.use('/api/products', productRoute)

// Define the PORT
const PORT = process.env.PORT || 5000

app.listen(PORT, ()=>{
    console.log(`Server listening on port ${PORT}`)
})
