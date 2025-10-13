import mongoose from 'mongoose';

const counterSchema = new mongoose.Schema({
  _id: { type: String, required: true },
  seq: { type: Number, default: 0 }
});

const Counter = mongoose.model('Counter', counterSchema);

/**
 * Get the next sequence number with optional min and max values
 * @param {string} name - The name of the sequence
 * @param {number} [increment=1] - The amount to increment by (default: 1)
 * @param {number} [min=1] - The minimum value for the sequence (inclusive)
 * @param {number} [max=Number.MAX_SAFE_INTEGER] - The maximum value for the sequence (inclusive)
 * @returns {Promise<number>} The next sequence number
 */
export async function getNextSequence(name, increment = 1, min = 1, max = Number.MAX_SAFE_INTEGER) {
  // Ensure min and max are valid
  min = Math.max(1, Math.floor(min));
  max = Math.min(Number.MAX_SAFE_INTEGER, Math.floor(max));
  
  // Get the current sequence
  const result = await Counter.findOneAndUpdate(
    { _id: name },
    [
      {
        $set: {
          seq: {
            $cond: [
              { $lt: ["$seq", min] }, // If current seq is less than min
              min,                     // Set to min
              {
                $cond: [
                  { $gte: [{ $add: ["$seq", increment] }, max] }, // If next seq would exceed max
                  min,                                             // Wrap around to min
                  { $add: ["$seq", increment] }                    // Otherwise increment
                ]
              }
            ]
          }
        }
      }
    ],
    { new: true, upsert: true, returnDocument: 'after' }
  );
  
  return result.seq;
}

export default Counter;
