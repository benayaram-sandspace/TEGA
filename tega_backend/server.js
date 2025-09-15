// server.js
const express = require("express");
const dotenv = require("dotenv");
const connectDB = require("./src/config/database");

// Load environment variables
dotenv.config();

// Connect to the database
connectDB();

const app = express();

// Middleware to parse JSON bodies
app.use(express.json());

// A simple root route for testing
app.get("/", (req, res) => {
  res.send("API is running...");
});

// Mount Authentication Routes
app.use("/api/auth", require("./src/routes/authRoutes"));
app.use("/api/users", require("./src/routes/userRoutes"));
app.use("/api/colleges", require("./src/routes/collegeRoutes"));

// (You can keep your note routes if you want)
// app.use('/api/notes', require('./src/routes/noteRoutes'));

const PORT = process.env.PORT || 5000;

app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
});
