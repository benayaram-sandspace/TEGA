import express from 'express';
import Student from '../models/Student.js';
import Conversation from '../models/Conversation.js';
import { GoogleGenerativeAI } from '@google/generative-ai';
import { SYSTEM_PROMPT } from '../config/systemPrompt.js';

const router = express.Router();

// AI Configuration - Prioritize Gemini (cloud), fallback to Ollama (local)
const OLLAMA_API_URL = process.env.OLLAMA_API_URL || 'http://localhost:11434';
const OLLAMA_MODEL = process.env.OLLAMA_MODEL || 'phi';

// Function to get Gemini API key (called at runtime, not module load time)
function getGeminiApiKey() {
  return process.env.GEMINI_API_KEY;
}

// Function to get Gemini AI instance (called at runtime)
function getGeminiAI() {
  const apiKey = getGeminiApiKey();
  return apiKey ? new GoogleGenerativeAI(apiKey) : null;
}

// Debug: Check if GEMINI_API_KEY is loaded (called at runtime)
// Note: These debug logs are misleading at module load time, 
// the actual runtime check happens in the status endpoint

// Helper function to call Gemini API (streaming)
async function callGemini(messages, res) {
  try {
    const genAI = getGeminiAI();
    if (!genAI) {
      throw new Error('Gemini AI not initialized');
    }
    const model = genAI.getGenerativeModel({ model: 'gemini-2.0-flash' });
    
    // Build prompt from messages
    let prompt = '';
    messages.forEach(msg => {
      if (msg.role === 'system') {
        prompt += `${msg.content}\n\n`;
      } else if (msg.role === 'user') {
        prompt += `User: ${msg.content}\n`;
      } else if (msg.role === 'assistant') {
        prompt += `Assistant: ${msg.content}\n`;
      }
    });

    // Stream the response
    // Use streaming for better user experience
    const result = await model.generateContentStream(prompt);
    
    let fullResponse = '';
    for await (const chunk of result.stream) {
      const chunkText = chunk.text();
      fullResponse += chunkText;
      
      // Send chunk to client
      res.write(`data: ${JSON.stringify({ content: chunkText })}\n\n`);
    }
    
    return fullResponse;
  } catch (error) {
    throw new Error(`Gemini error: ${error.message}`);
  }
}

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
      }
    }

    // Use the imported system prompt
    const systemPrompt = SYSTEM_PROMPT;

    // Build conversation messages for Ollama
    const ollamaMessages = [
      {
        role: 'system',
        content: systemPrompt
      }
    ];

    // Add conversation history (last 3 messages for better context)
    if (conversationHistory && Array.isArray(conversationHistory)) {
      conversationHistory.slice(-3).forEach(msg => {
        ollamaMessages.push({
          role: msg.role,
          content: msg.content.substring(0, 500) // Allow more context
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

    let fullResponse = '';
    let savedConversationId = conversationId;

    // Check if user specifically requested Gemini or if it's the default
    const geminiApiKey = getGeminiApiKey();
    const useGemini = model === 'gemini' && geminiApiKey;
    
    if (useGemini) {
      // Use Gemini API
      try {
        fullResponse = await callGemini(ollamaMessages, res);
      } catch (geminiError) {
        // If Gemini fails, try Ollama
        if (!getGeminiApiKey()) {
          throw new Error('Gemini failed and Ollama not configured');
        }
        // Fall through to Ollama below
      }
    }
    
    // Use Ollama with Mistral if Gemini is not available or failed
    if (!fullResponse || fullResponse.length === 0) {
      const ollamaResponse = await fetch(`${OLLAMA_API_URL}/api/chat`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          model: 'mistral:latest', // Use Mistral specifically as fallback
          messages: ollamaMessages,
          stream: true,
          options: {
            temperature: 0.7,
            top_p: 0.9,
            num_predict: 1000,
            num_ctx: 8192,
            repeat_penalty: 1.1,
            stop: ["Human:", "User:", "\n\n\n\n"],
            num_thread: 8,
            num_gpu: 1,
            num_batch: 256,
            keep_alive: "5m"
          }
        }),
      });
      const reader = ollamaResponse.body.getReader();
      const decoder = new TextDecoder();

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
          }
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
      }
    }

    // Send completion signal
    res.write('data: [DONE]\n\n');
    res.end();

  } catch (error) {
    try {
      const errorMsg = getGeminiApiKey() 
        ? `\n\n❌ Error: ${error.message}\n\nPlease check:\n1. GEMINI_API_KEY is valid in .env file\n2. You have internet connection\n3. Check server logs for details`
        : `\n\n❌ Error: ${error.message}\n\nPlease make sure:\n1. Add GEMINI_API_KEY to .env (Recommended - Free tier available)\nOR\n2. Install Ollama and run: ollama pull ${OLLAMA_MODEL}\n3. Check server logs for details`;
      
      res.write(`data: ${JSON.stringify({ content: errorMsg })}\n\n`);
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
    res.status(500).json({ 
      success: false, 
      error: 'Failed to delete conversation' 
    });
  }
});

// GET /api/ai-assistant/debug - Debug environment variables
router.get('/debug', (req, res) => {
  res.json({
    geminiKey: process.env.GEMINI_API_KEY ? 'FOUND' : 'NOT FOUND',
    geminiValue: process.env.GEMINI_API_KEY ? process.env.GEMINI_API_KEY.substring(0, 20) + '...' : 'undefined',
    allGeminiVars: Object.keys(process.env).filter(key => key.includes('GEMINI')),
    nodeEnv: process.env.NODE_ENV,
    workingDir: process.cwd()
  });
});

// GET /api/ai-assistant/status - Check AI service status
router.get('/status', async (req, res) => {
  const geminiApiKey = getGeminiApiKey();
  const status = {
    gemini: {
      available: !!geminiApiKey,
      status: geminiApiKey ? 'configured' : 'not configured',
      model: 'gemini-2.0-flash'
    },
    ollama: {
      available: false,
      status: 'offline',
      url: OLLAMA_API_URL,
      model: OLLAMA_MODEL
    }
  };

  // Check Ollama status
  try {
    const response = await fetch(`${OLLAMA_API_URL}/api/tags`, {
      signal: AbortSignal.timeout(2000) // 2 second timeout
    });
    
    if (response.ok) {
      const data = await response.json();
      const hasModel = data.models?.some(m => m.name.includes(OLLAMA_MODEL));
      
      status.ollama.available = true;
      status.ollama.status = 'online';
      status.ollama.modelAvailable = hasModel;
      status.ollama.availableModels = data.models?.map(m => m.name) || [];
    }
  } catch (error) {
    // Ollama not available, already set to offline
  }

  // Determine primary AI service
  status.primary = geminiApiKey ? 'gemini' : (status.ollama.available ? 'ollama' : 'none');
  status.success = status.primary !== 'none';

  res.json({
    success: status.success,
    data: status,
    message: status.primary === 'gemini' 
      ? 'Using Google Gemini AI (cloud) - FREE tier'
      : status.primary === 'ollama'
      ? 'Using Ollama with Mistral AI (local fallback)'
      : 'No AI service configured. Add GEMINI_API_KEY to .env or install Ollama'
  });
});

export default router;
