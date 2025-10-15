import jwt from 'jsonwebtoken'

export function authRequired(req, res, next) {
  const auth = req.headers.authorization || ''
  const token = auth.startsWith('Bearer ') ? auth.slice(7) : null
  if (!token) return res.status(401).json({ message: 'Missing token' })
  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET || 'your-super-secret-jwt-key-change-this-in-production')
    
    // Handle different possible ID field names in the JWT payload
    const userId = payload.id || payload.userId || payload.principalId || payload._id;
    
    if (!userId) {
      return res.status(401).json({ message: 'Invalid token payload' });
    }
    
    // Set the user object with consistent field names
    req.user = {
      id: userId,
      role: payload.role
    };
    
    
    next()
  } catch (error) {
    return res.status(401).json({ message: 'Invalid token' })
  }
}
