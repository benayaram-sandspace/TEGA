// Ollama configuration and helper functions
const OLLAMA_API_URL = process.env.OLLAMA_API_URL || 'http://localhost:11434';
const OLLAMA_MODEL = process.env.OLLAMA_MODEL || 'llama2';

// Task-specific model configuration (can be overridden via environment variables)
// Models ordered by preference (will fallback to lighter models if memory issues occur)
const OLLAMA_ANALYTICAL_MODEL = process.env.OLLAMA_ANALYTICAL_MODEL || 'llama2'; // Scoring and analysis
const OLLAMA_CREATIVE_MODEL = process.env.OLLAMA_CREATIVE_MODEL || 'llama2'; // Question generation
const OLLAMA_CODING_MODEL = process.env.OLLAMA_CODING_MODEL || 'llama2'; // Technical questions

// Fallback chain for models (ordered from preferred to lightest)
// Optimized: Start with lighter, faster models to avoid timeouts
// If a model fails with memory error, system will automatically try the next one
const MODEL_FALLBACK_CHAIN = [
  'tinyllama',        // 637 MB - fastest and lightest (start here to avoid timeouts)
  'qwen2.5:1.5b',     // 986 MB - second option (lightweight)
  'phi',              // 1.6 GB - third option
  'llama2',           // 3.8 GB - fourth option (if enough memory)
  'gemma3:4b'         // 3.3 GB - last option (if enough memory)
];

/**
 * Check if Ollama service is available
 */
export async function checkOllamaAvailability() {
  try {
    // Create timeout signal (compatible with older Node.js versions)
    let timeoutSignal;
    if (typeof AbortSignal !== 'undefined' && AbortSignal.timeout) {
      timeoutSignal = AbortSignal.timeout(3000);
    } else {
      const controller = new AbortController();
      timeoutSignal = controller.signal;
      setTimeout(() => controller.abort(), 3000);
    }
    
    const response = await fetch(`${OLLAMA_API_URL}/api/tags`, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
      },
      signal: timeoutSignal
    });
    
    if (response.ok) {
      return { available: true };
    }
    return { available: false };
  } catch (error) {
    return { available: false, error: error.message };
  }
}

/**
 * Try to generate with a specific model
 */
async function tryGenerateWithModel(model, prompt, temperature, top_p, num_predict) {
  // Reduced timeout for faster fallback (15 seconds instead of 30)
  // Smaller models should respond faster, larger models will timeout quickly if no memory
  const timeoutMs = 15000; // 15 seconds
  let timeoutSignal;
  if (typeof AbortSignal !== 'undefined' && AbortSignal.timeout) {
    timeoutSignal = AbortSignal.timeout(timeoutMs);
  } else {
    const controller = new AbortController();
    timeoutSignal = controller.signal;
    setTimeout(() => controller.abort(), timeoutMs);
  }
  
  const response = await fetch(`${OLLAMA_API_URL}/api/generate`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: model,
      prompt: prompt,
      stream: false,
      options: {
        temperature: temperature,
        top_p: top_p,
        num_predict: num_predict,
      }
    }),
    signal: timeoutSignal
  });

  if (!response.ok) {
    const errorText = await response.text().catch(() => '');
    const error = JSON.parse(errorText || '{}');
    return {
      success: false,
      error: error.error || `${response.status} ${response.statusText}`,
      status: response.status,
      isMemoryError: response.status === 500 && (errorText.includes('memory') || errorText.includes('Memory') || errorText.includes('system memory'))
    };
  }

  const data = await response.json();
  return {
    success: true,
    content: data.response || '',
    model: model,
    done: data.done || false
  };
}

/**
 * Generate content using Ollama with automatic fallback to lighter models
 */
export async function generateWithOllama(prompt, task = 'general', options = {}) {
  const temperature = options.temperature || 0.7;
  const top_p = options.top_p || 0.9;
  const num_predict = options.num_predict || 500;
  
  // Optimized: Start with lighter, faster models first to avoid timeouts
  // Skip the preferred model if it's heavy - start with lightweight models
  const preferredModel = getModelForTask(task);
  
  // Build fallback chain - prioritize lighter models for speed
  // Start with the fastest models, then try heavier ones if needed
  let modelsToTry = [];
  
  // If preferred model is lightweight, try it first
  const lightweightModels = ['tinyllama', 'qwen2.5:1.5b', 'phi'];
  if (lightweightModels.includes(preferredModel)) {
    modelsToTry.push(preferredModel);
  }
  
  // Add all models from fallback chain (lightest first)
  modelsToTry.push(...MODEL_FALLBACK_CHAIN);
  
  // If preferred model is heavier, add it after lightweight ones
  if (!lightweightModels.includes(preferredModel) && !modelsToTry.includes(preferredModel)) {
    // Insert after lightweight models
    const insertIndex = lightweightModels.length;
    modelsToTry.splice(insertIndex, 0, preferredModel);
  }
  
  // Remove duplicates while preserving order
  const uniqueModels = [...new Set(modelsToTry)];
  
  // Try each model in order until one works
  for (let i = 0; i < uniqueModels.length; i++) {
    const model = uniqueModels[i];
    
    try {
      // Quick check if model exists (with shorter timeout for speed)
      const modelCheck = await ensureModelAvailable(model);
      if (!modelCheck.success && modelCheck.message !== 'Model is being downloaded') {
        continue; // Try next model
      }
      
      const startTime = Date.now();
      
      // Try generating with this model
      const result = await tryGenerateWithModel(model, prompt, temperature, top_p, num_predict);
      const elapsed = ((Date.now() - startTime) / 1000).toFixed(1);
      
      if (result.success) {
        if (i > 0) {
        }
        return result;
      }
      
      // If memory error, skip heavier models and try next
      if (result.isMemoryError) {
        // Skip other heavy models in the chain if we hit memory error
        if (['llama2', 'gemma3:4b', 'llama3', 'mistral'].includes(model)) {
          const heavyModels = ['llama2', 'gemma3:4b', 'llama3', 'mistral'];
          const skipIndex = uniqueModels.findIndex(m => heavyModels.includes(m) && m !== model);
          if (skipIndex > i) {
            // Remove heavy models from remaining list
            for (let j = uniqueModels.length - 1; j > i; j--) {
              if (heavyModels.includes(uniqueModels[j])) {
                uniqueModels.splice(j, 1);
              }
            }
          }
        }
        continue;
      }
      
      // If timeout or abort error in result, skip this model and try next
      if (result.error && (result.error.includes('timeout') || result.error.includes('aborted'))) {
        continue;
      }
      
      // For other errors (404, etc.), try next model
      if (result.status === 404) {
        continue;
      }
      
      // For other errors, try next model
      
    } catch (error) {
      const errorMsg = error.message || String(error);
      if (errorMsg.includes('timeout') || errorMsg.includes('aborted')) {
      } else {
      }
      continue;
    }
  }
  
  // All models failed
  return {
    success: false,
    error: `All models failed. Tried: ${uniqueModels.join(', ')}. Last error: Unable to generate with any available model. Please ensure Ollama is running and at least one model is installed.`,
    content: ''
  };
}

/**
 * Get the appropriate model for a specific task
 * Uses different models optimized for different tasks
 */
export function getModelForTask(task) {
  // Task-specific model mapping
  // All tasks use llama2 by default (lightweight and reliable)
  // You can override via environment variables if you have more memory
  const modelMap = {
    'analytical': OLLAMA_ANALYTICAL_MODEL, // Scoring, evaluation, analysis
    'creative': OLLAMA_CREATIVE_MODEL, // Question generation, conversational
    'coding': OLLAMA_CODING_MODEL, // Technical questions
    'technical': OLLAMA_CODING_MODEL, // Technical topics
    'general': OLLAMA_MODEL, // Default model
    'behavioral': OLLAMA_CREATIVE_MODEL, // Behavioral questions (more conversational)
    'problem_solving': OLLAMA_ANALYTICAL_MODEL, // Problem-solving analysis
    'introduction': OLLAMA_CREATIVE_MODEL, // Welcome messages and introductions
  };
  
  const selectedModel = modelMap[task] || OLLAMA_MODEL;
  return selectedModel;
}

/**
 * Ensure a model is available (download if needed)
 */
export async function ensureModelAvailable(model = OLLAMA_MODEL) {
  try {
    // Create timeout signal (compatible with older Node.js versions)
    let timeoutSignal;
    if (typeof AbortSignal !== 'undefined' && AbortSignal.timeout) {
      timeoutSignal = AbortSignal.timeout(3000);
    } else {
      const controller = new AbortController();
      timeoutSignal = controller.signal;
      setTimeout(() => controller.abort(), 3000);
    }
    
    // Check if model exists
    const response = await fetch(`${OLLAMA_API_URL}/api/tags`, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
      },
      signal: timeoutSignal
    });

    if (response.ok) {
      const data = await response.json();
      const models = data.models || [];
      const modelExists = models.some(m => m.name === model || m.name.startsWith(model));
      
      if (modelExists) {
        return { success: true, message: 'Model is available' };
      }
      
      // Model doesn't exist - return error with helpful message
      // Note: Auto-pulling is disabled as it can take a very long time
      return { 
        success: false, 
        message: `Model "${model}" not found. Please install it using: ollama pull ${model}` 
      };
    }
    
    return { success: false, message: 'Model not available' };
  } catch (error) {
    return { success: false, message: error.message };
  }
}

