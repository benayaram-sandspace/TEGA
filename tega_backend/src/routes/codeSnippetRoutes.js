import express from 'express';
import { 
  createSnippet,
  getUserSnippets,
  getSnippet,
  updateSnippet,
  deleteSnippet,
  getPublicSnippets,
  toggleFavorite,
  getSnippetStats
} from '../controllers/codeSnippetController.js';
import { studentAuth } from '../middleware/studentAuth.js';

const router = express.Router();

// Public routes (no auth required)
router.get('/public', getPublicSnippets);

// Protected routes (auth required)
router.use(studentAuth);

// Code snippet CRUD operations
router.post('/', createSnippet);
router.get('/', getUserSnippets);
router.get('/stats', getSnippetStats);
router.get('/:id', getSnippet);
router.put('/:id', updateSnippet);
router.delete('/:id', deleteSnippet);
router.patch('/:id/favorite', toggleFavorite);

export default router;
