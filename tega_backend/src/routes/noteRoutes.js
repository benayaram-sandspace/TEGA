// src/routes/noteRoutes.js
const express = require("express");
const router = express.Router();
const { getNotes, createNote } = require("../controllers/noteController.js");

// Route for getting all notes and creating a new note
router.route("/").get(getNotes).post(createNote);

module.exports = router;
