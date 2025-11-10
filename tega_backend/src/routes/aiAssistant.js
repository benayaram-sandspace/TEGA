import express from 'express';
import Student from '../models/Student.js';
import Conversation from '../models/Conversation.js';
import { GoogleGenerativeAI } from '@google/generative-ai';
import { SYSTEM_PROMPT } from '../config/systemPrompt.js';
import { generateWithOllama } from '../config/ollama.js';

const router = express.Router();

// AI Configuration - Prioritize Gemini (cloud), fallback to Ollama (local)
const OLLAMA_API_URL = process.env.OLLAMA_API_URL || 'http://localhost:11434';
const OLLAMA_MODEL = process.env.OLLAMA_MODEL || 'llama2';

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
    
    // Use selected model from request, fallback to env, then default to lightweight model
    // NEVER default to heavy models like mistral, llama3, gemma3
    const heavyModelsToExclude = ['mistral', 'llama3', 'gemma3'];
    const defaultLightweightModel = 'tinyllama'; // Lightest model
    let selectedModel = model || process.env.OLLAMA_MODEL || defaultLightweightModel;
    
    // If selectedModel is a heavy model, override it to lightweight
    const selectedBase = selectedModel.split(':')[0];
    if (heavyModelsToExclude.includes(selectedBase)) {
      selectedModel = defaultLightweightModel;
    }
    
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
    
    // Use Ollama with optimized model fallback if Gemini is not available or failed
    if (!fullResponse || fullResponse.length === 0) {
      try {
        // Build prompt from messages for generateWithOllama
        let promptText = '';
        ollamaMessages.forEach(msg => {
          if (msg.role === 'system') {
            promptText += `${msg.content}\n\n`;
          } else if (msg.role === 'user') {
            promptText += `User: ${msg.content}\n`;
          } else if (msg.role === 'assistant') {
            promptText += `Assistant: ${msg.content}\n`;
          }
        });
        
        // Use the optimized generateWithOllama with automatic fallback to lighter models
        const ollamaResult = await generateWithOllama(promptText, 'creative', {
          temperature: 0.7,
          top_p: 0.9,
          num_predict: 1000
        });
        
        if (ollamaResult.success && ollamaResult.content) {
          fullResponse = ollamaResult.content;
          
          // Stream the response to client (chunked for better UX)
          const words = fullResponse.split(' ');
          for (let i = 0; i < words.length; i++) {
            const chunk = (i === 0 ? '' : ' ') + words[i];
            res.write(`data: ${JSON.stringify({ content: chunk })}\n\n`);
            // Small delay to simulate streaming
            await new Promise(resolve => setTimeout(resolve, 10));
          }
        } else {
          throw new Error(ollamaResult.error || 'Failed to generate response with Ollama');
        }
      } catch (ollamaError) {
        // Check if Ollama service is available first
        let ollamaAvailable = false;
        try {
          const healthCheck = await fetch(`${OLLAMA_API_URL}/api/tags`, {
            method: 'GET',
            signal: AbortSignal.timeout(3000)
          });
          ollamaAvailable = healthCheck.ok;
        } catch (healthError) {
          throw new Error(`Ollama service is not running. Please start Ollama with: ollama serve`);
        }
        
        if (!ollamaAvailable) {
          throw new Error(`Ollama service is not responding. Please check if Ollama is running.`);
        }
        
        // Get available models
        let availableModels = [];
        try {
          const tagsResponse = await fetch(`${OLLAMA_API_URL}/api/tags`, {
            method: 'GET',
            signal: AbortSignal.timeout(3000)
          });
          if (tagsResponse.ok) {
            const tagsData = await tagsResponse.json();
            availableModels = (tagsData.models || []).map(m => m.name);
          }
        } catch (tagsError) {
          // Failed to get available models, continue with empty list
        }
        
        // Try direct Ollama API call with streaming and optimized model fallback
        // CRITICAL: Filter availableModels FIRST to remove heavy models completely
        const heavyModelsToExclude = ['mistral', 'llama3', 'gemma3'];
        const availableLightweightModels = availableModels.filter(m => {
          const modelBase = m.split(':')[0];
          return !heavyModelsToExclude.includes(modelBase);
        });
        
        // Only try lightweight models that fit in memory (in priority order)
        const preferredModels = ['tinyllama', 'qwen2.5:1.5b', 'phi', 'llama2'];
        
        // Build modelsToTry from preferred lightweight models only
        const modelsToTry = [];
        for (const preferred of preferredModels) {
          const prefBase = preferred.split(':')[0];
          if (!heavyModelsToExclude.includes(prefBase)) {
            modelsToTry.push(preferred);
          }
        }
        
        // Add selectedModel only if it's lightweight and not already in list
        if (selectedModel) {
          const selectedBase = selectedModel.split(':')[0];
          if (!heavyModelsToExclude.includes(selectedBase)) {
            if (!modelsToTry.includes(selectedModel) && !modelsToTry.some(m => m.includes(selectedBase))) {
              modelsToTry.push(selectedModel);
            }
          }
        }
        
        // Map to exact model names from AVAILABLE LIGHTWEIGHT models only
        const modelsToAttempt = [];
        for (const modelToTry of modelsToTry) {
          // Use availableLightweightModels instead of availableModels
          const exactMatch = availableLightweightModels.find(avail => 
            avail === modelToTry || 
            avail === `${modelToTry}:latest` ||
            avail.startsWith(`${modelToTry}:`) ||
            modelToTry.startsWith(avail.split(':')[0])
          );
          
          if (exactMatch) {
            modelsToAttempt.push(exactMatch);
          } else {
            // Try partial match but ONLY from lightweight models
            const partialMatch = availableLightweightModels.find(avail => {
              const availBase = avail.split(':')[0];
              const tryBase = modelToTry.split(':')[0];
              return availBase === tryBase || avail.includes(tryBase) || modelToTry.includes(availBase);
            });
            if (partialMatch && !modelsToAttempt.includes(partialMatch)) {
              modelsToAttempt.push(partialMatch);
            }
          }
        }
        
        // Remove duplicates and FINAL filter to ensure NO heavy models
        const uniqueModelsToAttempt = [...new Set(modelsToAttempt)].filter(m => {
          const modelBase = m.split(':')[0];
          return !heavyModelsToExclude.includes(modelBase);
        });
        
        if (uniqueModelsToAttempt.length === 0) {
          throw new Error(`No lightweight Ollama models available. Available models: ${availableModels.join(', ') || 'none'}. Heavy models (mistral, llama3, gemma3) are excluded due to memory constraints. Please install a lightweight model: ollama pull tinyllama`);
        }
        
        // Final models to try (guaranteed lightweight only)
        const finalModelsToTry = uniqueModelsToAttempt;
        
        let streamingSuccess = false;
        let lastError = null;
        
        for (const modelToTry of finalModelsToTry) {
          // CRITICAL SAFETY CHECK: Skip heavy models immediately if they somehow got through
          const modelBase = modelToTry.split(':')[0];
          if (heavyModelsToExclude.includes(modelBase)) {
            continue;
          }
          
          try {
            // Try non-streaming first (faster for small responses, especially for lightweight models)
            // Increased timeouts - models need time to load, especially on first use
            let timeoutMs = 60000; // 60 seconds - give models more time to load and respond
            const currentModelBase = modelToTry.split(':')[0];
            if (currentModelBase === 'tinyllama' || currentModelBase === 'qwen2.5' || currentModelBase.startsWith('qwen')) {
              timeoutMs = 45000; // 45 seconds for lightweight models
            } else if (currentModelBase === 'phi') {
              timeoutMs = 50000; // 50 seconds for phi
            }
            
            let timeoutSignal;
            if (typeof AbortSignal !== 'undefined' && AbortSignal.timeout) {
              timeoutSignal = AbortSignal.timeout(timeoutMs);
            } else {
              const controller = new AbortController();
              timeoutSignal = controller.signal;
              setTimeout(() => controller.abort(), timeoutMs);
            }
            
            // Try non-streaming first (faster response, especially for lightweight models)
            // Pre-warm: Try to generate a simple response first to load the model
            // This helps avoid timeouts on first use
            try {
              const warmupResponse = await fetch(`${OLLAMA_API_URL}/api/generate`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                  model: modelToTry,
                  prompt: 'Hi',
                  stream: false,
                  options: {
                    num_predict: 5 // Very short prompt to warm up
                  }
                }),
                signal: AbortSignal.timeout(10000) // 10 second warmup
              });
              // Don't wait for warmup to complete, just trigger model loading
              warmupResponse.json().catch(() => {}); // Fire and forget
            } catch (warmupError) {
              // Warmup failed, continue anyway
            }
            
            const nonStreamResponse = await fetch(`${OLLAMA_API_URL}/api/chat`, {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({
                model: modelToTry,
                messages: ollamaMessages,
                stream: false, // Non-streaming for faster response
                options: {
                  temperature: 0.7,
                  top_p: 0.9,
                  num_predict: 800, // Reduced for faster response
                  num_ctx: 2048,
                  repeat_penalty: 1.1,
                  stop: ["Human:", "User:", "\n\n\n\n"]
                }
              }),
              signal: timeoutSignal
            });
            
            if (nonStreamResponse.ok) {
              const nonStreamData = await nonStreamResponse.json();
              if (nonStreamData.message && nonStreamData.message.content) {
                fullResponse = nonStreamData.message.content;
                
                // Stream the response to client (chunked for UX)
                const words = fullResponse.split(' ');
                for (let i = 0; i < words.length; i++) {
                  const chunk = (i === 0 ? '' : ' ') + words[i];
                  res.write(`data: ${JSON.stringify({ content: chunk })}\n\n`);
                  await new Promise(resolve => setTimeout(resolve, 5)); // Small delay for streaming effect
                }
                
                streamingSuccess = true;
                break;
              }
            } else {
              // Check error for non-streaming
              const errorText = await nonStreamResponse.text().catch(() => '');
              if (nonStreamResponse.status === 500 && errorText.includes('memory')) {
                lastError = `Model "${modelToTry}" requires more memory than available`;
                continue;
              }
            }
            
            // If non-streaming failed, try streaming
            // Create new timeout for streaming (longer timeout for streaming)
            let streamTimeoutMs = timeoutMs * 2; // Double timeout for streaming
            let streamTimeoutSignal;
            if (typeof AbortSignal !== 'undefined' && AbortSignal.timeout) {
              streamTimeoutSignal = AbortSignal.timeout(streamTimeoutMs);
            } else {
              const streamController = new AbortController();
              streamTimeoutSignal = streamController.signal;
              setTimeout(() => streamController.abort(), streamTimeoutMs);
            }
            
            // Use /api/chat endpoint for streaming chat responses
            const ollamaResponse = await fetch(`${OLLAMA_API_URL}/api/chat`, {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({
                model: modelToTry,
                messages: ollamaMessages,
                stream: true,
                options: {
                  temperature: 0.7,
                  top_p: 0.9,
                  num_predict: 1000,
                  num_ctx: 2048,
                  repeat_penalty: 1.1,
                  stop: ["Human:", "User:", "\n\n\n\n"]
                }
              }),
              signal: streamTimeoutSignal
            });
            
            if (!ollamaResponse.ok) {
              const errorText = await ollamaResponse.text().catch(() => '');
              let errorObj = {};
              try {
                errorObj = JSON.parse(errorText);
              } catch {}
              
              if (ollamaResponse.status === 500 && (errorText.includes('memory') || errorText.includes('Memory') || errorObj.error?.includes('memory'))) {
                lastError = `Model "${modelToTry}" requires more memory than available`;
                continue; // Try next model
              }
              
              if (ollamaResponse.status === 404) {
                lastError = `Model "${modelToTry}" not found`;
                continue; // Try next model
              }
              
              throw new Error(`Ollama API error (${ollamaResponse.status}): ${errorObj.error || errorText || ollamaResponse.statusText}`);
            }
            
            const reader = ollamaResponse.body.getReader();
            const decoder = new TextDecoder();
            let hasReceivedContent = false;

            // Stream response to client with timeout protection
            const streamStartTime = Date.now();
            const streamTimeout = 60000; // 60 seconds max for streaming
            
            while (true) {
              // Check for overall timeout
              if (Date.now() - streamStartTime > streamTimeout) {
                reader.cancel();
                break;
              }
              
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
                    hasReceivedContent = true;
                    
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
              
              // If we've received content and stream seems stuck, break
              if (hasReceivedContent && Date.now() - streamStartTime > streamTimeout) {
                break;
              }
            }
            
            if (fullResponse.length > 0) {
              streamingSuccess = true;
              break; // Success, exit loop
            } else {
              throw new Error('Streaming completed but no content received');
            }
            
          } catch (modelError) {
            const errorMsg = modelError.message || String(modelError);
            lastError = errorMsg;
            
            if (errorMsg.includes('timeout') || errorMsg.includes('aborted')) {
              continue; // Try next model
            }
            
            if (errorMsg.includes('memory') || errorMsg.includes('Memory')) {
              continue; // Try next model
            }
          }
        }
        
        if (!streamingSuccess) {
          // Build error message - only show lightweight models that were actually tried
          const triedModels = finalModelsToTry.filter(m => {
            const base = m.split(':')[0];
            return !heavyModelsToExclude.includes(base);
          });
          
          throw new Error(
            `All lightweight Ollama models failed. Tried: ${triedModels.join(', ') || 'none'}. ` +
            `Last error: ${lastError || 'Unknown error'}. ` +
            `Available lightweight models: ${availableLightweightModels.join(', ') || 'none'}. ` +
            `Heavy models (mistral, llama3, gemma3) were excluded. ` +
            `Please ensure Ollama is running and try: ollama pull tinyllama (lightest model)`
          );
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
      let errorMsg = `\n\n❌ Error: ${error.message}\n\n`;
      
      // Provide specific guidance based on error type
      if (error.message.includes('Ollama service is not running') || error.message.includes('not reachable')) {
        errorMsg += `**Ollama Service Issue:**\n`;
        errorMsg += `1. Start Ollama service: Open terminal and run "ollama serve"\n`;
        errorMsg += `2. Verify it's running: Check if http://localhost:11434 is accessible\n`;
        errorMsg += `3. Install a model: Run "ollama pull tinyllama" (fastest option)\n`;
      } else if (error.message.includes('All Ollama models failed') || error.message.includes('No Ollama models available')) {
        errorMsg += `**Model Availability Issue:**\n`;
        errorMsg += `1. Check available models: Run "ollama list" in terminal\n`;
        errorMsg += `2. Install a lightweight model: Run "ollama pull tinyllama"\n`;
        errorMsg += `3. Or install: "ollama pull qwen2.5:1.5b" or "ollama pull phi"\n`;
        errorMsg += `4. Verify Ollama is running: "ollama serve"\n`;
      } else if (error.message.includes('memory')) {
        errorMsg += `**Memory Issue:**\n`;
        errorMsg += `1. Install a lighter model: Run "ollama pull tinyllama"\n`;
        errorMsg += `2. Or try: "ollama pull qwen2.5:1.5b"\n`;
        errorMsg += `3. Check system memory availability\n`;
      } else if (getGeminiApiKey()) {
        errorMsg += `**Gemini API Issue:**\n`;
        errorMsg += `1. Check GEMINI_API_KEY is valid in .env file\n`;
        errorMsg += `2. Verify internet connection\n`;
        errorMsg += `3. Check server logs for details\n`;
      } else {
        errorMsg += `**Troubleshooting:**\n`;
        errorMsg += `1. Add GEMINI_API_KEY to .env (Recommended - Free tier available)\n`;
        errorMsg += `OR\n`;
        errorMsg += `2. Install Ollama: Run "ollama pull tinyllama"\n`;
        errorMsg += `3. Start Ollama: Run "ollama serve"\n`;
        errorMsg += `4. Check server logs for detailed error messages\n`;
      }
      
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
