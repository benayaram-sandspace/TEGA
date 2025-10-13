import express from 'express';
import { authRequired } from '../middleware/auth.js';
import Student from '../models/Student.js';
import Conversation from '../models/Conversation.js';

const router = express.Router();

// Ollama configuration
const OLLAMA_API_URL = process.env.OLLAMA_API_URL || 'http://localhost:11434';
const OLLAMA_MODEL = process.env.OLLAMA_MODEL || 'phi'; // Using phi model (fast and accurate)

// Helper function to call Ollama API
async function callOllama(messages, stream = true) {
  try {
    const response = await fetch(`${OLLAMA_API_URL}/api/chat`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: OLLAMA_MODEL,
        messages: messages,
        stream: stream,
        options: {
          temperature: 0.1,  // VERY LOW for focused responses
          top_p: 0.7,        // Controlled for brevity
          num_predict: 150,  // ULTRA SHORT - complete answer in 150 tokens
          num_ctx: 1024,     // REDUCED context for speed
          repeat_penalty: 1.2, // Prevent repetition
          stop: ["Human:", "User:", "\n\n\n", "Question:", "Q:", "Student:"], // Multiple stop tokens
          num_thread: 8,     // INCREASED threads for speed
          num_gpu: 1,        // Enable GPU if available
          keep_alive: "15m"  // Keep model loaded longer
        }
      }),
    });

    if (!response.ok) {
      throw new Error(`Ollama API error: ${response.status} ${response.statusText}`);
    }

    return response;
  } catch (error) {
    console.error('Ollama connection error:', error);
    throw new Error('Failed to connect to Ollama. Make sure Ollama is running.');
  }
}

// POST /api/ai-assistant/chat - Stream AI responses from Ollama (with optional auth)
router.post('/chat', async (req, res) => {
  try {
    const { message, conversationId, conversationHistory, model } = req.body;
    
    // Use selected model from request, fallback to env, then default
    const selectedModel = model || process.env.OLLAMA_MODEL || 'mistral';
    
    // Try to get user ID from auth, but make it optional
    let userId = null;
    try {
      // Check if user is authenticated
      const auth = req.headers.authorization || '';
      const token = auth.startsWith('Bearer ') ? auth.slice(7) : null;
      if (token) {
        const jwt = await import('jsonwebtoken');
        const payload = jwt.default.verify(token, process.env.JWT_SECRET);
        userId = payload.id || payload.userId || payload.principalId || payload._id;
      }
    } catch (authError) {
      console.log('No valid authentication, proceeding without user context');
    }

    if (!message || typeof message !== 'string') {
      return res.status(400).json({
        success: false,
        error: 'Message is required and must be a string'
      });
    }

    // Get student context (if authenticated)
    let user = null;
    if (userId) {
      try {
        user = await Student.findById(userId)
          .populate('enrolledCourses')
          .select('name email enrolledCourses college');
      } catch (userError) {
        console.log('Could not fetch user context:', userError.message);
      }
    }

    const systemPrompt = `Answer in MAX 20 words + code only.

FORMAT: "X does Y.\`\`\`language\ncode\`\`\`"

EXAMPLES:
"what is sql" → "SQL queries databases.\`\`\`sql\nSELECT * FROM users;\`\`\`"
"kadane algorithm" → "Finds max subarray sum.\`\`\`python\ndef kadane(arr):\n  max_sum = curr = arr[0]\n  for n in arr[1:]:\n    curr = max(n, curr+n)\n    max_sum = max(max_sum, curr)\n  return max_sum\`\`\`"
"react hooks" → "State in functions.\`\`\`javascript\nconst [x, setX] = useState(0);\`\`\`"
"nodejs server" → "Use Express.\`\`\`javascript\nrequire('express')().listen(3000);\`\`\`"

CODE FIRST. Be ultra brief.`;

    // Build conversation messages for Ollama
    const ollamaMessages = [
      {
        role: 'system',
        content: systemPrompt
      }
    ];

    // Add conversation history (last 1 message only for maximum speed)
    if (conversationHistory && Array.isArray(conversationHistory)) {
      conversationHistory.slice(-1).forEach(msg => {
        ollamaMessages.push({
          role: msg.role,
          content: msg.content.substring(0, 100) // HEAVILY REDUCED for speed
        });
      });
    }

    // Add current user message
    ollamaMessages.push({
      role: 'user',
      content: message
    });

    // Set up streaming response
    res.setHeader('Content-Type', 'text/event-stream');
    res.setHeader('Cache-Control', 'no-cache');
    res.setHeader('Connection', 'keep-alive');

    // Call Ollama with streaming using selected model
    const ollamaResponse = await fetch(`${OLLAMA_API_URL}/api/chat`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model: selectedModel, // Use selected model
        messages: ollamaMessages,
        stream: true,
        options: {
          temperature: 0.1,        // Low for focus
          top_p: 0.7,              // Controlled
          num_predict: 80,         // ULTRA SHORT - max 80 tokens ONLY
          num_ctx: 512,            // MINIMAL context for speed
          repeat_penalty: 1.1,     // Less strict
          stop: ["Human:", "User:", "\n\n\n\n"],  // Fewer stop tokens
          num_thread: 12,          // MAX CPU threads
          num_gpu: 1,              // GPU enabled
          num_batch: 512,          // Batch processing
          keep_alive: "30m"        // Keep model loaded longer (less startup)
        }
      }),
    });
    const reader = ollamaResponse.body.getReader();
    const decoder = new TextDecoder();

    let fullResponse = '';
    let savedConversationId = conversationId;

    // Stream response to client
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;

      const chunk = decoder.decode(value, { stream: true });
      const lines = chunk.split('\n').filter(line => line.trim());

      for (const line of lines) {
        try {
          const parsed = JSON.parse(line);
          
          if (parsed.message && parsed.message.content) {
            const content = parsed.message.content;
            fullResponse += content;
            
            // Send chunk to client
            res.write(`data: ${JSON.stringify({ content })}\n\n`);
          }

          // Check if done
          if (parsed.done === true) {
            break;
          }
        } catch (e) {
          // Skip malformed JSON lines
          console.error('JSON parse error:', e);
        }
      }
    }

    // Save conversation to database (only if user is authenticated)
    if (userId) {
      try {
        if (!savedConversationId || savedConversationId.startsWith('new-')) {
          // Create new conversation
          const newConversation = await Conversation.create({
            userId,
            title: message.slice(0, 60) + (message.length > 60 ? '...' : ''),
            messages: [
              { role: 'user', content: message, timestamp: new Date() },
              { role: 'assistant', content: fullResponse, timestamp: new Date() }
            ],
            model: OLLAMA_MODEL
          });
          savedConversationId = newConversation._id.toString();
        } else {
          // Update existing conversation
          await Conversation.findByIdAndUpdate(
            savedConversationId,
            {
              $push: {
                messages: {
                  $each: [
                    { role: 'user', content: message, timestamp: new Date() },
                    { role: 'assistant', content: fullResponse, timestamp: new Date() }
                  ]
                }
              },
              updatedAt: new Date()
            }
          );
        }

        // Send conversation ID to client
        res.write(`data: ${JSON.stringify({ conversationId: savedConversationId })}\n\n`);
      } catch (dbError) {
        console.error('Error saving conversation:', dbError);
      }
    }

    // Send completion signal
    res.write('data: [DONE]\n\n');
    res.end();

  } catch (error) {
    console.error('AI Assistant error:', error);
    
    try {
      res.write(`data: ${JSON.stringify({ 
        content: `\n\n❌ Error: ${error.message}\n\nPlease make sure:\n1. Ollama is installed and running\n2. Run: ollama pull ${OLLAMA_MODEL}\n3. Check server logs for details` 
      })}\n\n`);
      res.write('data: [DONE]\n\n');
      res.end();
    } catch (writeError) {
      res.status(500).json({
        success: false,
        error: error.message
      });
    }
  }
});

// GET /api/ai-assistant/conversations - Get user's conversation history (optional auth)
router.get('/conversations', async (req, res) => {
  try {
    // Try to get user ID from auth, but make it optional
    let userId = null;
    try {
      const auth = req.headers.authorization || '';
      const token = auth.startsWith('Bearer ') ? auth.slice(7) : null;
      if (token) {
        const jwt = await import('jsonwebtoken');
        const payload = jwt.default.verify(token, process.env.JWT_SECRET);
        userId = payload.id || payload.userId || payload.principalId || payload._id;
      }
    } catch (authError) {
      console.log('No valid authentication for conversations');
    }

    if (!userId) {
      return res.json({ 
        success: true, 
        data: [] 
      });
    }

    const conversations = await Conversation.find({ 
      userId: userId 
    })
      .select('_id title createdAt updatedAt messages')
      .sort({ updatedAt: -1 })
      .limit(50);
    
    // Return conversations with message count
    const conversationsWithCount = conversations.map(conv => ({
      _id: conv._id,
      title: conv.title,
      createdAt: conv.createdAt,
      updatedAt: conv.updatedAt,
      messageCount: conv.messages?.length || 0
    }));

    res.json({ 
      success: true, 
      data: conversationsWithCount 
    });
  } catch (error) {
    console.error('Error fetching conversations:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Failed to load conversations' 
    });
  }
});

// GET /api/ai-assistant/conversations/:id - Get specific conversation (optional auth)
router.get('/conversations/:id', async (req, res) => {
  try {
    // Try to get user ID from auth, but make it optional
    let userId = null;
    try {
      const auth = req.headers.authorization || '';
      const token = auth.startsWith('Bearer ') ? auth.slice(7) : null;
      if (token) {
        const jwt = await import('jsonwebtoken');
        const payload = jwt.default.verify(token, process.env.JWT_SECRET);
        userId = payload.id || payload.userId || payload.principalId || payload._id;
      }
    } catch (authError) {
      console.log('No valid authentication for conversation');
    }

    if (!userId) {
      return res.status(404).json({ 
        success: false, 
        error: 'Authentication required to access conversation' 
      });
    }

    const conversation = await Conversation.findOne({
      _id: req.params.id,
      userId: userId
    });
    
    if (!conversation) {
      return res.status(404).json({ 
        success: false, 
        error: 'Conversation not found' 
      });
    }
    
    res.json({ 
      success: true, 
      data: conversation 
    });
  } catch (error) {
    console.error('Error fetching conversation:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Failed to load conversation' 
    });
  }
});

// DELETE /api/ai-assistant/conversations/:id - Delete a conversation (optional auth)
router.delete('/conversations/:id', async (req, res) => {
  try {
    // Try to get user ID from auth, but make it optional
    let userId = null;
    try {
      const auth = req.headers.authorization || '';
      const token = auth.startsWith('Bearer ') ? auth.slice(7) : null;
      if (token) {
        const jwt = await import('jsonwebtoken');
        const payload = jwt.default.verify(token, process.env.JWT_SECRET);
        userId = payload.id || payload.userId || payload.principalId || payload._id;
      }
    } catch (authError) {
      console.log('No valid authentication for delete conversation');
    }

    if (!userId) {
      return res.status(404).json({ 
        success: false, 
        error: 'Authentication required to delete conversation' 
      });
    }

    const result = await Conversation.findOneAndDelete({
      _id: req.params.id,
      userId: userId
    });
    
    if (!result) {
      return res.status(404).json({ 
        success: false, 
        error: 'Conversation not found' 
      });
    }
    
    res.json({ 
      success: true, 
      message: 'Conversation deleted successfully' 
    });
  } catch (error) {
    console.error('Error deleting conversation:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Failed to delete conversation' 
    });
  }
});

// GET /api/ai-assistant/status - Check Ollama status
router.get('/status', async (req, res) => {
  try {
    const response = await fetch(`${OLLAMA_API_URL}/api/tags`);
    
    if (response.ok) {
      const data = await response.json();
      const hasModel = data.models?.some(m => m.name.includes(OLLAMA_MODEL));
      
      res.json({
        success: true,
        data: {
          status: 'online',
          ollamaUrl: OLLAMA_API_URL,
          model: OLLAMA_MODEL,
          modelAvailable: hasModel,
          availableModels: data.models?.map(m => m.name) || []
        }
      });
    } else {
      res.json({
        success: false,
        error: 'Ollama is not running',
        data: {
          status: 'offline',
          ollamaUrl: OLLAMA_API_URL
        }
      });
    }
  } catch (error) {
    res.json({
      success: false,
      error: 'Cannot connect to Ollama',
      data: {
        status: 'offline',
        ollamaUrl: OLLAMA_API_URL,
        message: 'Make sure Ollama is installed and running'
      }
    });
  }
});

export default router;

