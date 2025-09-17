// src/controllers/noteController.js

// @desc    Get all notes
// @route   GET /api/notes
const getNotes = (req, res) => {
  res.status(200).json({ message: "Placeholder for getting all notes" });
  // Later, you'll replace this with:
  // const notes = await Note.find();
  // res.status(200).json(notes);
};

// @desc    Create a new note
// @route   POST /api/notes
const createNote = (req, res) => {
  const { title, content } = req.body;
  if (!title || !content) {
    return res.status(400).json({ message: "Title and content are required" });
  }
  res.status(201).json({
    message: "Placeholder for creating a new note",
    data: { title, content },
  });
  // Later, you'll replace this with:
  // const note = await Note.create({ title, content });
  // res.status(201).json(note);
};

module.exports = {
  getNotes,
  createNote,
};
