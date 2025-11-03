import mongoose from 'mongoose';
import CodeSnippet from '../models/CodeSnippet.js';
import { cacheHelpers, cacheKeys } from '../config/redis.js';

/**
 * Create a new code snippet
 */
export const createSnippet = async (req, res) => {
  try {
    const { name, language, code, editorMode, description, tags, isPublic } = req.body;
    const userId = req.student?._id || req.studentId || req.user?.id;

    // Validate required fields
    if (!name || !language || !code) {
      return res.status(400).json({
        success: false,
        message: 'Name, language, and code are required'
      });
    }

    // Check if snippet with same name already exists for this user
    const existingSnippet = await CodeSnippet.findOne({
      user: userId,
      name: name.trim()
    });

    if (existingSnippet) {
      return res.status(409).json({
        success: false,
        message: 'A snippet with this name already exists'
      });
    }

    // Create new snippet
    const snippet = new CodeSnippet({
      user: userId,
      name: name.trim(),
      language,
      code,
      editorMode: editorMode || 'single',
      description: description?.trim() || '',
      tags: tags || [],
      isPublic: isPublic || false
    });

    await snippet.save();

    // Clear user's snippet cache
    const cacheKey = cacheKeys.userSession(`user-snippets:${userId}`);
    await cacheHelpers.del(cacheKey);

    res.status(201).json({
      success: true,
      data: snippet,
      message: 'Code snippet created successfully'
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to create code snippet',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
};

/**
 * Get user's code snippets
 */
export const getUserSnippets = async (req, res) => {
  try {
    const userId = req.student?._id || req.studentId || req.user?.id;
    const { page = 1, limit = 20, language, isFavorite, search } = req.query;

    // Check cache first
    const cacheKey = cacheKeys.userSession(`user-snippets:${userId}:${page}:${limit}:${language}:${isFavorite}:${search}`);
    const cachedResult = await cacheHelpers.get(cacheKey);
    
    if (cachedResult) {
      return res.json({
        success: true,
        data: cachedResult
      });
    }

    // Get snippets from database
    const result = await CodeSnippet.getUserSnippets(userId, {
      page: parseInt(page),
      limit: parseInt(limit),
      language,
      isFavorite: isFavorite === 'true' ? true : isFavorite === 'false' ? false : null,
      search
    });

    // Cache for 5 minutes
    await cacheHelpers.set(cacheKey, result, 300);

    res.json({
      success: true,
      data: result
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch code snippets'
    });
  }
};

/**
 * Get a specific code snippet
 */
export const getSnippet = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.student?._id || req.studentId || req.user?.id;

    const snippet = await CodeSnippet.findById(id);

    if (!snippet) {
      return res.status(404).json({
        success: false,
        message: 'Code snippet not found'
      });
    }

    // Check if user has access to this snippet (allow access to own snippets and public snippets)
    if (snippet.user.toString() !== userId && !snippet.isPublic) {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    // Increment usage count only if it's the owner (for analytics)
    if (snippet.user.toString() === userId.toString()) {
      await snippet.incrementUsage();
    }

    res.json({
      success: true,
      data: snippet
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch code snippet'
    });
  }
};

/**
 * Update a code snippet
 */
export const updateSnippet = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, language, code, editorMode, description, tags, isPublic, isFavorite } = req.body;
    const userId = req.student?._id || req.studentId || req.user?.id;

    const snippet = await CodeSnippet.findById(id);

    if (!snippet) {
      return res.status(404).json({
        success: false,
        message: 'Code snippet not found'
      });
    }

    // Check if user owns this snippet
    if (snippet.user.toString() !== userId) {
      return res.status(403).json({
        success: false,
        message: 'Access denied. You can only update your own snippets.'
      });
    }

    // Check for name conflicts if name is being changed
    if (name && name.trim() !== snippet.name) {
      const existingSnippet = await CodeSnippet.findOne({
        user: userId,
        name: name.trim(),
        _id: { $ne: id }
      });

      if (existingSnippet) {
        return res.status(409).json({
          success: false,
          message: 'A snippet with this name already exists'
        });
      }
    }

    // Update snippet
    const updateData = {};
    if (name) updateData.name = name.trim();
    if (language) updateData.language = language;
    if (code) updateData.code = code;
    if (editorMode) updateData.editorMode = editorMode;
    if (description !== undefined) updateData.description = description.trim();
    if (tags) updateData.tags = tags;
    if (isPublic !== undefined) updateData.isPublic = isPublic;
    if (isFavorite !== undefined) updateData.isFavorite = isFavorite;

    const updatedSnippet = await CodeSnippet.findByIdAndUpdate(
      id,
      updateData,
      { new: true, runValidators: true }
    );

    // Clear user's snippet cache
    const cacheKey = cacheKeys.userSession(`user-snippets:${userId}`);
    await cacheHelpers.del(cacheKey);

    res.json({
      success: true,
      data: updatedSnippet,
      message: 'Code snippet updated successfully'
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to update code snippet',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
};

/**
 * Delete a code snippet
 */
export const deleteSnippet = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.student?._id || req.studentId || req.user?.id;

    const snippet = await CodeSnippet.findById(id);

    if (!snippet) {
      return res.status(404).json({
        success: false,
        message: 'Code snippet not found'
      });
    }

    // Check if user owns this snippet
    if (snippet.user.toString() !== userId) {
      return res.status(403).json({
        success: false,
        message: 'Access denied. You can only delete your own snippets.'
      });
    }

    await CodeSnippet.findByIdAndDelete(id);

    // Clear user's snippet cache
    const cacheKey = cacheKeys.userSession(`user-snippets:${userId}`);
    await cacheHelpers.del(cacheKey);

    res.json({
      success: true,
      message: 'Code snippet deleted successfully'
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to delete code snippet'
    });
  }
};

/**
 * Get public code snippets
 */
export const getPublicSnippets = async (req, res) => {
  try {
    const { page = 1, limit = 20, language, search } = req.query;

    // Check cache first
    const cacheKey = cacheKeys.courseContent(`public-snippets:${page}:${limit}:${language}:${search}`);
    const cachedResult = await cacheHelpers.get(cacheKey);
    
    if (cachedResult) {
      return res.json({
        success: true,
        data: cachedResult
      });
    }

    // Get public snippets from database
    const result = await CodeSnippet.getPublicSnippets({
      page: parseInt(page),
      limit: parseInt(limit),
      language,
      search
    });

    // Cache for 10 minutes
    await cacheHelpers.set(cacheKey, result, 600);

    res.json({
      success: true,
      data: result
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch public code snippets'
    });
  }
};

/**
 * Toggle favorite status of a snippet
 */
export const toggleFavorite = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.student?._id || req.studentId || req.user?.id;

    const snippet = await CodeSnippet.findById(id);

    if (!snippet) {
      return res.status(404).json({
        success: false,
        message: 'Code snippet not found'
      });
    }

    // Check if user owns this snippet
    if (snippet.user.toString() !== userId) {
      return res.status(403).json({
        success: false,
        message: 'Access denied. You can only modify your own snippets.'
      });
    }

    // Toggle favorite status
    snippet.isFavorite = !snippet.isFavorite;
    await snippet.save();

    // Clear user's snippet cache
    const cacheKey = cacheKeys.userSession(`user-snippets:${userId}`);
    await cacheHelpers.del(cacheKey);

    res.json({
      success: true,
      data: snippet,
      message: `Snippet ${snippet.isFavorite ? 'added to' : 'removed from'} favorites`
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to update favorite status'
    });
  }
};

/**
 * Get snippet statistics for user
 */
export const getSnippetStats = async (req, res) => {
  try {
    const userId = req.student?._id || req.studentId || req.user?.id;

    // Check cache first
    const cacheKey = cacheKeys.userSession(`snippet-stats:${userId}`);
    const cachedStats = await cacheHelpers.get(cacheKey);
    
    if (cachedStats) {
      return res.json({
        success: true,
        data: cachedStats
      });
    }

    // Get stats from database
    const stats = await CodeSnippet.aggregate([
      { $match: { user: new mongoose.Types.ObjectId(userId) } },
      {
        $group: {
          _id: null,
          totalSnippets: { $sum: 1 },
          favoriteSnippets: { $sum: { $cond: ['$isFavorite', 1, 0] } },
          publicSnippets: { $sum: { $cond: ['$isPublic', 1, 0] } },
          languages: { $addToSet: '$language' },
          totalUsage: { $sum: '$usageCount' },
          avgUsage: { $avg: '$usageCount' }
        }
      }
    ]);

    const result = stats[0] || {
      totalSnippets: 0,
      favoriteSnippets: 0,
      publicSnippets: 0,
      languages: [],
      totalUsage: 0,
      avgUsage: 0
    };

    // Cache for 10 minutes
    await cacheHelpers.set(cacheKey, result, 600);

    res.json({
      success: true,
      data: result
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch snippet statistics'
    });
  }
};
